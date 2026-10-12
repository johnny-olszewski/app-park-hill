-- Profiles, the shared signed-in check and whoami (SUP-005, specs/AUTH.md 4.3, 5.5.1).

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  created_at timestamptz not null default now()
);

comment on table public.profiles is
  'One row per account, created with the account. Private: a user can read only their own row.';

alter table public.profiles enable row level security;

revoke all on public.profiles from public, anon, authenticated;
grant select on public.profiles to authenticated;

create policy "Users read their own profile"
  on public.profiles for select
  to authenticated
  using (id = (select auth.uid()));

-- Creates the profile in the same transaction as the account. Display name
-- comes from the account's display_name metadata, else the email local part.
create function internal.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'display_name', ''),
      split_part(coalesce(new.email, ''), '@', 1)
    )
  );
  return new;
end;
$$;

revoke all on function internal.create_profile_for_new_user() from public, anon, authenticated;

create trigger create_profile_after_user_insert
  after insert on auth.users
  for each row execute function internal.create_profile_for_new_user();

-- Every signed-in function calls this first. Returns the caller's id, or
-- raises session_ended when there is no valid user or the account is banned
-- or deleted, so a disabled account is refused on its next request.
create function internal.require_active_user()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null or not exists (
    select 1
    from auth.users u
    where u.id = v_user_id
      and u.deleted_at is null
      and (u.banned_until is null or u.banned_until <= now())
  ) then
    raise exception 'session_ended'
      using hint = 'Sign in again.';
  end if;

  return v_user_id;
end;
$$;

revoke all on function internal.require_active_user() from public, anon, authenticated;

-- The caller's own profile. Proves signed-in identity reaches the backend.
create function public.whoami()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := internal.require_active_user();
begin
  return (
    select jsonb_build_object('id', p.id, 'display_name', p.display_name)
    from public.profiles p
    where p.id = v_user_id
  );
end;
$$;

revoke all on function public.whoami() from public, anon, authenticated;
-- anon may call it so a signed-out caller gets session_ended, not a grant error.
grant execute on function public.whoami() to anon, authenticated;
