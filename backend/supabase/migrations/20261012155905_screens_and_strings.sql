-- Screen registry and localized strings. App configuration: rows are added by
-- migrations, never by seed. Clients never read these tables directly; all
-- access goes through the screen functions (guide 4.1).

-- Internal helpers live outside the API-exposed schemas.
create schema internal;
revoke all on schema internal from public, anon, authenticated;

create table public.screens (
  key text primary key
    check (key ~ '^[a-z0-9_]+(\.[a-z0-9_]+)*$'),
  data_function text not null
    check (data_function ~ '^screen_[a-z0-9_]+$')
);

comment on table public.screens is
  'Registry of screen keys returned by the backend. data_function names the internal.<fn>(p_locale text, p_params jsonb) that assembles the screen''s data.';

create table public.strings (
  key text not null,
  locale text not null,
  value text not null,
  primary key (key, locale)
);

comment on table public.strings is
  'Localized text by key and locale. Resolved per string, falling back to en.';

alter table public.screens enable row level security;
alter table public.strings enable row level security;

revoke all on public.screens, public.strings from public, anon, authenticated;

-- Resolves a string for a locale, falling back to en. A key missing in en is a
-- configuration bug and raises.
create function internal.t(p_key text, p_locale text)
returns text
language plpgsql
stable
set search_path = ''
as $$
declare
  v_value text;
begin
  select s.value into v_value
  from public.strings s
  where s.key = p_key and s.locale = p_locale;

  if v_value is null then
    select s.value into v_value
    from public.strings s
    where s.key = p_key and s.locale = 'en';
  end if;

  if v_value is null then
    raise exception 'missing_string' using detail = p_key;
  end if;

  return v_value;
end;
$$;

revoke all on function internal.t(text, text) from public, anon, authenticated;
