-- The people picker (SUP-013 AC1, AC2, AC4).
begin;

select plan(9);

create temporary table ids as
select
  (select id from public.groups where name = 'Tuesday Night Group') as tuesday,
  (select id from public.groups where name = 'Young Families') as families,
  (select id from auth.users where email = 'leader@parkhill.test') as leader,
  (select id from auth.users where email = 'staff@parkhill.test') as staff,
  (select id from auth.users where email = 'member.one@parkhill.test') as member_one,
  (select id from auth.users where email = 'attendee@parkhill.test') as attendee;
grant select on ids to authenticated;

create function pg_temp.picker_as(p_user uuid, p_group uuid)
returns jsonb
language plpgsql
as $$
declare
  v_result jsonb;
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  set local role authenticated;
  v_result := public.get_screen('people.picker', 'en', jsonb_build_object('group_id', p_group)) -> 'data';
  reset role;
  return v_result;
end;
$$;

create temporary table picked as
select r
from ids, jsonb_array_elements(pg_temp.picker_as(ids.leader, ids.tuesday) -> 'rows') r;

-- AC1: every active person by name; members marked, not selectable.
select is(
  (select count(*)::int from picked),
  (select count(*)::int from public.profiles p join auth.users u on u.id = p.id
   where u.deleted_at is null and (u.banned_until is null or u.banned_until <= now())),
  'every active person is listed'
);
select ok(
  not exists (select 1 from picked where r ->> 'title' = 'Disabled'),
  'a disabled account is not listed'
);
select is(
  array(select r ->> 'title' from picked),
  array(select r ->> 'title' from picked order by r ->> 'title'),
  'people are sorted by name'
);
select is(
  (select r from picked where r ->> 'title' = 'Member One') - 'user_id',
  jsonb_build_object('title', 'Member One', 'note', 'Already a member', 'selectable', false),
  'a current member is marked and cannot be chosen'
);
select is(
  (select r from picked where r ->> 'title' = 'Attendee') - 'user_id',
  jsonb_build_object('title', 'Attendee', 'selectable', true),
  'anyone else can be chosen'
);

-- AC2: only holders of groups.add_member on that group.
select is(
  (select pg_temp.picker_as(staff, tuesday) ->> 'add_label' from ids), 'Add', 'staff open the picker for any group'
);
select throws_ok(
  format('select pg_temp.picker_as(%L, %L)', (select leader from ids), (select families from ids)),
  'P0001', 'screen_unavailable', 'a leader cannot add people to a group they do not lead'
);
select throws_ok(
  format('select pg_temp.picker_as(%L, %L)', (select member_one from ids), (select tuesday from ids)),
  'P0001', 'screen_unavailable', 'a member cannot open the picker'
);
select throws_ok(
  format('select pg_temp.picker_as(%L, %L)', (select attendee from ids), (select tuesday from ids)),
  'P0001', 'screen_unavailable', 'an attendee cannot open the picker'
);

select * from finish();
rollback;
