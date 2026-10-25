-- Browse all groups and Community home's toolbar (SUP-023 AC1 to AC4).
begin;

select plan(14);

create function pg_temp.persona(p_email text)
returns uuid
language sql
as $$ select id from auth.users where email = p_email $$;

-- Calls get_screen as an account.
create function pg_temp.screen_as(p_user uuid, p_key text, p_params jsonb default '{}')
returns jsonb
language plpgsql
as $$
declare
  v_result jsonb;
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  set local role authenticated;
  v_result := public.get_screen(p_key, 'en', p_params);
  reset role;
  return v_result;
end;
$$;

create function pg_temp.toolbar_ids(p_email text)
returns text[]
language sql
as $$
  select coalesce(array_agg(t ->> 'id'), '{}')
  from jsonb_array_elements(pg_temp.screen_as(pg_temp.persona(p_email), 'community.home') -> 'toolbar') t
$$;

create function pg_temp.browse(p_email text)
returns jsonb
language sql
as $$ select pg_temp.screen_as(pg_temp.persona(p_email), 'community.browse') -> 'data' $$;

-- AC1: envelopes without toolbar items have no toolbar field.
select ok(
  not (pg_temp.screen_as(pg_temp.persona('member.one@parkhill.test'), 'community.home') ? 'toolbar'),
  'a home with no items has no toolbar field'
);
select ok(not (public.get_screen('auth.sign_in', 'en', '{}') ? 'toolbar'), 'a screen without a toolbar function has none');

-- AC2: the browse item for groups.view_all only, on every home state.
select is(pg_temp.toolbar_ids('staff@parkhill.test'), array['browse_all_groups'], 'staff (empty home) get browse');
select is(pg_temp.toolbar_ids('admin@parkhill.test'), array['browse_all_groups'], 'admin (group home) gets browse');
select is(pg_temp.toolbar_ids('attendee@parkhill.test'), '{}'::text[], 'attendee does not');
select is(pg_temp.toolbar_ids('member.one@parkhill.test'), '{}'::text[], 'member_one does not');
select is(pg_temp.toolbar_ids('member.two@parkhill.test'), '{}'::text[], 'member_two does not');
select is(pg_temp.toolbar_ids('leader@parkhill.test'), '{}'::text[], 'leader does not');
select is(
  pg_temp.screen_as(pg_temp.persona('staff@parkhill.test'), 'community.home') -> 'toolbar' -> 0,
  '{"id": "browse_all_groups", "label": "Browse all groups", "icon_key": "toolbar.browse",
    "action": {"type": "navigate", "screen_key": "community.browse", "params": {}, "presentation": "full_screen_cover"}}'::jsonb,
  'the browse item opens community.browse as a full-screen cover'
);

-- AC3: every community group by name, own groups and leaderless groups badged.
select results_eq(
  $$ select r ->> 'title' from jsonb_array_elements(pg_temp.browse('staff@parkhill.test') -> 'rows') r $$,
  $$ select g.name from public.groups g join public.group_types t on t.id = g.group_type_id
     where t.key = 'community' and g.archived_at is null order by g.name, g.id $$,
  'staff see every community group that is not archived, by name'
);
insert into public.group_members (group_id, user_id)
select g.id, pg_temp.persona('admin@parkhill.test') from public.groups g where g.name in ('Tuesday Night Group', 'Point Loma Group');
update public.groups set archived_at = now() where name = 'Young Families';
select results_eq(
  $$ select r ->> 'title', r ->> 'badge', r ->> 'badge_tone' from jsonb_array_elements(pg_temp.browse('admin@parkhill.test') -> 'rows') r
     where r ->> 'title' in ('Mission Hills Group', 'Point Loma Group', 'Tuesday Night Group', 'Young Families', 'Normal Heights Group') $$,
  $$ values ('Mission Hills Group', 'Leader', null::text), ('Normal Heights Group', null, null),
            ('Point Loma Group', 'No leader', 'attention'), ('Tuesday Night Group', 'Member', null::text) $$,
  'own groups badged Leader or Member, No leader wins with attention, archived groups left out'
);

-- AC4: refused without groups.view_all.
select throws_ok(
  $$ select pg_temp.screen_as(pg_temp.persona('leader@parkhill.test'), 'community.browse') $$,
  'P0001', 'screen_unavailable', 'a leader cannot browse all groups'
);
select throws_ok(
  $$ select pg_temp.screen_as(pg_temp.persona('attendee@parkhill.test'), 'community.browse') $$,
  'P0001', 'screen_unavailable', 'an attendee cannot browse all groups'
);
select set_config('request.jwt.claims', '{"role": "anon"}', true);
select throws_ok(
  $$ select public.get_screen('community.browse', 'en', '{}') $$,
  'P0001', 'session_ended', 'signed out is refused'
);

select * from finish();
rollback;
