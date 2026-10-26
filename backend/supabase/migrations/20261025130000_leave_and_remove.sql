-- Leaving a group and removing a member (SUP-014, specs/COMMUNITY.md 5.2,
-- 5.5, 5.6; specs/ROLES.md 2). Both are one-tap `call` actions: each starts
-- with require_active_user(), checks the caller may make the change, and
-- refuses a call the caller may no longer make with action_refused and the
-- backend's message.

insert into public.strings (key, locale, value) values
  ('community.call_refused', 'en', 'You can''t make this change anymore.');

-- Whether p_user_id may remove p_member_id from p_group_id now: someone
-- else who is in that community group, when internal.can_remove_member
-- allows it (leaders cannot remove other leaders).
create function internal.may_remove_member(p_user_id uuid, p_group_id uuid, p_member_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_member_id <> p_user_id
    and exists (
      select 1
      from internal.community_groups() g
      join public.group_members m on m.group_id = g.id and m.user_id = p_member_id
      where g.id = p_group_id
    )
    and internal.can_remove_member(p_user_id, p_group_id, p_member_id);
$$;

revoke all on function internal.may_remove_member(uuid, uuid, uuid) from public, anon, authenticated;

-- Whether p_user_id may leave p_group_id: anyone in a community group,
-- leaders included.
create function internal.may_leave_group(p_user_id uuid, p_group_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from internal.community_groups() g
    join public.group_members m on m.group_id = g.id and m.user_id = p_user_id
    where g.id = p_group_id
  );
$$;

revoke all on function internal.may_leave_group(uuid, uuid) from public, anon, authenticated;

create function internal.refuse_action(p_locale text)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  raise exception 'action_refused'
    using detail = internal.t('community.call_refused', coalesce(p_locale, 'en')),
          hint = 'The caller may not make this change.';
end;
$$;

revoke all on function internal.refuse_action(text) from public, anon, authenticated;

-- Removes a member, and their leadership with them.
create function public.remove_member(p_group_id uuid, p_user_id uuid, p_locale text default 'en')
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_caller uuid := internal.require_active_user();
begin
  if not internal.may_remove_member(v_caller, p_group_id, p_user_id) then
    perform internal.refuse_action(p_locale);
  end if;

  delete from public.group_members m where m.group_id = p_group_id and m.user_id = p_user_id;
  return '{}'::jsonb;
end;
$$;

-- Ends the caller's membership and leadership. The last leader may leave,
-- leaving the group leaderless (specs/COMMUNITY.md 5.6).
create function public.leave_group(p_group_id uuid, p_locale text default 'en')
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_caller uuid := internal.require_active_user();
begin
  if not internal.may_leave_group(v_caller, p_group_id) then
    perform internal.refuse_action(p_locale);
  end if;

  delete from public.group_members m where m.group_id = p_group_id and m.user_id = v_caller;
  return '{}'::jsonb;
end;
$$;

revoke all on function public.remove_member(uuid, uuid, text) from public, anon, authenticated;
revoke all on function public.leave_group(uuid, text) from public, anon, authenticated;
-- anon may call them so a signed-out caller gets session_ended, not a grant error.
grant execute on function public.remove_member(uuid, uuid, text) to anon, authenticated;
grant execute on function public.leave_group(uuid, text) to anon, authenticated;
