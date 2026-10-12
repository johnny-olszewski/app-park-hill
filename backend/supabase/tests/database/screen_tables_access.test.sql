-- Clients reach screens and strings only through functions (SUP-003 AC6).
begin;

select plan(14);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.screens'::regclass),
  'RLS is enabled on screens'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.strings'::regclass),
  'RLS is enabled on strings'
);

select policies_are('public', 'screens', array[]::name[], 'screens has no policies');
select policies_are('public', 'strings', array[]::name[], 'strings has no policies');

select ok(
  has_function_privilege('anon', 'public.get_entry(text)', 'execute'),
  'anon can execute get_entry'
);
select ok(
  has_function_privilege('anon', 'public.get_screen(text, text, jsonb)', 'execute'),
  'anon can execute get_screen'
);
select ok(
  has_function_privilege('authenticated', 'public.get_screen(text, text, jsonb)', 'execute'),
  'authenticated can execute get_screen'
);
select ok(
  not has_schema_privilege('anon', 'internal', 'usage'),
  'anon cannot use the internal schema'
);

set local role anon;

select throws_ok(
  $$ select * from public.screens $$,
  '42501', null, 'anon cannot read screens'
);
select throws_ok(
  $$ select * from public.strings $$,
  '42501', null, 'anon cannot read strings'
);
select throws_ok(
  $$ insert into public.screens (key, data_function) values ('x', 'screen_x') $$,
  '42501', null, 'anon cannot insert screens'
);
select throws_ok(
  $$ update public.strings set value = 'x' $$,
  '42501', null, 'anon cannot update strings'
);

reset role;
set local role authenticated;

select throws_ok(
  $$ select * from public.strings $$,
  '42501', null, 'authenticated cannot read strings'
);
select throws_ok(
  $$ delete from public.screens $$,
  '42501', null, 'authenticated cannot delete screens'
);

reset role;

select * from finish();

rollback;
