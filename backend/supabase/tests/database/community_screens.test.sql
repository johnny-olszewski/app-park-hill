-- Community home and group detail for each person (SUP-012 AC1 to AC5).
begin;

select plan(23);

create temporary table ids as
select
  (select id from public.groups where name = 'Tuesday Night Group') as tuesday,
  (select id from public.groups where name = 'Mission Hills Group') as mission,
  (select id from public.groups where name = 'Young Families') as families,
  (select id from public.groups where name = 'Point Loma Group') as point_loma;
grant select on ids to authenticated;

-- Calls get_screen as a persona's account (or any user id).
create function pg_temp.screen_as(p_user uuid, p_key text, p_params jsonb default '{}')
returns jsonb
language plpgsql
as $$
declare
  v_result jsonb;
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  set local role authenticated;
  v_result := public.get_screen(p_key, 'en', p_params);
  reset role;
  return v_result;
end;
$$;

create function pg_temp.persona(p_email text)
returns uuid
language sql
as $$ select id from auth.users where email = p_email $$;

create function pg_temp.home(p_email text)
returns jsonb
language sql
as $$ select pg_temp.screen_as(pg_temp.persona(p_email), 'community.home') -> 'data' $$;

-- AC1: the backend decides each persona's state.
select is(
  pg_temp.home('attendee@parkhill.test'),
  jsonb_build_object('empty', jsonb_build_object(
    'title', 'You''re not in a community group yet.',
    'message', 'Community Groups gather through the week to study the Bible, talk and live life together. A staff member can add you to one.'
  )),
  'attendee gets empty'
);
select ok(pg_temp.home('staff@parkhill.test') ? 'empty', 'staff with no group gets empty');
select is(pg_temp.home('member.one@parkhill.test') -> 'group' ->> 'title', 'Tuesday Night Group', 'member_one gets their group');
select is(pg_temp.home('leader@parkhill.test') -> 'group' ->> 'title', 'Tuesday Night Group', 'leader gets their group');
select is(pg_temp.home('admin@parkhill.test') -> 'group' ->> 'title', 'Mission Hills Group', 'admin gets their group');
select ok(
  (select count(*) = 1 from jsonb_object_keys(pg_temp.home('member.one@parkhill.test'))),
  'home carries exactly one part'
);
select is(pg_temp.home('member.two@parkhill.test') -> 'my_groups' ->> 'title', 'My groups', 'member_two gets my_groups');

-- AC2: led groups first, then the rest, each by name.
select results_eq(
  $$ select r ->> 'title' from jsonb_array_elements(pg_temp.home('member.two@parkhill.test') -> 'my_groups' -> 'rows') r $$,
  array['Young Families', 'Tuesday Night Group'],
  'member_two: the group they lead first'
);
insert into auth.users (id, email, raw_user_meta_data)
values ('55555555-5555-5555-5555-555555555555', 'order@example.com', '{"display_name": "Order Test"}');
insert into public.group_leaders (group_id, user_id) select tuesday, '55555555-5555-5555-5555-555555555555' from ids;
insert into public.group_members (group_id, user_id)
select g, '55555555-5555-5555-5555-555555555555' from ids, unnest(array[families, mission]) g;
select results_eq(
  $$ select r ->> 'title' from jsonb_array_elements(
       pg_temp.screen_as('55555555-5555-5555-5555-555555555555', 'community.home') -> 'data' -> 'my_groups' -> 'rows') r $$,
  array['Tuesday Night Group', 'Mission Hills Group', 'Young Families'],
  'a user leading one group and in two others: led first, then the rest by name'
);
select results_eq(
  $$ select r ->> 'badge' from jsonb_array_elements(
       pg_temp.screen_as('55555555-5555-5555-5555-555555555555', 'community.home') -> 'data' -> 'my_groups' -> 'rows') r $$,
  array['Leader', null, null],
  'only led groups carry the Leader badge'
);
select is(
  pg_temp.home('member.two@parkhill.test') -> 'my_groups' -> 'rows' -> 1,
  jsonb_build_object(
    'group_id', (select tuesday from ids),
    'title', 'Tuesday Night Group',
    'subtitle', 'Tuesdays · 7:00 PM · Lee home, North Park',
    'action', jsonb_build_object(
      'type', 'navigate', 'screen_key', 'community.group',
      'params', jsonb_build_object('group_id', (select tuesday from ids)), 'presentation', 'push'
    )
  ),
  'a group row opens that group''s detail'
);

-- AC3: community.group for members, leaders and holders of groups.view_all only.
select is(
  pg_temp.screen_as(pg_temp.persona('member.one@parkhill.test'), 'community.group', jsonb_build_object('group_id', (select tuesday from ids))) -> 'data',
  pg_temp.home('member.one@parkhill.test') -> 'group',
  'a member gets their group, the same detail home embeds'
);
select is(
  pg_temp.screen_as(pg_temp.persona('leader@parkhill.test'), 'community.group', jsonb_build_object('group_id', (select tuesday from ids))) -> 'data' ->> 'title',
  'Tuesday Night Group', 'a leader gets their group'
);
select is(
  pg_temp.screen_as(pg_temp.persona('staff@parkhill.test'), 'community.group', jsonb_build_object('group_id', (select point_loma from ids))) -> 'data' ->> 'title',
  'Point Loma Group', 'staff get any group'
);
select throws_ok(
  format($$ select pg_temp.screen_as(pg_temp.persona('member.one@parkhill.test'), 'community.group', '{"group_id": "%s"}') $$, (select mission from ids)),
  'P0001', 'screen_unavailable', 'a non-member is refused another group'
);
select throws_ok(
  $$ select pg_temp.screen_as(pg_temp.persona('attendee@parkhill.test'), 'community.group', '{"group_id": "not-a-uuid"}') $$,
  'P0001', 'screen_unavailable', 'a malformed group id is refused'
);
update public.groups set archived_at = now() from ids where groups.id = ids.tuesday;
select throws_ok(
  format($$ select pg_temp.screen_as(pg_temp.persona('member.one@parkhill.test'), 'community.group', '{"group_id": "%s"}') $$, (select tuesday from ids)),
  'P0001', 'screen_unavailable', 'an archived group is refused, even to its members'
);
select ok(pg_temp.home('member.one@parkhill.test') ? 'empty', 'an archived group leaves home');
update public.groups set archived_at = null from ids where groups.id = ids.tuesday;

-- AC4: the detail matches the seed.
select is(
  pg_temp.home('member.two@parkhill.test') -> 'my_groups' -> 'rows' -> 0 ->> 'subtitle',
  'Sundays · 4:00 PM · Vesper Hall', 'row subtitles are backend formatted'
);
select is(
  pg_temp.screen_as(pg_temp.persona('staff@parkhill.test'), 'community.group', jsonb_build_object('group_id', (select point_loma from ids))) -> 'data' ->> 'leaders_line',
  'Leaders: none yet', 'a leaderless group says so'
);
select is(
  (select (g - 'group_id' - 'members') || jsonb_build_object(
     'leaders', (select jsonb_agg(m ->> 'title' order by o) from jsonb_array_elements(g -> 'members') with ordinality e(m, o) where (m ->> 'is_leader')::boolean),
     'you', (select jsonb_agg(m ->> 'title') from jsonb_array_elements(g -> 'members') m where m ->> 'note' = 'You'),
     'leaders_first', (select bool_and(not (m ->> 'is_leader')::boolean or o <= 2) from jsonb_array_elements(g -> 'members') with ordinality e(m, o)),
     'members', jsonb_array_length(g -> 'members'),
     'member_ids', (select bool_and(m ? 'user_id') from jsonb_array_elements(g -> 'members') m))
   from (select pg_temp.home('member.one@parkhill.test') -> 'group' as g) x),
  jsonb_build_object(
    'title', 'Tuesday Night Group',
    'description', 'Study, conversation and dinner together.',
    'meeting', 'Tuesdays · 7:00 PM',
    'location', 'Lee home, North Park',
    'leaders_line', 'Leaders: Leader, Order Test',
    'members_title', 'Members',
    'leaders', jsonb_build_array('Leader', 'Order Test'),
    'you', jsonb_build_array('Member One'),
    'leaders_first', true,
    'members', (select count(*)::int from public.group_members m join public.groups g on g.id = m.group_id where g.name = 'Tuesday Night Group'),
    'member_ids', true
  ),
  'member_one''s group: details, leaders line, leaders first, and You on their own row'
);

-- AC5: wording is remote.
update public.strings set value = 'Your groups' where key = 'community.home.my_groups.title' and locale = 'en';
select is(pg_temp.home('member.two@parkhill.test') -> 'my_groups' ->> 'title', 'Your groups', 'a changed string shows in the next response');

-- get_tabs embeds the same Community home.
select is(
  (select public.get_tabs('en') -> 'tabs' -> 1 -> 'screen'
   from (select set_config('request.jwt.claims', json_build_object('sub', pg_temp.persona('admin@parkhill.test'), 'role', 'authenticated')::text, true)) c),
  pg_temp.screen_as(pg_temp.persona('admin@parkhill.test'), 'community.home'),
  'get_tabs embeds the caller''s Community home'
);

select * from finish();
rollback;
