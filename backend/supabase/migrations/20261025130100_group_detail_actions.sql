-- Leave and swipe to remove on group detail (SUP-014, specs/COMMUNITY.md
-- 5.1, 5.2). `leave` goes to every member of the group, leaders included;
-- `remove` goes on each row the caller may remove (internal.may_remove_member),
-- so each button appears only for people who may use it.

insert into public.strings (key, locale, value) values
  ('community.group.leave', 'en', 'Leave group'),
  ('community.group.leave.confirm_title', 'en', 'Leave {group}?'),
  ('community.group.leave.confirm_message', 'en', 'You''ll no longer see this group or its members.'),
  ('community.group.leave.confirm', 'en', 'Leave'),
  ('community.group.remove', 'en', 'Remove'),
  ('community.group.remove.confirm_title', 'en', 'Remove {name}?'),
  ('community.group.remove.confirm_message', 'en', '{name} will no longer be in {group}.'),
  ('community.group.remove.confirm', 'en', 'Remove'),
  ('community.cancel', 'en', 'Cancel');

-- A destructive call button with the backend's confirmation.
create function internal.call_button(
  p_label text, p_function text, p_params jsonb, p_on_success text,
  p_title text, p_message text, p_confirm_label text, p_locale text
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'label', p_label,
    'action', jsonb_build_object(
      'type', 'call',
      'function', p_function,
      'params', p_params,
      'confirm', jsonb_build_object(
        'title', p_title,
        'message', p_message,
        'confirm_label', p_confirm_label,
        'cancel_label', internal.t('community.cancel', p_locale)
      ),
      'on_success', p_on_success,
      'role', 'destructive'
    )
  );
$$;

revoke all on function internal.call_button(text, text, jsonb, text, text, text, text, text) from public, anon, authenticated;

-- A group's detail as p_user_id sees it (GroupDetail), now with leave and
-- remove for those who may use them.
create or replace function internal.group_detail(p_group_id uuid, p_user_id uuid, p_locale text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'group_id', g.id,
    'title', g.name,
    'description', g.description,
    'meeting', internal.meeting_line(g.meeting_day, g.meeting_time, p_locale),
    'location', g.location,
    'leaders_line', coalesce(
      (
        select replace(
          internal.t('community.group.leaders', p_locale),
          '{names}',
          string_agg(p.display_name, internal.t('community.list_separator', p_locale) order by p.display_name)
        )
        from public.group_leaders l
        join public.profiles p on p.id = l.user_id
        where l.group_id = g.id
        having count(*) > 0
      ),
      internal.t('community.group.leaders_none', p_locale)
    ),
    'members_title', internal.t('community.group.members_title', p_locale),
    'members', coalesce((
      select jsonb_agg(
        jsonb_strip_nulls(jsonb_build_object(
          'user_id', m.user_id,
          'title', p.display_name,
          'note', case when m.user_id = p_user_id then internal.t('community.group.you', p_locale) end,
          'is_leader', l.user_id is not null,
          'remove', case when internal.may_remove_member(p_user_id, g.id, m.user_id) then internal.call_button(
            internal.t('community.group.remove', p_locale),
            'remove_member',
            jsonb_build_object('p_group_id', g.id, 'p_user_id', m.user_id),
            'refresh',
            replace(internal.t('community.group.remove.confirm_title', p_locale), '{name}', p.display_name),
            replace(replace(internal.t('community.group.remove.confirm_message', p_locale), '{name}', p.display_name), '{group}', g.name),
            internal.t('community.group.remove.confirm', p_locale),
            p_locale
          ) end
        ))
        order by l.user_id is null, p.display_name, m.user_id
      )
      from public.group_members m
      join public.profiles p on p.id = m.user_id
      left join public.group_leaders l on l.group_id = m.group_id and l.user_id = m.user_id
      where m.group_id = g.id
    ), '[]'::jsonb)
  ) || case when internal.may_leave_group(p_user_id, g.id) then jsonb_build_object('leave', internal.call_button(
    internal.t('community.group.leave', p_locale),
    'leave_group',
    jsonb_build_object('p_group_id', g.id),
    'dismiss',
    replace(internal.t('community.group.leave.confirm_title', p_locale), '{group}', g.name),
    internal.t('community.group.leave.confirm_message', p_locale),
    internal.t('community.group.leave.confirm', p_locale),
    p_locale
  )) else '{}'::jsonb end
  from internal.community_groups() g
  where g.id = p_group_id;
$$;
