-- Data-driven roles, permissions and the permission check (SUP-009 AC1 to AC6, AC9).
begin;

select plan(27);

-- AC1: the roles and permissions in specs/ROLES.md are migration data.
select results_eq(
  $$ select key from public.roles where assignable order by key $$,
  array['admin', 'attendee', 'staff'],
  'the assigned roles exist'
);
select results_eq(
  $$ select key from public.permissions order by key $$,
  array[
    'directory.always_listed', 'directory.eligible',
    'groups.add_member', 'groups.assign_leader', 'groups.create', 'groups.delete',
    'groups.edit_details', 'groups.remove_member', 'groups.view_all',
    'people.view_all_eligible', 'roles.assign_admin', 'roles.assign_staff'
  ],
  'the permissions exist'
);
select is_empty(
  $$ select 1 from public.role_permissions rp join public.roles r on r.id = rp.role_id where r.key = 'attendee' $$,
  'attendee grants nothing'
);
select results_eq(
  $$ select p.key from public.role_permissions rp
     join public.roles r on r.id = rp.role_id join public.permissions p on p.id = rp.permission_id
     where r.key = 'admin'
     except
     select p.key from public.role_permissions rp
     join public.roles r on r.id = rp.role_id join public.permissions p on p.id = rp.permission_id
     where r.key = 'staff'
     order by 1 $$,
  array['roles.assign_admin', 'roles.assign_staff'],
  'admin grants everything staff does, plus assigning roles'
);
select is(
  (select count(*)::int from public.role_permissions rp
   join public.roles r on r.id = rp.role_id where r.key = 'staff'),
  10,
  'staff grants every group and directory permission'
);

-- Personas: admin holds staff and admin; every persona holds attendee.
select results_eq(
  $$ select r.key from public.user_roles ur join public.roles r on r.id = ur.role_id
     join auth.users u on u.id = ur.user_id where u.email = 'admin@parkhill.test' order by r.key $$,
  array['admin', 'attendee', 'staff'],
  'the admin persona holds attendee, staff and admin'
);
select is_empty(
  $$ select 1 from auth.users u where u.email like '%@parkhill.test' and not exists (
       select 1 from public.user_roles ur join public.roles r on r.id = ur.role_id
       where ur.user_id = u.id and r.key = 'attendee') $$,
  'every persona holds attendee'
);

-- AC2: a new account gets attendee in the same transaction.
insert into auth.users (id, email, raw_user_meta_data)
values ('33333333-3333-3333-3333-333333333333', 'new.role@example.com', '{}');
select results_eq(
  $$ select r.key from public.user_roles ur join public.roles r on r.id = ur.role_id
     where ur.user_id = '33333333-3333-3333-3333-333333333333' $$,
  array['attendee'],
  'a new account holds attendee'
);

-- AC3: permissions are the union of the user's roles.
select ok(
  not internal.has_permission('33333333-3333-3333-3333-333333333333', 'groups.view_all'),
  'an attendee lacks groups.view_all'
);
insert into public.user_roles (user_id, role_id)
select '33333333-3333-3333-3333-333333333333', id from public.roles where key = 'staff';
select ok(
  internal.has_permission('33333333-3333-3333-3333-333333333333', 'groups.view_all'),
  'adding staff grants groups.view_all'
);
select ok(
  internal.has_permission('33333333-3333-3333-3333-333333333333', 'groups.edit_details', gen_random_uuid()),
  'an assigned role grants a group-scoped permission for any group'
);
select ok(
  not internal.has_permission('33333333-3333-3333-3333-333333333333', 'roles.assign_admin'),
  'staff lacks roles.assign_admin'
);
select ok(
  internal.has_permission(
    (select id from auth.users where email = 'admin@parkhill.test'), 'roles.assign_admin'),
  'the admin persona holds roles.assign_admin'
);
select ok(
  not internal.has_permission('33333333-3333-3333-3333-333333333333', 'no.such_permission'),
  'an unknown permission is never held'
);

-- AC4: changing a grant changes the result with no code change.
insert into public.role_permissions (role_id, permission_id)
select r.id, p.id from public.roles r, public.permissions p
where r.key = 'attendee' and p.key = 'directory.eligible';
select ok(
  internal.has_permission(
    (select id from auth.users where email = 'attendee@parkhill.test'), 'directory.eligible'),
  'granting attendee a permission gives it to attendees'
);
delete from public.role_permissions
where role_id = (select id from public.roles where key = 'staff')
  and permission_id = (select id from public.permissions where key = 'groups.view_all');
select ok(
  not internal.has_permission('33333333-3333-3333-3333-333333333333', 'groups.view_all'),
  'revoking a grant from staff takes it from staff'
);

-- Derived roles are never assigned.
insert into public.roles (key, assignable) values ('derived_test', false);
select throws_ok(
  $$ insert into public.user_roles (user_id, role_id)
     select '33333333-3333-3333-3333-333333333333', id from public.roles where key = 'derived_test' $$,
  'P0001', 'role_not_assignable',
  'a derived role cannot be assigned'
);

-- AC5: the last admin cannot lose the admin role.
select throws_ok(
  $$ delete from public.user_roles
     where user_id = (select id from auth.users where email = 'admin@parkhill.test')
       and role_id = (select id from public.roles where key = 'admin') $$,
  'P0001', 'last_admin',
  'removing admin from the last admin is refused'
);
insert into public.user_roles (user_id, role_id)
select '33333333-3333-3333-3333-333333333333', id from public.roles where key = 'admin';
select lives_ok(
  $$ delete from public.user_roles
     where user_id = (select id from auth.users where email = 'admin@parkhill.test')
       and role_id = (select id from public.roles where key = 'admin') $$,
  'removing admin is allowed while another admin remains'
);
select throws_ok(
  $$ delete from public.user_roles
     where user_id = '33333333-3333-3333-3333-333333333333'
       and role_id = (select id from public.roles where key = 'admin') $$,
  'P0001', 'last_admin',
  'the remaining admin is now the last admin'
);

-- AC9: every table has a nullable org_id, null in every row, with no default.
select col_is_null('public', 'roles', 'org_id', 'roles.org_id is nullable');
select col_is_null('public', 'user_roles', 'org_id', 'user_roles.org_id is nullable');
select col_hasnt_default('public', 'permissions', 'org_id', 'permissions.org_id has no default');
select col_hasnt_default('public', 'role_permissions', 'org_id', 'role_permissions.org_id has no default');
select is_empty(
  $$ select 1 from public.roles where org_id is not null
     union all select 1 from public.permissions where org_id is not null
     union all select 1 from public.role_permissions where org_id is not null
     union all select 1 from public.user_roles where org_id is not null $$,
  'org_id is null in every row'
);

-- AC6: clients cannot read or write these tables.
select set_config('request.jwt.claims', json_build_object('sub', id, 'role', 'authenticated')::text, true)
from auth.users where email = 'attendee@parkhill.test';
set local role authenticated;
select throws_ok($$ select * from public.user_roles $$, '42501', null, 'authenticated cannot read user_roles');
select throws_ok(
  $$ insert into public.role_permissions (role_id, permission_id) values (gen_random_uuid(), gen_random_uuid()) $$,
  '42501', null, 'authenticated cannot write role_permissions'
);
reset role;

select * from finish();
rollback;
