-- Edit mode's capabilities on group detail (SUP-024 AC1).
begin;

select plan(10);

create temporary table ids as
select
  (select id from public.groups where name = 'Tuesday Night Group') as tuesday,
  (select id from auth.users where email = 'leader@parkhill.test') as leader,
  (select id from auth.users where email = 'staff@parkhill.test') as staff,
  (select id from auth.users where email = 'member.one@parkhill.test') as member_one;
grant select on ids to authenticated;

create function pg_temp.detail(p_user uuid, p_group uuid)
returns jsonb
language plpgsql
as $$
declare
  v_result jsonb;
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  set local role authenticated;
  v_result := public.get_screen('community.group', 'en', jsonb_build_object('group_id', p_group)) -> 'data';
  reset role;
  return v_result;
end;
$$;

create temporary table seen as
select
  pg_temp.detail(leader, tuesday) as leader,
  pg_temp.detail(staff, tuesday) as staff,
  pg_temp.detail(member_one, tuesday) as member
from ids;

select ok(
  (select leader ?& array['edit', 'edit_fields', 'add_member', 'save'] from seen),
  'a leader gets edit, edit_fields, add_member and save for their group'
);
select ok(
  (select not exists (select 1 from jsonb_array_elements(leader -> 'members') m where m ? 'toggle_leader') from seen),
  'a leader gets no toggle_leader'
);
select ok(
  (select bool_and((m ? 'remove') = not (m ->> 'is_leader')::boolean) from seen, jsonb_array_elements(leader -> 'members') m),
  'a leader gets remove on non-leader rows only'
);
select ok(
  (select staff ?& array['edit', 'edit_fields', 'add_member', 'save']
     and (select bool_and((m ->> 'toggle_leader')::boolean) from jsonb_array_elements(staff -> 'members') m) from seen),
  'staff get every capability and toggle_leader on every row'
);
select ok(
  (select not (member ?| array['edit', 'edit_fields', 'add_member', 'save'])
     and not exists (select 1 from jsonb_array_elements(member -> 'members') m where m ? 'toggle_leader') from seen),
  'a member gets no edit capability'
);
select is(
  (select leader -> 'edit' from seen),
  '{"edit_label": "Edit", "done_label": "Done", "cancel_label": "Cancel"}'::jsonb,
  'edit carries the backend''s labels'
);
select is(
  (select leader -> 'add_member' from seen),
  (select jsonb_build_object('label', 'Add member', 'action', jsonb_build_object(
    'type', 'navigate', 'screen_key', 'people.picker', 'params', jsonb_build_object('group_id', tuesday), 'presentation', 'sheet'
  )) from ids),
  'add_member opens the picker for the group as a sheet'
);
select is(
  (select leader -> 'save' from seen),
  (select jsonb_build_object('type', 'call', 'function', 'save_group_changes', 'params', jsonb_build_object('p_group_id', tuesday), 'on_success', 'refresh') from ids),
  'save calls save_group_changes for the group and refreshes'
);
select is(
  (select jsonb_agg(f - 'options') from seen, jsonb_array_elements(leader -> 'edit_fields') f),
  '[{"id": "name", "label": "Name", "kind": "text", "value": "Tuesday Night Group"},
    {"id": "description", "label": "Description", "kind": "multiline", "value": "Study, conversation and dinner together."},
    {"id": "day", "label": "Meeting day", "kind": "day", "value": "2"},
    {"id": "time", "label": "Meeting time", "kind": "time", "value": "19:00"},
    {"id": "location", "label": "Location", "kind": "text", "value": "Lee home, North Park"}]'::jsonb,
  'edit_fields carry the details as strings'
);
select is(
  (select f -> 'options' -> 0 from seen, jsonb_array_elements(leader -> 'edit_fields') f where f ->> 'id' = 'day'),
  '{"value": "1", "label": "Mondays"}'::jsonb,
  'the day field offers every day, labelled'
);

select * from finish();
rollback;
