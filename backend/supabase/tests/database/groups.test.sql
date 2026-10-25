-- Groups, membership, leadership and derived permissions (SUP-010 AC1 to AC9).
begin;

select plan(36);

create temporary table ids as
select
  (select id from auth.users where email = 'attendee@parkhill.test') as attendee,
  (select id from auth.users where email = 'member.one@parkhill.test') as member_one,
  (select id from auth.users where email = 'member.two@parkhill.test') as member_two,
  (select id from auth.users where email = 'leader@parkhill.test') as leader,
  (select id from auth.users where email = 'staff@parkhill.test') as staff,
  (select id from auth.users where email = 'admin@parkhill.test') as admin,
  (select id from public.groups where name = 'Tuesday Night Group') as tuesday,
  (select id from public.groups where name = 'Mission Hills Group') as mission,
  (select id from public.groups where name = 'Point Loma Group') as point_loma;
grant select on ids to authenticated;

-- AC6: the seed creates the spec's personas and groups.
select is(
  (select count(*)::int from public.groups
   where name in ('Mission Hills Group', 'Point Loma Group', 'Tuesday Night Group', 'Young Families')),
  4,
  'the seed groups the personas are in exist, among the others'
);
select results_eq(
  $$ select g.name from public.groups g
     where not exists (select 1 from public.group_leaders l where l.group_id = g.id) $$,
  array['Point Loma Group'],
  'exactly one seed group is leaderless'
);
select results_eq(
  $$ select u.email::text, count(m.group_id)::int from auth.users u
     left join public.group_members m on m.user_id = u.id
     where u.email in ('attendee@parkhill.test', 'member.one@parkhill.test', 'member.two@parkhill.test',
                       'leader@parkhill.test', 'staff@parkhill.test', 'admin@parkhill.test')
     group by u.email order by u.email $$,
  $$ values ('admin@parkhill.test', 1), ('attendee@parkhill.test', 0), ('leader@parkhill.test', 1),
            ('member.one@parkhill.test', 1), ('member.two@parkhill.test', 2), ('staff@parkhill.test', 0) $$,
  'each persona is in the groups the spec gives them'
);
select ok(
  exists (select 1 from public.group_leaders l, ids where l.group_id = ids.mission and l.user_id = ids.admin),
  'admin leads one group'
);
select is(
  internal.setting('church_time_zone'),
  'America/Los_Angeles',
  'the church time zone is a setting'
);

-- AC1: leadership sits on top of membership.
select lives_ok(
  $$ insert into public.group_leaders (group_id, user_id) select point_loma, attendee from ids $$,
  'a non-member can be made a leader'
);
select ok(
  exists (select 1 from public.group_members m, ids where m.group_id = ids.point_loma and m.user_id = ids.attendee),
  'making a non-member a leader also makes them a member'
);
delete from public.group_members m using ids where m.group_id = ids.point_loma and m.user_id = ids.attendee;
select ok(
  not exists (select 1 from public.group_leaders l, ids where l.group_id = ids.point_loma and l.user_id = ids.attendee),
  'removing a member also removes their leadership'
);
select throws_ok(
  $$ insert into public.group_members (group_id, user_id) select tuesday, member_one from ids $$,
  '23505', null,
  'a person is a member of a group at most once'
);

-- Derived roles: membership gives member and leadership gives leader, per group.
select results_eq(
  $$ select r.key from internal.derived_roles((select leader from ids)) d
     join public.roles r on r.id = d.role_id order by r.key $$,
  array['leader', 'member'],
  'a leader derives member and leader'
);
select is_empty(
  $$ select 1 from public.user_roles ur join public.roles r on r.id = ur.role_id
     where r.key in ('member', 'leader') $$,
  'derived roles are never stored'
);

-- AC3, AC4: one allowed and one refused test per group-scoped permission.
select ok(internal.has_permission((select leader from ids), 'groups.edit_details', (select tuesday from ids)),
  'edit_details: a leader may edit their own group');
select ok(not internal.has_permission((select leader from ids), 'groups.edit_details', (select mission from ids)),
  'edit_details: a leader may not edit another group');
select ok(not internal.has_permission((select member_one from ids), 'groups.edit_details', (select tuesday from ids)),
  'edit_details: a member may not edit their group');
select ok(internal.has_permission((select staff from ids), 'groups.edit_details', (select tuesday from ids)),
  'edit_details: staff may edit any group');

select ok(internal.has_permission((select leader from ids), 'groups.add_member', (select tuesday from ids)),
  'add_member: a leader may add to their own group');
select ok(not internal.has_permission((select leader from ids), 'groups.add_member', (select mission from ids)),
  'add_member: a leader may not add to another group');
select ok(not internal.has_permission((select attendee from ids), 'groups.add_member', (select tuesday from ids)),
  'add_member: an attendee may not add');

select ok(internal.can_remove_member((select leader from ids), (select tuesday from ids), (select member_one from ids)),
  'remove_member: a leader may remove a member of their own group');
select ok(not internal.can_remove_member((select leader from ids), (select mission from ids), (select admin from ids)),
  'remove_member: a leader may not remove from another group');
select ok(internal.can_remove_member((select staff from ids), (select tuesday from ids), (select leader from ids)),
  'remove_member: staff may remove a leader');

select ok(not internal.has_permission((select leader from ids), 'groups.assign_leader', (select tuesday from ids)),
  'assign_leader: a leader may not assign leaders, even in their own group');
select ok(internal.has_permission((select admin from ids), 'groups.assign_leader', (select tuesday from ids)),
  'assign_leader: admin may assign leaders in any group');

select ok(not internal.has_permission((select leader from ids), 'groups.delete', (select tuesday from ids)),
  'delete: a leader may not delete their own group');
select ok(internal.has_permission((select staff from ids), 'groups.delete', (select tuesday from ids)),
  'delete: staff may delete any group');

select ok(not internal.has_permission((select member_one from ids), 'groups.view_all'),
  'view_all: a member may not browse all groups');
select ok(internal.has_permission((select staff from ids), 'groups.view_all'),
  'view_all: staff may browse all groups');

-- AC5: a leader cannot remove another leader.
insert into public.group_leaders (group_id, user_id) select tuesday, member_two from ids;
select ok(not internal.can_remove_member((select leader from ids), (select tuesday from ids), (select member_two from ids)),
  'a leader may not remove another leader');

-- AC2: an archived group grants nothing.
update public.groups set archived_at = now() from ids where groups.id = ids.tuesday;
select ok(not internal.has_permission((select leader from ids), 'groups.edit_details', (select tuesday from ids)),
  'leading an archived group grants nothing');
select is_empty(
  $$ select 1 from internal.derived_roles((select member_one from ids)) $$,
  'membership of an archived group derives no role'
);
update public.groups set archived_at = null from ids where groups.id = ids.tuesday;

-- AC8: a new kind of group is data only.
insert into public.roles (key, assignable) values ('server_test', false), ('team_lead_test', false);
insert into public.permissions (key, group_scoped) values ('serving.test', false);
insert into public.role_permissions (role_id, permission_id)
select r.id, p.id from public.roles r, public.permissions p where r.key = 'server_test' and p.key = 'serving.test';
insert into public.group_types (key, membership_role_id, leadership_role_id)
select 'serving_test', m.id, l.id from public.roles m, public.roles l
where m.key = 'server_test' and l.key = 'team_lead_test';
insert into public.groups (id, group_type_id, name)
select '44444444-4444-4444-4444-444444444444', id, 'Test team' from public.group_types where key = 'serving_test';
insert into public.group_members (group_id, user_id) select '44444444-4444-4444-4444-444444444444', attendee from ids;
select ok(internal.has_permission((select attendee from ids), 'serving.test'),
  'a member of a new group type holds its derived role''s permission');
select ok(not internal.has_permission((select member_one from ids), 'serving.test'),
  'a non-member of the new group type does not');

-- AC9: nullable org_id with no default, null in every row.
select is_empty(
  $$ select table_name from information_schema.columns
     where table_schema = 'public' and column_name = 'org_id'
       and table_name in ('group_types', 'groups', 'group_members', 'group_leaders')
       and (is_nullable = 'NO' or column_default is not null)
     union all
     select t from (values ('group_types'), ('groups'), ('group_members'), ('group_leaders')) v(t)
     where not exists (select 1 from information_schema.columns c
                       where c.table_schema = 'public' and c.table_name = v.t and c.column_name = 'org_id') $$,
  'each groups table has a nullable org_id with no default'
);
select is_empty(
  $$ select 1 from public.group_types where org_id is not null
     union all select 1 from public.groups where org_id is not null
     union all select 1 from public.group_members where org_id is not null
     union all select 1 from public.group_leaders where org_id is not null $$,
  'org_id is null in every row'
);

-- AC7: clients cannot read or write these tables.
select set_config('request.jwt.claims', json_build_object('sub', member_one, 'role', 'authenticated')::text, true)
from ids;
set local role authenticated;
select throws_ok($$ select * from public.groups $$, '42501', null, 'authenticated cannot read groups');
select throws_ok(
  $$ insert into public.group_members (group_id, user_id) select tuesday, attendee from ids $$,
  '42501', null, 'authenticated cannot write group_members'
);
reset role;

select * from finish();
rollback;
