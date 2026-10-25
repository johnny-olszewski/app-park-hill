-- Profiles are created with accounts, personas are seeded, and profiles are
-- private (SUP-005 AC1, AC2, AC5).
begin;

select plan(14);

-- AC2: every persona exists after reset; disabled is banned.
select results_eq(
  $$ select email::text from auth.users where email like '%@parkhill.test' order by email $$,
  array[
    'admin@parkhill.test', 'attendee@parkhill.test', 'disabled@parkhill.test', 'leader@parkhill.test',
    'member.one@parkhill.test', 'member.two@parkhill.test', 'staff@parkhill.test'
  ],
  'each persona has an account'
);
select ok(
  (select banned_until > now() from auth.users where email = 'disabled@parkhill.test'),
  'disabled is banned'
);
select ok(
  (select banned_until is null from auth.users where email = 'attendee@parkhill.test'),
  'attendee is not banned'
);
select is(
  (select p.display_name from public.profiles p join auth.users u on u.id = p.id where u.email = 'admin@parkhill.test'),
  'Admin',
  'persona profiles use the dataset display name'
);

-- AC1: creating an account creates its profile in the same transaction.
insert into auth.users (id, email, raw_user_meta_data)
values ('11111111-1111-1111-1111-111111111111', 'new.person@example.com', '{}');

select is(
  (select display_name from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  'new.person',
  'a new account gets a profile named after its email local part'
);

insert into auth.users (id, email, raw_user_meta_data)
values ('22222222-2222-2222-2222-222222222222', 'named@example.com', '{"display_name": "Named Person"}');

select is(
  (select display_name from public.profiles where id = '22222222-2222-2222-2222-222222222222'),
  'Named Person',
  'display_name metadata wins over the email'
);

delete from auth.users where id = '22222222-2222-2222-2222-222222222222';
select is_empty(
  $$ select 1 from public.profiles where id = '22222222-2222-2222-2222-222222222222' $$,
  'deleting an account deletes its profile'
);

-- AC5: profiles are private.
select ok(
  (select relrowsecurity from pg_class where oid = 'public.profiles'::regclass),
  'RLS is enabled on profiles'
);

select set_config('request.jwt.claims', json_build_object('sub', id, 'role', 'authenticated')::text, true)
from auth.users where email = 'attendee@parkhill.test';
set local role authenticated;

select results_eq(
  $$ select display_name from public.profiles $$,
  array['Attendee'],
  'a signed-in user sees only their own profile'
);
select is_empty(
  $$ select 1 from public.profiles where id = 'c02348f0-ad95-58bc-a073-cd90ea7ac705' $$,
  'a signed-in user cannot read another profile'
);
select throws_ok(
  $$ update public.profiles set display_name = 'Hacked' $$,
  '42501', null, 'a signed-in user cannot update profiles directly'
);
select throws_ok(
  $$ insert into public.profiles (id, display_name) values (gen_random_uuid(), 'x') $$,
  '42501', null, 'a signed-in user cannot insert profiles'
);
select throws_ok(
  $$ delete from public.profiles $$,
  '42501', null, 'a signed-in user cannot delete profiles'
);

reset role;
set local role anon;

select throws_ok(
  $$ select * from public.profiles $$,
  '42501', null, 'anon cannot read profiles'
);

reset role;

select * from finish();

rollback;
