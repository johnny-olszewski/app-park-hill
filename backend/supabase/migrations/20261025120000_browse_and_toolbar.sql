-- Browse all groups and the screen toolbar (SUP-023, specs/COMMUNITY.md 3.1,
-- 4.2, 5.6). A screen may name a toolbar function; get_screen adds its items
-- to the envelope as `toolbar`, and leaves the field out when there are none,
-- so envelopes without a toolbar are unchanged.

alter table public.screens
  add column toolbar_function text
    check (toolbar_function ~ '^toolbar_[a-z0-9_]+$');

comment on column public.screens.toolbar_function is
  'Names the internal.<fn>(p_locale text, p_params jsonb) returning the screen''s toolbar items as a JSON array, built for the caller. Null: no toolbar.';

create or replace function public.get_screen(p_key text, p_locale text, p_params jsonb default '{}')
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_locale text := coalesce(p_locale, 'en');
  v_params jsonb := coalesce(p_params, '{}'::jsonb);
  v_function text;
  v_toolbar_function text;
  v_signed_in boolean;
  v_data jsonb;
  v_toolbar jsonb;
begin
  select s.data_function, s.toolbar_function, s.signed_in into v_function, v_toolbar_function, v_signed_in
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
    using v_locale, v_params;

  if v_toolbar_function is not null then
    execute format('select internal.%I($1, $2)', v_toolbar_function)
      into v_toolbar
      using v_locale, v_params;
  end if;

  if coalesce(jsonb_array_length(v_toolbar), 0) = 0 then
    return jsonb_build_object('key', p_key, 'data', v_data);
  end if;
  return jsonb_build_object('key', p_key, 'data', v_data, 'toolbar', v_toolbar);
end;
$$;

insert into public.strings (key, locale, value) values
  ('community.toolbar.browse', 'en', 'Browse all groups'),
  ('community.browse.title', 'en', 'All groups'),
  ('community.browse.search_placeholder', 'en', 'Search groups'),
  ('community.browse.unavailable', 'en', 'You can no longer browse all groups.'),
  ('community.group.badge.member', 'en', 'Member'),
  ('community.group.badge.no_leader', 'en', 'No leader');

-- Community home's toolbar: Browse all groups, for groups.view_all only.
create function internal.toolbar_community_home(p_locale text, p_params jsonb)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select case when internal.has_permission(auth.uid(), 'groups.view_all') then
    jsonb_build_array(jsonb_build_object(
      'id', 'browse_all_groups',
      'label', internal.t('community.toolbar.browse', p_locale),
      'icon_key', 'toolbar.browse',
      'action', jsonb_build_object(
        'type', 'navigate',
        'screen_key', 'community.browse',
        'params', '{}'::jsonb,
        'presentation', 'full_screen_cover'
      )
    ))
  else '[]'::jsonb end;
$$;

revoke all on function internal.toolbar_community_home(text, jsonb) from public, anon, authenticated;

update public.screens set toolbar_function = 'toolbar_community_home' where key = 'community.home';

-- A group in the browse list: like a GroupRow anywhere, but badged for the
-- whole picture: "No leader" (attention) wins, then the caller's "Leader",
-- then "Member".
create function internal.browse_row(p_group_id uuid, p_user_id uuid, p_locale text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select (internal.group_row(p_group_id, p_user_id, p_locale) - 'badge' - 'badge_tone')
    || jsonb_strip_nulls(jsonb_build_object(
      'badge', case
        when not exists (select 1 from public.group_leaders l where l.group_id = p_group_id)
          then internal.t('community.group.badge.no_leader', p_locale)
        when exists (select 1 from public.group_leaders l where l.group_id = p_group_id and l.user_id = p_user_id)
          then internal.t('community.group.badge.leader', p_locale)
        when exists (select 1 from public.group_members m where m.group_id = p_group_id and m.user_id = p_user_id)
          then internal.t('community.group.badge.member', p_locale)
      end,
      'badge_tone', case
        when not exists (select 1 from public.group_leaders l where l.group_id = p_group_id)
          then 'attention'
      end
    ));
$$;

revoke all on function internal.browse_row(uuid, uuid, text) from public, anon, authenticated;

-- community.browse: every community group by name, for groups.view_all only;
-- anyone else is refused with screen_unavailable.
create function internal.screen_community_browse(p_locale text, p_params jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := internal.require_active_user();
begin
  if not internal.has_permission(v_user_id, 'groups.view_all') then
    raise exception 'screen_unavailable'
      using detail = internal.t('community.browse.unavailable', p_locale),
            hint = 'The caller may not see this screen.';
  end if;

  return jsonb_build_object(
    'title', internal.t('community.browse.title', p_locale),
    'search_placeholder', internal.t('community.browse.search_placeholder', p_locale),
    'rows', coalesce((
      select jsonb_agg(internal.browse_row(g.id, v_user_id, p_locale) order by g.name, g.id)
      from internal.community_groups() g
    ), '[]'::jsonb)
  );
end;
$$;

revoke all on function internal.screen_community_browse(text, jsonb) from public, anon, authenticated;

insert into public.screens (key, data_function, signed_in) values
  ('community.browse', 'screen_community_browse', true);
