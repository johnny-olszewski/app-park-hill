-- Edit mode's capabilities on group detail (SUP-024, specs/COMMUNITY.md 5.3):
-- each person gets exactly the edit controls they hold. edit_fields for
-- groups.edit_details, add_member for groups.add_member, toggle_leader on
-- every row for groups.assign_leader, remove as before; edit and save
-- whenever any of them is present.

insert into public.strings (key, locale, value) values
  ('community.edit.edit', 'en', 'Edit'),
  ('community.edit.done', 'en', 'Done'),
  ('community.edit.cancel', 'en', 'Cancel'),
  ('community.edit.add_member', 'en', 'Add member'),
  ('community.edit.field.name', 'en', 'Name'),
  ('community.edit.field.description', 'en', 'Description'),
  ('community.edit.field.day', 'en', 'Meeting day'),
  ('community.edit.field.time', 'en', 'Meeting time'),
  ('community.edit.field.location', 'en', 'Location');

-- The details edited inline (EditField), as they are now.
create function internal.group_edit_fields(p_group_id uuid, p_locale text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_array(
    jsonb_build_object('id', 'name', 'label', internal.t('community.edit.field.name', p_locale), 'kind', 'text', 'value', g.name),
    jsonb_build_object('id', 'description', 'label', internal.t('community.edit.field.description', p_locale), 'kind', 'multiline', 'value', g.description),
    jsonb_build_object('id', 'day', 'label', internal.t('community.edit.field.day', p_locale), 'kind', 'day',
      'value', coalesce(g.meeting_day::text, ''),
      'options', (select jsonb_agg(jsonb_build_object('value', d::text, 'label', internal.t('community.weekday.' || d, p_locale)) order by d)
                  from generate_series(1, 7) d)),
    jsonb_build_object('id', 'time', 'label', internal.t('community.edit.field.time', p_locale), 'kind', 'time',
      'value', coalesce(to_char(g.meeting_time, 'HH24:MI'), '')),
    jsonb_build_object('id', 'location', 'label', internal.t('community.edit.field.location', p_locale), 'kind', 'text', 'value', g.location)
  )
  from public.groups g
  where g.id = p_group_id;
$$;

revoke all on function internal.group_edit_fields(uuid, text) from public, anon, authenticated;

-- The edit capabilities p_user_id holds on p_group_id, to merge into its
-- GroupDetail: edit_fields, add_member, and edit and save when any edit
-- capability is held (p_any_row_removable: some row carries remove).
create function internal.group_edit(p_group_id uuid, p_user_id uuid, p_any_row_removable boolean, p_locale text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with can as (
    select
      internal.has_permission(p_user_id, 'groups.edit_details', p_group_id) as edit_details,
      internal.has_permission(p_user_id, 'groups.add_member', p_group_id) as add_member,
      internal.has_permission(p_user_id, 'groups.assign_leader', p_group_id) as assign_leader
  )
  select case when edit_details or add_member or assign_leader or p_any_row_removable then
      jsonb_build_object(
        'edit', jsonb_build_object(
          'edit_label', internal.t('community.edit.edit', p_locale),
          'done_label', internal.t('community.edit.done', p_locale),
          'cancel_label', internal.t('community.edit.cancel', p_locale)
        ),
        'save', jsonb_build_object(
          'type', 'call',
          'function', 'save_group_changes',
          'params', jsonb_build_object('p_group_id', p_group_id),
          'on_success', 'refresh'
        )
      )
      || case when edit_details then jsonb_build_object('edit_fields', internal.group_edit_fields(p_group_id, p_locale)) else '{}'::jsonb end
      || case when add_member then jsonb_build_object('add_member', jsonb_build_object(
        'label', internal.t('community.edit.add_member', p_locale),
        'action', jsonb_build_object(
          'type', 'navigate',
          'screen_key', 'people.picker',
          'params', jsonb_build_object('group_id', p_group_id),
          'presentation', 'sheet'
        )
      )) else '{}'::jsonb end
    else '{}'::jsonb end
  from can;
$$;

revoke all on function internal.group_edit(uuid, uuid, boolean, text) from public, anon, authenticated;

-- A group's detail as p_user_id sees it (GroupDetail), now with edit mode's
-- capabilities.
create or replace function internal.group_detail(p_group_id uuid, p_user_id uuid, p_locale text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_assign_leader boolean := internal.has_permission(p_user_id, 'groups.assign_leader', p_group_id);
  v_detail jsonb;
begin
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
            'toggle_leader', case when v_assign_leader then true end,
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
    where g.id = p_group_id
  into v_detail;

  if v_detail is null then
    return null;
  end if;

  return v_detail || internal.group_edit(
    p_group_id, p_user_id,
    exists (select 1 from jsonb_array_elements(v_detail -> 'members') m where m ? 'remove'),
    p_locale
  );
end;
$$;
