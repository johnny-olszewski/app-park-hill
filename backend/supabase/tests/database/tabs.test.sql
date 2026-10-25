-- get_tabs and the tab root screens (SUP-008 AC1 to AC7, AC9, AC10).
begin;

select plan(17);

-- Signed in as a persona.
select set_config('request.jwt.claims', json_build_object('sub', id, 'role', 'authenticated')::text, true)
from auth.users where email = 'attendee@parkhill.test';
set local role authenticated;

-- AC1: the tabs in order with their root screens, exactly as in
-- contract/mock_responses/<persona>/get_tabs.json.
select is(
  public.get_tabs('en'),
  '{
    "tabs": [
      {"id": "home", "title": "Home", "icon_key": "tab.home", "screen": {"key": "home.root", "data": {}}},
      {"id": "community", "title": "Community", "icon_key": "tab.community", "screen": {"key": "community.home", "data": {"empty": {
        "title": "You''re not in a community group yet.",
        "message": "Community Groups gather through the week to study the Bible, talk and live life together. A staff member can add you to one."
      }}}}
    ]
  }'::jsonb,
  'get_tabs(en) returns the tabs in order with their root screens'
);

-- AC3: titles fall back to English.
select is(public.get_tabs('es'), public.get_tabs('en'), 'unseeded locale es returns English titles');
select is(public.get_tabs(null), public.get_tabs('en'), 'null locale returns English titles');

-- AC5: get_screen returns the envelope get_tabs embeds.
select is(
  public.get_screen('home.root', 'en', '{}'),
  public.get_tabs('en') -> 'tabs' -> 0 -> 'screen',
  'get_screen(home.root) matches the embedded Home screen'
);
select is(
  public.get_screen('community.home', 'en', '{}'),
  public.get_tabs('en') -> 'tabs' -> 1 -> 'screen',
  'get_screen(community.home) matches the embedded Community screen'
);

-- AC7: clients cannot touch the table directly.
select throws_ok($$ select * from public.tabs $$, '42501', null, 'authenticated cannot read tabs');
select throws_ok(
  $$ update public.tabs set enabled = false $$,
  '42501', null, 'authenticated cannot write tabs'
);

reset role;

-- AC2, AC10: signed out is refused with the documented signed-in error.
select set_config('request.jwt.claims', '{"role": "anon"}', true);
set local role anon;

select throws_ok($$ select public.get_tabs('en') $$, 'P0001', 'session_ended', 'get_tabs as anon raises session_ended');
select throws_ok(
  $$ select public.get_screen('home.root', 'en', '{}') $$,
  'P0001', 'session_ended', 'get_screen(home.root) as anon raises session_ended'
);
select throws_ok(
  $$ select public.get_screen('community.home', 'en', '{}') $$,
  'P0001', 'session_ended', 'get_screen(community.home) as anon raises session_ended'
);
select lives_ok(
  $$ select public.get_screen('auth.sign_in', 'en', '{}') $$,
  'signed-out screens are still served to anon'
);
select throws_ok($$ select * from public.tabs $$, '42501', null, 'anon cannot read tabs');

reset role;

-- AC4: changing the data changes the next response, with nothing else.
update public.tabs set sort_order = 3 where id = 'home';
update public.strings set value = 'Groups' where key = 'tabs.community.title' and locale = 'en';

select set_config('request.jwt.claims', json_build_object('sub', id, 'role', 'authenticated')::text, true)
from auth.users where email = 'attendee@parkhill.test';
set local role authenticated;

select is(
  (select jsonb_agg(tab -> 'title') from jsonb_array_elements(public.get_tabs('en') -> 'tabs') tab),
  '["Groups", "Home"]'::jsonb,
  'a new order and title show in the next response'
);

reset role;

update public.tabs set enabled = false where id = 'home';
set local role authenticated;

select is(
  (select jsonb_agg(tab -> 'id') from jsonb_array_elements(public.get_tabs('en') -> 'tabs') tab),
  '["community"]'::jsonb,
  'a disabled tab is left out'
);

reset role;

-- AC6: a tab cannot point at an unregistered screen.
select throws_ok(
  $$ insert into public.tabs (id, sort_order, title_key, icon_key, screen_key)
     values ('nowhere', 10, 'tabs.home.title', 'tab.home', 'no.such.screen') $$,
  '23503', null, 'a tab referencing an unregistered screen is refused'
);

-- AC9: at most five enabled tabs. home is disabled, so four more fit.
insert into public.tabs (id, sort_order, title_key, icon_key, screen_key) values
  ('extra_1', 11, 'tabs.home.title', 'tab.home', 'home.root'),
  ('extra_2', 12, 'tabs.home.title', 'tab.home', 'home.root'),
  ('extra_3', 13, 'tabs.home.title', 'tab.home', 'home.root'),
  ('extra_4', 14, 'tabs.home.title', 'tab.home', 'home.root');

select throws_ok(
  $$ update public.tabs set enabled = true where id = 'home' $$,
  'P0001', 'too_many_tabs', 'enabling a sixth tab is refused'
);

-- get_tabs never returns more than five, even if the check were bypassed.
alter table public.tabs disable trigger check_tab_limit;
update public.tabs set enabled = true where id = 'home';
alter table public.tabs enable trigger check_tab_limit;
set local role authenticated;

select is(
  jsonb_array_length(public.get_tabs('en') -> 'tabs'),
  5,
  'get_tabs returns at most five tabs'
);

reset role;

select * from finish();
rollback;
