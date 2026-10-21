-- Tabs for signed-in people (SUP-008): app configuration in migrations, never
-- seed. get_tabs returns them in order, each with its root screen embedded.

-- Screens a signed-out caller may not see. get_screen checks the session
-- first for these, so they are refused exactly as get_tabs is.
alter table public.screens
  add column signed_in boolean not null default false;

comment on column public.screens.signed_in is
  'When true, get_screen requires an active signed-in user (internal.require_active_user).';

create or replace function public.get_screen(p_key text, p_locale text, p_params jsonb default '{}')
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_locale text := coalesce(p_locale, 'en');
  v_function text;
  v_signed_in boolean;
  v_data jsonb;
begin
  select s.data_function, s.signed_in into v_function, v_signed_in
  from public.screens s
  where s.key = p_key;

  if v_function is null then
    raise exception 'unknown_screen'
      using detail = coalesce(p_key, ''),
            hint = 'The screen key is not registered on this backend.';
  end if;

  if v_signed_in then
    perform internal.require_active_user();
  end if;

  execute format('select internal.%I($1, $2)', v_function)
    into v_data
    using v_locale, coalesce(p_params, '{}'::jsonb);

  return jsonb_build_object('key', p_key, 'data', v_data);
end;
$$;

create table public.tabs (
  id text primary key
    check (id ~ '^[a-z0-9_]+$'),
  sort_order integer not null unique,
  title_key text not null,
  icon_key text not null,
  screen_key text not null references public.screens (key),
  enabled boolean not null default true
);

comment on table public.tabs is
  'The signed-in app''s tabs, in sort_order. At most five are enabled. title_key is a public.strings key; icon_key names a bundled client asset.';

alter table public.tabs enable row level security;
revoke all on public.tabs from public, anon, authenticated;

-- The five-tab maximum (EP-02 story 6), checked after every change.
create function internal.check_tab_limit()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (select count(*) from public.tabs where enabled) > 5 then
    raise exception 'too_many_tabs'
      using hint = 'At most five tabs can be enabled.';
  end if;
  return null;
end;
$$;

revoke all on function internal.check_tab_limit() from public, anon, authenticated;

create trigger check_tab_limit
  after insert or update on public.tabs
  for each statement execute function internal.check_tab_limit();

-- The enabled tabs in order, each with its root screen envelope:
-- { "tabs": [ { "id", "title", "icon_key", "screen": { "key", "data" } } ] }
create function public.get_tabs(p_locale text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_locale text := coalesce(p_locale, 'en');
begin
  perform internal.require_active_user();

  return jsonb_build_object('tabs', coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'id', t.id,
        'title', internal.t(t.title_key, v_locale),
        'icon_key', t.icon_key,
        'screen', public.get_screen(t.screen_key, v_locale, '{}'::jsonb)
      )
      order by t.sort_order
    )
    from (
      select * from public.tabs where enabled order by sort_order limit 5
    ) t
  ), '[]'::jsonb));
end;
$$;

revoke all on function public.get_tabs(text) from public, anon, authenticated;
-- anon may call it so a signed-out caller gets session_ended, not a grant error.
grant execute on function public.get_tabs(text) to anon, authenticated;

-- The tab root screens. Empty until their epics add content.
create function internal.screen_home_root(p_locale text, p_params jsonb)
returns jsonb
language sql
stable
set search_path = ''
as $$
  select '{}'::jsonb;
$$;

create function internal.screen_community_home(p_locale text, p_params jsonb)
returns jsonb
language sql
stable
set search_path = ''
as $$
  select '{}'::jsonb;
$$;

revoke all on function internal.screen_home_root(text, jsonb) from public, anon, authenticated;
revoke all on function internal.screen_community_home(text, jsonb) from public, anon, authenticated;

insert into public.screens (key, data_function, signed_in) values
  ('home.root', 'screen_home_root', true),
  ('community.home', 'screen_community_home', true);

insert into public.strings (key, locale, value) values
  ('tabs.home.title', 'en', 'Home'),
  ('tabs.community.title', 'en', 'Community');

insert into public.tabs (id, sort_order, title_key, icon_key, screen_key) values
  ('home', 1, 'tabs.home.title', 'tab.home', 'home.root'),
  ('community', 2, 'tabs.community.title', 'tab.community', 'community.home');
