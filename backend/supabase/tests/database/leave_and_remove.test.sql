-- Leaving a group and removing a member (SUP-014 AC2 to AC4, AC7): one
-- allowed and one refused test for "Leave a group" and groups.remove_member.
begin;

select plan(19);

create temporary table ids as
select
  (select id from public.groups where name = 'Tuesday Night Group') as tuesday,
  (select id from public.groups where name = 'Young Families') as families,
  (select id from public.groups where name = 'Point Loma Group') as point_loma,
  (select id from auth.users where email = 'leader@parkhill.test') as leader,
  (select id from auth.users where email = 'member.one@parkhill.test') as member_one,
  (select id from auth.users where email = 'member.two@parkhill.test') as member_two,
  (select id from auth.users where email = 'staff@parkhill.test') as staff,
  (select id from auth.users where email = 'attendee@parkhill.test') as attendee,
  (select id from auth.users where email = 'disabled@parkhill.test') as disabled,
  (select id from public.profiles where display_name = 'Jordan Lee') as jordan,
  (select id from public.profiles where display_name = 'Maria Lopez') as maria,
  (select id from public.profiles where display_name = 'Rachel Cohen') as rachel,
  (select id from public.profiles where display_name = 'Mei Chen') as mei;
grant select on ids to authenticated;

-- Runs p_sql as p_user's account.
create function pg_temp.as_user(p_user uuid, p_sql text)
returns jsonb
language plpgsql
as $$
declare
  v_result jsonb;
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  set local role authenticated;
  execute p_sql into v_result;
  reset role;
  return v_result;
end;
$$;

-- The detail of the error p_sql raises as p_user.
create function pg_temp.refusal_detail(p_user uuid, p_sql text)
returns text
language plpgsql
as $$
declare
  v_detail text;
begin
  perform pg_temp.as_user(p_user, p_sql);
  return null;
exception when others then
  reset role;
  get stacked diagnostics v_detail = pg_exception_detail;
  return v_detail;
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

create function pg_temp.remove(p_group uuid, p_member uuid)
returns text
language sql
as $$ select format('select public.remove_member(%L, %L, ''en'')', p_group, p_member) $$;

create function pg_temp.leave(p_group uuid)
returns text
language sql
as $$ select format('select public.leave_group(%L, ''en'')', p_group) $$;

-- AC3, AC4, AC7: groups.remove_member, allowed and refused.
select is(
  pg_temp.as_user((select leader from ids), pg_temp.remove((select tuesday from ids), (select jordan from ids))),
  '{}'::jsonb, 'a leader removes a member of their group'
);
select ok(not pg_temp.is_member((select tuesday from ids), (select jordan from ids)), 'the removed member is gone');
select throws_ok(
  format('select pg_temp.as_user(%L, %L)', (select member_two from ids), pg_temp.remove((select families from ids), (select rachel from ids))),
  'P0001', 'action_refused', 'a leader cannot remove another leader'
);
select throws_ok(
  format('select pg_temp.as_user(%L, %L)', (select leader from ids), pg_temp.remove((select families from ids), (select member_two from ids))),
  'P0001', 'action_refused', 'a leader cannot remove members of a group they do not lead'
);
select throws_ok(
  format('select pg_temp.as_user(%L, %L)', (select member_one from ids), pg_temp.remove((select tuesday from ids), (select maria from ids))),
  'P0001', 'action_refused', 'a member without groups.remove_member is refused'
);
select is(
  pg_temp.refusal_detail((select member_one from ids), pg_temp.remove((select tuesday from ids), (select maria from ids))),
  'You can''t make this change anymore.', 'a refusal carries the backend''s message'
);
select is(
  pg_temp.as_user((select staff from ids), pg_temp.remove((select families from ids), (select rachel from ids))),
  '{}'::jsonb, 'staff remove a leader from any group'
);
select ok(
  not pg_temp.is_member((select families from ids), (select rachel from ids))
    and not pg_temp.is_leader((select families from ids), (select rachel from ids)),
  'removing a leader ends their membership and leadership'
);
select throws_ok(
  format('select pg_temp.as_user(%L, %L)', (select staff from ids), pg_temp.remove((select tuesday from ids), (select jordan from ids))),
  'P0001', 'action_refused', 'removing someone no longer in the group is refused'
);
select throws_ok(
  format('select pg_temp.as_user(%L, %L)', (select leader from ids), pg_temp.remove((select tuesday from ids), (select leader from ids))),
  'P0001', 'action_refused', 'nobody removes themself; they leave instead'
);

-- AC2, AC4, AC7: leaving, allowed and refused.
select is(
  pg_temp.as_user((select member_one from ids), pg_temp.leave((select tuesday from ids))),
  '{}'::jsonb, 'a member leaves their group'
);
select ok(not pg_temp.is_member((select tuesday from ids), (select member_one from ids)), 'leaving ends the membership');
select throws_ok(
  format('select pg_temp.as_user(%L, %L)', (select attendee from ids), pg_temp.leave((select tuesday from ids))),
  'P0001', 'action_refused', 'someone not in the group cannot leave it'
);
select is(
  pg_temp.as_user((select leader from ids), pg_temp.leave((select tuesday from ids))),
  '{}'::jsonb, 'the last leader can leave'
);
select ok(
  not pg_temp.is_member((select tuesday from ids), (select leader from ids))
    and not exists (select 1 from public.group_leaders l, ids where l.group_id = ids.tuesday),
  'leaving ends the leadership too, leaving the group leaderless'
);

-- AC5: after leaving, the group is refused with the backend's message.
select throws_ok(
  format($$ select pg_temp.as_user(%L, 'select public.get_screen(''community.group'', ''en'', ''{"group_id": "%s"}'')') $$,
    (select member_one from ids), (select tuesday from ids)),
  'P0001', 'screen_unavailable', 'a member who left is refused the group'
);
select is(
  pg_temp.refusal_detail((select member_one from ids),
    format($$ select public.get_screen('community.group', 'en', '{"group_id": "%s"}') $$, (select tuesday from ids))),
  'You''re no longer in this group.', 'the refusal says they are no longer in the group'
);

-- AC4: a disabled account is refused with session_ended.
select throws_ok(
  format('select pg_temp.as_user(%L, %L)', (select disabled from ids), pg_temp.leave((select point_loma from ids))),
  'P0001', 'session_ended', 'a disabled account cannot leave'
);
select throws_ok(
  format('select pg_temp.as_user(%L, %L)', (select disabled from ids), pg_temp.remove((select point_loma from ids), (select mei from ids))),
  'P0001', 'session_ended', 'a disabled account cannot remove'
);

select * from finish();
rollback;
