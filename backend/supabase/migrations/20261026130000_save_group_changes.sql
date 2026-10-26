-- Saving a group's edit mode in one pass (SUP-024, specs/COMMUNITY.md 5.4):
-- details, people added and removed, and leaders made and removed, applied
-- in one transaction only when every change is allowed and valid. Otherwise
-- nothing is applied and every problem comes back keyed to its field or row.

insert into public.strings (key, locale, value) values
  ('community.edit.error.name_required', 'en', 'Enter a name.'),
  ('community.edit.error.day_required', 'en', 'Choose a day.'),
  ('community.edit.error.time_required', 'en', 'Choose a time.'),
  ('community.edit.error.already_member', 'en', 'Already a member'),
  ('community.edit.error.not_member', 'en', 'No longer in this group');

-- The uuid in p_value, or null when it is not one.
create function internal.try_uuid(p_value text)
returns uuid
language plpgsql
immutable
set search_path = ''
as $$
begin
  return p_value::uuid;
exception when invalid_text_representation then
  return null;
end;
$$;

revoke all on function internal.try_uuid(text) from public, anon, authenticated;

-- Applies p_batch ({ fields: { <id>: value }, add, remove, make_leader,
-- remove_leader: [user_id] }) to p_group_id, checking permission for every
-- change. Returns SaveResult: { ok: true }, or { ok: false, field_errors,
-- row_errors } with nothing applied. Field ids: name, description, day,
-- time, location.
create function public.save_group_changes(p_group_id uuid, p_batch jsonb, p_locale text default 'en')
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := internal.require_active_user();
  v_locale text := coalesce(p_locale, 'en');
  v_batch jsonb := coalesce(p_batch, '{}'::jsonb);
  v_fields jsonb := coalesce(v_batch -> 'fields', '{}'::jsonb);
  v_refused text := internal.t('community.call_refused', v_locale);
  v_field_errors jsonb := '{}'::jsonb;
  v_row_errors jsonb := '{}'::jsonb;
  v_key text;
  v_value text;
  v_id text;
  v_member uuid;
begin
  if not exists (select 1 from internal.community_groups() g where g.id = p_group_id) then
    perform internal.refuse_action(v_locale);
  end if;

  -- Details.
  for v_key, v_value in select key, value from jsonb_each_text(v_fields) loop
    if not internal.has_permission(v_user_id, 'groups.edit_details', p_group_id) then
      v_field_errors := v_field_errors || jsonb_build_object(v_key, v_refused);
    elsif v_key = 'name' and btrim(coalesce(v_value, '')) = '' then
      v_field_errors := v_field_errors || jsonb_build_object(v_key, internal.t('community.edit.error.name_required', v_locale));
    elsif v_key = 'day' and coalesce(v_value, '') !~ '^[1-7]$' then
      v_field_errors := v_field_errors || jsonb_build_object(v_key, internal.t('community.edit.error.day_required', v_locale));
    elsif v_key = 'time' and coalesce(v_value, '') !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' then
      v_field_errors := v_field_errors || jsonb_build_object(v_key, internal.t('community.edit.error.time_required', v_locale));
    elsif v_key not in ('name', 'description', 'day', 'time', 'location') then
      v_field_errors := v_field_errors || jsonb_build_object(v_key, v_refused);
    end if;
  end loop;

  -- People added: active people who are not members yet.
  for v_id in select jsonb_array_elements_text(coalesce(v_batch -> 'add', '[]'::jsonb)) loop
    v_member := internal.try_uuid(v_id);
    if not internal.has_permission(v_user_id, 'groups.add_member', p_group_id)
      or v_member is null
      or not exists (
        select 1 from auth.users u
        where u.id = v_member and u.deleted_at is null and (u.banned_until is null or u.banned_until <= now())
      ) then
      v_row_errors := v_row_errors || jsonb_build_object(v_id, v_refused);
    elsif exists (select 1 from public.group_members m where m.group_id = p_group_id and m.user_id = v_member) then
      v_row_errors := v_row_errors || jsonb_build_object(v_id, internal.t('community.edit.error.already_member', v_locale));
    end if;
  end loop;

  -- People removed: members the caller may remove, and not also made leaders.
  for v_id in select jsonb_array_elements_text(coalesce(v_batch -> 'remove', '[]'::jsonb)) loop
    v_member := internal.try_uuid(v_id);
    if v_member is not null
      and not exists (select 1 from public.group_members m where m.group_id = p_group_id and m.user_id = v_member) then
      v_row_errors := v_row_errors || jsonb_build_object(v_id, internal.t('community.edit.error.not_member', v_locale));
    elsif v_member is null
      or not internal.may_remove_member(v_user_id, p_group_id, v_member)
      or coalesce(v_batch -> 'make_leader', '[]'::jsonb) ? v_id then
      v_row_errors := v_row_errors || jsonb_build_object(v_id, v_refused);
    end if;
  end loop;

  -- Leaders made and removed: groups.assign_leader for the group.
  for v_id in
    select jsonb_array_elements_text(coalesce(v_batch -> 'make_leader', '[]'::jsonb))
    union all
    select jsonb_array_elements_text(coalesce(v_batch -> 'remove_leader', '[]'::jsonb))
  loop
    v_member := internal.try_uuid(v_id);
    if not internal.has_permission(v_user_id, 'groups.assign_leader', p_group_id)
      or v_member is null
      or not exists (select 1 from public.profiles p where p.id = v_member) then
      v_row_errors := v_row_errors || jsonb_build_object(v_id, v_refused);
    end if;
  end loop;

  if v_field_errors <> '{}'::jsonb or v_row_errors <> '{}'::jsonb then
    return jsonb_build_object('ok', false)
      || case when v_field_errors <> '{}'::jsonb then jsonb_build_object('field_errors', v_field_errors) else '{}'::jsonb end
      || case when v_row_errors <> '{}'::jsonb then jsonb_build_object('row_errors', v_row_errors) else '{}'::jsonb end;
  end if;

  update public.groups g set
    name = coalesce(btrim(v_fields ->> 'name'), g.name),
    description = coalesce(v_fields ->> 'description', g.description),
    meeting_day = coalesce((v_fields ->> 'day')::smallint, g.meeting_day),
    meeting_time = coalesce((v_fields ->> 'time')::time, g.meeting_time),
    location = coalesce(v_fields ->> 'location', g.location)
  where g.id = p_group_id and v_fields <> '{}'::jsonb;

  delete from public.group_members m
  where m.group_id = p_group_id
    and m.user_id in (select (jsonb_array_elements_text(coalesce(v_batch -> 'remove', '[]'::jsonb)))::uuid);

  insert into public.group_members (group_id, user_id)
  select p_group_id, (jsonb_array_elements_text(coalesce(v_batch -> 'add', '[]'::jsonb)))::uuid;

  -- Making a non-member a leader adds the membership (SUP-010's trigger).
  insert into public.group_leaders (group_id, user_id)
  select p_group_id, id
  from (select distinct (jsonb_array_elements_text(coalesce(v_batch -> 'make_leader', '[]'::jsonb)))::uuid as id) made
  on conflict do nothing;

  delete from public.group_leaders l
  where l.group_id = p_group_id
    and l.user_id in (select (jsonb_array_elements_text(coalesce(v_batch -> 'remove_leader', '[]'::jsonb)))::uuid);

  return jsonb_build_object('ok', true);
end;
$$;

revoke all on function public.save_group_changes(uuid, jsonb, text) from public, anon, authenticated;
-- anon may call it so a signed-out caller gets session_ended, not a grant error.
grant execute on function public.save_group_changes(uuid, jsonb, text) to anon, authenticated;
