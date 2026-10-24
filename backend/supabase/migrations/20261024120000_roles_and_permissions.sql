-- Roles and permissions as data (SUP-009, specs/ROLES.md). App configuration:
-- roles, permissions and their grants are migration rows; who holds which
-- assigned role is seed or app data. Every rule asks has_permission, never a
-- role key, so a role's permissions change without a release.

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  key text not null unique
    check (key ~ '^[a-z][a-z0-9_]*$'),
  assignable boolean not null,
  granted_on_sign_up boolean not null default false,
  org_id uuid
);

comment on table public.roles is
  'Roles. assignable roles are held through user_roles; the others are derived from group memberships (group_types).';
comment on column public.roles.granted_on_sign_up is
  'When true, every new account is given this role as it is created.';
comment on column public.roles.org_id is
  'Organization scoping (guide 4): null in every row until a second organization exists. Nothing reads it yet.';

create table public.permissions (
  id uuid primary key default gen_random_uuid(),
  key text not null unique
    check (key ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$'),
  group_scoped boolean not null,
  org_id uuid
);

comment on table public.permissions is
  'Permissions checked by has_permission. A group_scoped permission granted by a derived role applies only to the group that role comes from.';
comment on column public.permissions.org_id is
  'Organization scoping (guide 4): null in every row until a second organization exists. Nothing reads it yet.';

create table public.role_permissions (
  role_id uuid not null references public.roles (id) on delete cascade,
  permission_id uuid not null references public.permissions (id) on delete cascade,
  org_id uuid,
  primary key (role_id, permission_id)
);

comment on table public.role_permissions is
  'Which permissions each role grants. A user''s permissions are the union over their effective roles.';
comment on column public.role_permissions.org_id is
  'Organization scoping (guide 4): null in every row until a second organization exists. Nothing reads it yet.';

create table public.user_roles (
  user_id uuid not null references auth.users (id) on delete cascade,
  role_id uuid not null references public.roles (id) on delete cascade,
  org_id uuid,
  primary key (user_id, role_id)
);

comment on table public.user_roles is
  'Assigned roles held by each account. Derived roles are never stored here.';
comment on column public.user_roles.org_id is
  'Organization scoping (guide 4): null in every row until a second organization exists. Nothing reads it yet.';

-- Clients never touch these tables; all access goes through functions.
alter table public.roles enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.user_roles enable row level security;
revoke all on public.roles, public.permissions, public.role_permissions, public.user_roles
  from public, anon, authenticated;

-- Only assignable roles are held through user_roles.
create function internal.check_assignable_role()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not (select r.assignable from public.roles r where r.id = new.role_id) then
    raise exception 'role_not_assignable'
      using hint = 'Derived roles come from group memberships and are never assigned.';
  end if;
  return new;
end;
$$;

revoke all on function internal.check_assignable_role() from public, anon, authenticated;

create trigger check_assignable_role
  before insert or update on public.user_roles
  for each row execute function internal.check_assignable_role();

-- Roles a user derives from group memberships, with the group each comes
-- from. None until groups exist (SUP-010 replaces this).
create function internal.derived_roles(p_user_id uuid)
returns table (role_id uuid, group_id uuid)
language sql
stable
security definer
set search_path = ''
as $$
  select null::uuid, null::uuid where false;
$$;

revoke all on function internal.derived_roles(uuid) from public, anon, authenticated;

-- Whether p_user_id holds p_permission, over their effective roles. Assigned
-- roles grant everywhere. A derived role grants a group-scoped permission
-- only for the group it comes from (p_group_id), and any other permission
-- wherever it comes from.
create function internal.has_permission(p_user_id uuid, p_permission text, p_group_id uuid default null)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.permissions p
    join public.role_permissions rp on rp.permission_id = p.id
    where p.key = p_permission
      and (
        rp.role_id in (select ur.role_id from public.user_roles ur where ur.user_id = p_user_id)
        or exists (
          select 1
          from internal.derived_roles(p_user_id) d
          where d.role_id = rp.role_id
            and (not p.group_scoped or d.group_id = p_group_id)
        )
      )
  );
$$;

revoke all on function internal.has_permission(uuid, text, uuid) from public, anon, authenticated;

-- The last admin cannot lose the admin role (specs/ROLES.md rule 2). An admin
-- is whoever holds roles.assign_admin through an assigned role; a change that
-- leaves nobody holding it is refused.
create function internal.check_last_admin()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if exists (
    select 1
    from public.role_permissions rp
    join public.permissions p on p.id = rp.permission_id
    where rp.role_id = old.role_id and p.key = 'roles.assign_admin'
  ) and not exists (
    select 1
    from public.user_roles ur
    join public.role_permissions rp on rp.role_id = ur.role_id
    join public.permissions p on p.id = rp.permission_id
    where p.key = 'roles.assign_admin'
  ) then
    raise exception 'last_admin'
      using hint = 'At least one person must keep the admin role.';
  end if;
  return null;
end;
$$;

revoke all on function internal.check_last_admin() from public, anon, authenticated;

create trigger check_last_admin
  after delete or update on public.user_roles
  for each row execute function internal.check_last_admin();

-- Every new account gets the roles marked granted_on_sign_up (attendee) in
-- the same transaction.
create function internal.grant_sign_up_roles()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.user_roles (user_id, role_id)
  select new.id, r.id from public.roles r where r.granted_on_sign_up;
  return new;
end;
$$;

revoke all on function internal.grant_sign_up_roles() from public, anon, authenticated;

create trigger grant_sign_up_roles_after_user_insert
  after insert on auth.users
  for each row execute function internal.grant_sign_up_roles();

insert into public.roles (key, assignable, granted_on_sign_up) values
  ('attendee', true, true),
  ('staff', true, false),
  ('admin', true, false);

insert into public.permissions (key, group_scoped) values
  ('groups.view_all', false),
  ('groups.edit_details', true),
  ('groups.add_member', true),
  ('groups.remove_member', true),
  ('groups.assign_leader', true),
  ('groups.create', false),
  ('groups.delete', true),
  ('roles.assign_staff', false),
  ('roles.assign_admin', false),
  ('directory.eligible', false),
  ('directory.always_listed', false),
  ('people.view_all_eligible', false);

-- Staff: every group permission and the directory. Admin: everything staff
-- has, plus assigning roles.
insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.key in (
  'groups.view_all', 'groups.edit_details', 'groups.add_member', 'groups.remove_member',
  'groups.assign_leader', 'groups.create', 'groups.delete',
  'directory.eligible', 'directory.always_listed', 'people.view_all_eligible'
)
where r.key in ('staff', 'admin');

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.key in ('roles.assign_staff', 'roles.assign_admin')
where r.key = 'admin';
