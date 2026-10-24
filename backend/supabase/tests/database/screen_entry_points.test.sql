-- get_entry and get_screen: envelope, locale fallback, remote strings,
-- unknown keys and migration-provided configuration (SUP-003 AC1 to AC5, AC7).
begin;

select plan(12);

-- AC7: configuration comes from migrations, not seed.
select ok(
  exists (select 1 from public.screens where key = 'auth.sign_in'),
  'auth.sign_in is registered by migrations'
);

select is_empty(
  $$
    select s.key from public.screens s
    where not exists (
      select 1 from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'internal'
        and p.proname = s.data_function
        and pg_get_function_identity_arguments(p.oid) = 'p_locale text, p_params jsonb'
    )
  $$,
  'every registered screen has an internal data function'
);

set local role anon;

-- AC1: the signed-out entry screen, exactly as in contract/mock_responses/get_entry.json.
select is(
  public.get_entry('en'),
  '{
    "key": "auth.sign_in",
    "data": {
      "title": "Sign in",
      "email_label": "Email",
      "password_label": "Password",
      "submit_label": "Sign in",
      "cannot_connect_message": "Can''t connect. Check your connection and try again.",
      "session_ended_message": "You''ve been signed out. Please sign in again.",
      "secondary_actions": []
    }
  }'::jsonb,
  'get_entry(en) as anon returns the auth.sign_in envelope'
);

select is(
  public.get_entry('en') ? 'toolbar',
  false,
  'the envelope has no toolbar yet'
);

-- AC2: unseeded locales fall back to English.
select is(public.get_entry('es'), public.get_entry('en'), 'unseeded locale es returns English');
select is(public.get_entry(null), public.get_entry('en'), 'null locale returns English');

-- AC4: get_screen returns the same envelope as get_entry.
select is(
  public.get_screen('auth.sign_in', 'en', '{}'),
  public.get_entry('en'),
  'get_screen(auth.sign_in) matches get_entry'
);

-- AC5: unregistered keys raise the documented error.
select throws_ok(
  $$ select public.get_screen('does.not_exist', 'en', '{}') $$,
  'P0001',
  'unknown_screen',
  'get_screen with an unregistered key raises unknown_screen'
);

select throws_ok(
  $$ select public.get_screen('auth.sign_in.mock', 'en', '{}') $$,
  'P0001',
  'unknown_screen',
  'mock screen keys are never served by the backend'
);

reset role;

-- AC3: a string change shows in the next response with no other change.
update public.strings set value = 'Log in'
where key = 'auth.sign_in.title' and locale = 'en';

set local role anon;

select is(
  public.get_entry('en') -> 'data' ->> 'title',
  'Log in',
  'changing a string changes the next response'
);

reset role;

-- AC2: strings resolve per key, so a partly translated locale falls back key by key.
insert into public.strings (key, locale, value)
values ('auth.sign_in.title', 'es', 'Iniciar sesión');

set local role anon;

select is(
  public.get_entry('es') -> 'data' ->> 'title',
  'Iniciar sesión',
  'a seeded locale string is used'
);

select is(
  public.get_entry('es') -> 'data' ->> 'email_label',
  'Email',
  'a missing string in that locale falls back to English'
);

reset role;

select * from finish();

rollback;
