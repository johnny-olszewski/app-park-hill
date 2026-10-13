-- whoami and require_active_user: signed-in identity reaches the backend, and
-- a missing or disabled account is refused with session_ended (SUP-005 AC4, AC7).
begin;

select plan(7);

-- AC4: a signed-in persona gets its own profile.
select set_config('request.jwt.claims', json_build_object('sub', id, 'role', 'authenticated')::text, true)
from auth.users where email = 'attendee@parkhill.test';
set local role authenticated;

select is(
  public.whoami(),
  jsonb_build_object('id', '9f6798b4-9e35-5b41-8207-9290979b50c3', 'display_name', 'Attendee'),
  'whoami returns the signed-in persona''s profile'
);

reset role;

-- AC4: a signed-out caller gets the documented error.
select set_config('request.jwt.claims', '{"role": "anon"}', true);
set local role anon;

select throws_ok(
  $$ select public.whoami() $$,
  'P0001', 'session_ended', 'whoami as anon raises session_ended'
);

reset role;

-- AC7: disabling an account refuses its still-valid token on the next request.
update auth.users set banned_until = now() + interval '1 day'
where email = 'attendee@parkhill.test';

select set_config('request.jwt.claims', json_build_object('sub', id, 'role', 'authenticated')::text, true)
from auth.users where email = 'attendee@parkhill.test';
set local role authenticated;

select throws_ok(
  $$ select public.whoami() $$,
  'P0001', 'session_ended', 'a disabled account''s token is refused with session_ended'
);

reset role;

-- A ban that has expired no longer refuses.
update auth.users set banned_until = now() - interval '1 minute'
where email = 'attendee@parkhill.test';
set local role authenticated;

select lives_ok(
  $$ select public.whoami() $$,
  'an expired ban no longer refuses'
);

reset role;

-- A deleted account is refused.
update auth.users set deleted_at = now() where email = 'attendee@parkhill.test';
set local role authenticated;

select throws_ok(
  $$ select public.whoami() $$,
  'P0001', 'session_ended', 'a deleted account is refused with session_ended'
);

reset role;

-- The check itself is internal; clients cannot call it.
select ok(
  not has_function_privilege('authenticated', 'internal.require_active_user()', 'execute'),
  'authenticated cannot call require_active_user directly'
);
select ok(
  has_function_privilege('anon', 'public.whoami()', 'execute'),
  'anon can call whoami (and gets session_ended)'
);

select * from finish();

rollback;
