-- Saving edit mode in one pass (SUP-024 AC2 to AC5, AC7): one allowed and one
-- refused test for groups.edit_details, groups.add_member and
-- groups.assign_leader, and all or nothing.
begin;

select plan(23);

create temporary table ids as
select
  (select id from public.groups where name = 'Tuesday Night Group') as tuesday,
  (select id from public.groups where name = 'Young Families') as families,
  (select id from auth.users where email = 'leader@parkhill.test') as leader,
  (select id from auth.users where email = 'staff@parkhill.test') as staff,
  (select id from auth.users where email = 'member.one@parkhill.test') as member_one,
  (select id from auth.users where email = 'attendee@parkhill.test') as attendee,
  (select id from auth.users where email = 'disabled@parkhill.test') as disabled,
  (select id from public.profiles where display_name = 'Jordan Lee') as jordan,
  (select id from public.profiles where display_name = 'Rachel Cohen') as rachel;
grant select on ids to authenticated;

-- save_group_changes(p_group, p_batch) as p_user.
create function pg_temp.save_as(p_user uuid, p_group uuid, p_batch jsonb)
returns jsonb
language plpgsql
as $$
declare
  v_result jsonb;
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  set local role authenticated;
  v_result := public.save_group_changes(p_group, p_batch, 'en');
  reset role;
  return v_result;
end;
$$;

create function pg_temp.is_member(p_group uuid, p_user uuid)
returns boolean
language sql
as $$ select exists (select 1 from public.group_members where group_id = p_group and user_id = p_user) $$;

create function pg_temp.is_leader(p_group uuid, p_user uuid)
returns boolean
language sql
as $$ select exists (select 1 from public.group_leaders where group_id = p_group and user_id = p_user) $$;

-- AC2: a valid batch applies every change.
select is(
  (select pg_temp.save_as(leader, tuesday, jsonb_build_object(
    'fields', jsonb_build_object('name', 'Tuesday Supper Group', 'description', 'Dinner first.', 'day', '3', 'time', '18:15', 'location', 'Park home'),
    'add', jsonb_build_array(attendee),
    'remove', jsonb_build_array(jordan)
  )) from ids),
  '{"ok": true}'::jsonb,
  'a leader saves details, an addition and a removal'
);
select is(
  (select jsonb_build_object('name', name, 'description', description, 'day', meeting_day, 'time', to_char(meeting_time, 'HH24:MI'), 'location', location)
   from public.groups, ids where groups.id = ids.tuesday),
  '{"name": "Tuesday Supper Group", "description": "Dinner first.", "day": 3, "time": "18:15", "location": "Park home"}'::jsonb,
  'groups.edit_details allowed: every detail is saved'
);
select ok((select pg_temp.is_member(tuesday, attendee) from ids), 'groups.add_member allowed: the person is added');
select ok((select not pg_temp.is_member(tuesday, jordan) from ids), 'the removed member is gone');

-- AC2, AC3: any problem applies nothing and is keyed to its field or row.
select is(
  (select pg_temp.save_as(leader, tuesday, jsonb_build_object(
    'fields', jsonb_build_object('name', '  ', 'location', 'Somewhere else'),
    'add', jsonb_build_array(member_one, rachel),
    'make_leader', jsonb_build_array(member_one)
  )) from ids),
  (select jsonb_build_object(
    'ok', false,
    'field_errors', jsonb_build_object('name', 'Enter a name.'),
    'row_errors', jsonb_build_object(member_one::text, 'You can''t make this change anymore.')
  ) from ids),
  'a blank name, an existing member and a leader made by a leader are all reported'
);
select is(
  (select location from public.groups, ids where groups.id = ids.tuesday), 'Park home',
  'nothing in a failed batch is applied, not even its valid details'
);
select ok((select not pg_temp.is_member(tuesday, rachel) from ids), 'nor its valid additions');
select is(
  (select pg_temp.save_as(leader, tuesday, jsonb_build_object('add', jsonb_build_array(member_one))) -> 'row_errors' ->> member_one::text from ids),
  'Already a member', 'adding someone already in the group says so'
);
select is(
  (select pg_temp.save_as(leader, tuesday, jsonb_build_object('remove', jsonb_build_array(jordan))) -> 'row_errors' ->> jordan::text from ids),
  'No longer in this group', 'removing someone already gone says so'
);
select is(
  (select pg_temp.save_as(leader, tuesday, jsonb_build_object('fields', jsonb_build_object('day', '8', 'time', '7pm'))) -> 'field_errors' from ids),
  '{"day": "Choose a day.", "time": "Choose a time."}'::jsonb,
  'a day and a time must be valid'
);

-- AC3, AC7: each change is checked on its own.
select is(
  (select pg_temp.save_as(leader, families, jsonb_build_object('fields', jsonb_build_object('location', 'X'))) -> 'field_errors' ->> 'location' from ids),
  'You can''t make this change anymore.', 'groups.edit_details refused: a leader cannot edit a group they do not lead'
);
select is(
  (select pg_temp.save_as(member_one, tuesday, jsonb_build_object('add', jsonb_build_array(rachel))) -> 'row_errors' ->> rachel::text from ids),
  'You can''t make this change anymore.', 'groups.add_member refused: a member cannot add people'
);
select is(
  (select pg_temp.save_as(leader, tuesday, jsonb_build_object('remove_leader', jsonb_build_array(leader))) ->> 'ok' from ids),
  'false', 'groups.assign_leader refused: a leader cannot change who leads'
);

-- AC4, AC7: leadership sits on membership.
select is(
  (select pg_temp.save_as(staff, tuesday, jsonb_build_object('make_leader', jsonb_build_array(rachel, member_one))) from ids),
  '{"ok": true}'::jsonb, 'groups.assign_leader allowed: staff make leaders'
);
select ok(
  (select pg_temp.is_leader(tuesday, rachel) and pg_temp.is_member(tuesday, rachel) from ids),
  'making a non-member a leader adds them as a member'
);
select ok((select pg_temp.is_leader(tuesday, member_one) from ids), 'a member made a leader leads');
select is(
  (select pg_temp.save_as(staff, tuesday, jsonb_build_object('remove_leader', jsonb_build_array(member_one), 'remove', jsonb_build_array(rachel))) from ids),
  '{"ok": true}'::jsonb, 'staff remove a leadership and a leader in one save'
);
select ok(
  (select not pg_temp.is_leader(tuesday, member_one) and pg_temp.is_member(tuesday, member_one)
     and not pg_temp.is_member(tuesday, rachel) and not pg_temp.is_leader(tuesday, rachel) from ids),
  'removing leadership keeps the membership; removing a member removes their leadership'
);

-- Only active people can be made leaders; a disabled leader can be removed.
select is(
  (select pg_temp.save_as(staff, tuesday, jsonb_build_object('make_leader', jsonb_build_array(disabled))) -> 'row_errors' ->> disabled::text from ids),
  'You can''t make this change anymore.', 'a disabled account cannot be made a leader'
);
select ok((select not pg_temp.is_member(tuesday, disabled) from ids), 'nor added as a member through it');
insert into public.group_leaders (group_id, user_id) select tuesday, disabled from ids;
select is(
  (select pg_temp.save_as(staff, tuesday, jsonb_build_object('remove_leader', jsonb_build_array(disabled))) from ids),
  '{"ok": true}'::jsonb, 'a disabled leader can still be removed'
);

-- AC5: a disabled account is refused.
select throws_ok(
  format('select pg_temp.save_as(%L, %L, %L)', (select disabled from ids), (select tuesday from ids), '{}'),
  'P0001', 'session_ended', 'a disabled account cannot save'
);
select throws_ok(
  format('select pg_temp.save_as(%L, %L, %L)', (select leader from ids), gen_random_uuid(), '{}'),
  'P0001', 'action_refused', 'a group that does not exist is refused'
);

select * from finish();
rollback;
