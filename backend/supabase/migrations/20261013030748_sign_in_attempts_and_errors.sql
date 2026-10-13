-- Sign-in attempt limiting and error messages for the sign_in Edge Function
-- (SUP-006, specs/AUTH.md 5.5). Only the function, using the service role,
-- touches these; clients cannot.

create table public.auth_attempts (
  id bigint generated always as identity primary key,
  email_hash text not null,
  client_address text not null,
  outcome text not null check (outcome in ('success', 'failure', 'disabled', 'limited')),
  attempted_at timestamptz not null default now()
);

comment on table public.auth_attempts is
  'Sign-in attempts for attempt limiting. Emails are stored only as keyed hashes; passwords are never stored.';

create index auth_attempts_email_recent on public.auth_attempts (email_hash, attempted_at);
create index auth_attempts_address_recent on public.auth_attempts (client_address, attempted_at);

alter table public.auth_attempts enable row level security;
revoke all on public.auth_attempts from public, anon, authenticated;

-- Failed attempts since p_since, per email and per client address.
create function public.sign_in_failure_counts(p_email_hash text, p_client_address text, p_since timestamptz)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'email', (
      select count(*) from public.auth_attempts
      where email_hash = p_email_hash and outcome = 'failure' and attempted_at >= p_since
    ),
    'address', (
      select count(*) from public.auth_attempts
      where client_address = p_client_address and outcome = 'failure' and attempted_at >= p_since
    )
  );
$$;

create function public.record_sign_in_attempt(p_email_hash text, p_client_address text, p_outcome text)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.auth_attempts (email_hash, client_address, outcome)
  values (p_email_hash, p_client_address, p_outcome);
$$;

-- The localized message for a sign-in error code (auth.error.<code>).
create function public.sign_in_error_message(p_code text, p_locale text)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select internal.t('auth.error.' || p_code, coalesce(p_locale, 'en'));
$$;

revoke all on function public.sign_in_failure_counts(text, text, timestamptz) from public, anon, authenticated;
revoke all on function public.record_sign_in_attempt(text, text, text) from public, anon, authenticated;
revoke all on function public.sign_in_error_message(text, text) from public, anon, authenticated;
grant execute on function public.sign_in_failure_counts(text, text, timestamptz) to service_role;
grant execute on function public.record_sign_in_attempt(text, text, text) to service_role;
grant execute on function public.sign_in_error_message(text, text) to service_role;

insert into public.strings (key, locale, value) values
  ('auth.error.invalid_credentials', 'en', 'That email and password don''t match.'),
  ('auth.error.account_disabled', 'en', 'This account has been disabled.'),
  ('auth.error.too_many_attempts', 'en', 'Too many sign-in attempts. Wait a few minutes and try again.'),
  ('auth.error.invalid_request', 'en', 'Enter your email and password.'),
  ('auth.error.unknown', 'en', 'Something went wrong. Please try again.');
