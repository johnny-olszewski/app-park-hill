-- Sign-in attempts and helpers are reachable only by the service role, which
-- the sign_in Edge Function uses (SUP-006).
begin;

select plan(12);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.auth_attempts'::regclass),
  'RLS is enabled on auth_attempts'
);
select policies_are('public', 'auth_attempts', array[]::name[], 'auth_attempts has no policies');

select ok(not has_function_privilege('anon', 'public.sign_in_failure_counts(text, text, timestamptz)', 'execute'), 'anon cannot count failures');
select ok(not has_function_privilege('authenticated', 'public.record_sign_in_attempt(text, text, text)', 'execute'), 'authenticated cannot record attempts');
select ok(not has_function_privilege('anon', 'public.sign_in_error_message(text, text)', 'execute'), 'anon cannot read sign-in messages directly');
select ok(has_function_privilege('service_role', 'public.record_sign_in_attempt(text, text, text)', 'execute'), 'service_role can record attempts');

select public.record_sign_in_attempt('hash-a', '203.0.113.1', 'failure');
select public.record_sign_in_attempt('hash-a', '203.0.113.1', 'failure');
select public.record_sign_in_attempt('hash-a', '203.0.113.2', 'disabled');
select public.record_sign_in_attempt('hash-b', '203.0.113.1', 'limited');

select is(
  public.sign_in_failure_counts('hash-a', '203.0.113.1', now() - interval '15 minutes'),
  '{"email": 2, "address": 2}'::jsonb,
  'only failures count, per email and per address'
);
select is(
  public.sign_in_failure_counts('hash-a', '203.0.113.1', now() + interval '1 minute'),
  '{"email": 0, "address": 0}'::jsonb,
  'attempts before the window do not count'
);

select is(
  public.sign_in_error_message('invalid_credentials', 'es'),
  'That email and password don''t match.',
  'messages fall back to English'
);

set local role anon;
select throws_ok($$ select * from public.auth_attempts $$, '42501', null, 'anon cannot read auth_attempts');
reset role;
set local role authenticated;
select throws_ok($$ select * from public.auth_attempts $$, '42501', null, 'authenticated cannot read auth_attempts');
select throws_ok($$ insert into public.auth_attempts (email_hash, client_address, outcome) values ('x', 'y', 'failure') $$, '42501', null, 'authenticated cannot write auth_attempts');
reset role;

select * from finish();

rollback;
