-- Typed groups, membership and leadership (SUP-010, specs/COMMUNITY.md 7,
-- specs/ROLES.md 1). App configuration: group types, derived roles, their
-- grants and the church time zone are migration rows; groups and who is in
-- them are seed or app data.

-- Church-wide settings, read by key.
create table public.settings (
  key text primary key
    check (key ~ '^[a-z][a-z0-9_]*$'),
  value text not null
);

comment on table public.settings is
  'Church-wide settings by key. church_time_zone is the IANA zone meeting times are local to.';

alter table public.settings enable row level security;
revoke all on public.settings from public, anon, authenticated;

create function internal.setting(p_key text)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select s.value from public.settings s where s.key = p_key;
$$;

revoke all on function internal.setting(text) from public, anon, authenticated;

insert into public.settings (key, value) values ('church_time_zone', 'America/Los_Angeles');

-- Each kind of group names the role its membership grants and the role its
-- leadership grants. A new kind of group is a row here, roles and grants.
create table public.group_types (
  id uuid primary key default gen_random_uuid(),
  key text not null unique
    check (key ~ '^[a-z][a-z0-9_]*$'),
  membership_role_id uuid not null references public.roles (id),
  leadership_role_id uuid not null references public.roles (id),
  org_id uuid
);

comment on table public.group_types is
  'Kinds of group. Members derive membership_role_id and leaders leadership_role_id, for that group.';
comment on column public.group_types.org_id is
  'Organization scoping (guide 4): null in every row until a second organization exists. Nothing reads it yet.';

create table public.groups (
  id uuid primary key default gen_random_uuid(),
  group_type_id uuid not null references public.group_types (id),
  name text not null check (btrim(name) <> ''),
  description text not null default '',
  meeting_day smallint check (meeting_day between 1 and 7),
  meeting_time time,
  location text not null default '',
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  org_id uuid
);

comment on table public.groups is
  'Groups of every type. meeting_day is ISO (1 Monday to 7 Sunday); meeting_time is local to church_time_zone. Archived groups (archived_at set) are hidden everywhere and grant nothing.';
comment on column public.groups.org_id is
  'Organization scoping (guide 4): null in every row until a second organization exists. Nothing reads it yet.';

create table public.group_members (
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  org_id uuid,
  primary key (group_id, user_id)
);

comment on column public.group_members.org_id is
  'Organization scoping (guide 4): null in every row until a second organization exists. Nothing reads it yet.';

-- A leader is always a member: removing the membership removes the
-- leadership with it.
create table public.group_leaders (
  group_id uuid not null,
  user_id uuid not null,
  org_id uuid,
  primary key (group_id, user_id),
  foreign key (group_id, user_id) references public.group_members (group_id, user_id) on delete cascade
);

comment on column public.group_leaders.org_id is
  'Organization scoping (guide 4): null in every row until a second organization exists. Nothing reads it yet.';

alter table public.group_types enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.group_leaders enable row level security;
revoke all on public.group_types, public.groups, public.group_members, public.group_leaders
  from public, anon, authenticated;

-- Making a leader adds the membership when it is missing.
create function internal.add_membership_for_leader()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.group_members (group_id, user_id)
  values (new.group_id, new.user_id)
  on conflict do nothing;
  return new;
end;
$$;

revoke all on function internal.add_membership_for_leader() from public, anon, authenticated;

create trigger add_membership_for_leader
  before insert on public.group_leaders
  for each row execute function internal.add_membership_for_leader();

-- Derived roles: each membership and leadership in a group that is not
-- archived grants its type's role for that group.
create or replace function internal.derived_roles(p_user_id uuid)
returns table (role_id uuid, group_id uuid)
language sql
stable
security definer
set search_path = ''
as $$
  select gt.membership_role_id, g.id
  from public.group_members m
  join public.groups g on g.id = m.group_id and g.archived_at is null
  join public.group_types gt on gt.id = g.group_type_id
  where m.user_id = p_user_id
  union
  select gt.leadership_role_id, g.id
  from public.group_leaders l
  join public.groups g on g.id = l.group_id and g.archived_at is null
  join public.group_types gt on gt.id = g.group_type_id
  where l.user_id = p_user_id;
$$;

-- Whether p_actor may remove p_target from p_group_id: groups.remove_member
-- for the group, and groups.assign_leader as well when the target leads it,
-- so leaders cannot remove other leaders (specs/ROLES.md rule 1).
create function internal.can_remove_member(p_actor uuid, p_group_id uuid, p_target uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select internal.has_permission(p_actor, 'groups.remove_member', p_group_id)
    and (
      not exists (
        select 1 from public.group_leaders l where l.group_id = p_group_id and l.user_id = p_target
      )
      or internal.has_permission(p_actor, 'groups.assign_leader', p_group_id)
    );
$$;

revoke all on function internal.can_remove_member(uuid, uuid, uuid) from public, anon, authenticated;

-- Community groups: members derive member; leaders derive leader, which
-- manages its own group but cannot assign leaders.
insert into public.roles (key, assignable) values
  ('member', false),
  ('leader', false);

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.key = 'directory.eligible'
where r.key in ('member', 'leader');

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.key in ('groups.edit_details', 'groups.add_member', 'groups.remove_member')
where r.key = 'leader';

insert into public.group_types (key, membership_role_id, leadership_role_id)
select 'community', m.id, l.id
from public.roles m, public.roles l
where m.key = 'member' and l.key = 'leader';
