-- Community home and group detail for each person (SUP-012,
-- specs/COMMUNITY.md 4.1, 4.3, 5). Read-only: no row actions, no edit
-- capabilities. Every Community screen lists only community groups that are
-- not archived.

insert into public.strings (key, locale, value) values
  ('community.home.my_groups.title', 'en', 'My groups'),
  ('community.home.empty.title', 'en', 'You''re not in a community group yet.'),
  ('community.home.empty.message', 'en', 'Community Groups gather through the week to study the Bible, talk and live life together. A staff member can add you to one.'),
  ('community.group.members_title', 'en', 'Members'),
  ('community.group.leaders', 'en', 'Leaders: {names}'),
  ('community.group.leaders_none', 'en', 'Leaders: none yet'),
  ('community.group.you', 'en', 'You'),
  ('community.group.badge.leader', 'en', 'Leader'),
  ('community.group.unavailable', 'en', 'You''re no longer in this group.'),
  ('community.separator', 'en', ' · '),
  ('community.list_separator', 'en', ', '),
  -- A to_char pattern for meeting times.
  ('community.time_format', 'en', 'FMHH12:MI AM'),
  ('community.weekday.1', 'en', 'Mondays'),
  ('community.weekday.2', 'en', 'Tuesdays'),
  ('community.weekday.3', 'en', 'Wednesdays'),
  ('community.weekday.4', 'en', 'Thursdays'),
  ('community.weekday.5', 'en', 'Fridays'),
  ('community.weekday.6', 'en', 'Saturdays'),
  ('community.weekday.7', 'en', 'Sundays');

-- Community groups that are not archived.
create function internal.community_groups()
returns setof public.groups
language sql
stable
security definer
set search_path = ''
as $$
  select g.*
  from public.groups g
  join public.group_types t on t.id = g.group_type_id
  where t.key = 'community' and g.archived_at is null;
$$;

revoke all on function internal.community_groups() from public, anon, authenticated;

-- "Tuesdays · 7:00 PM": the parts that are set, joined. Meeting times are
-- local to the church time zone (internal.setting('church_time_zone')), so
-- they are shown as stored.
create function internal.meeting_line(p_day smallint, p_time time, p_locale text)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select concat_ws(
    internal.t('community.separator', p_locale),
    case when p_day is not null then internal.t('community.weekday.' || p_day, p_locale) end,
    case when p_time is not null then to_char(p_time, internal.t('community.time_format', p_locale)) end
  );
$$;

revoke all on function internal.meeting_line(smallint, time, text) from public, anon, authenticated;

-- A group's detail as p_user_id sees it (GroupDetail).
create function internal.group_detail(p_group_id uuid, p_user_id uuid, p_locale text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'group_id', g.id,
    'title', g.name,
    'description', g.description,
    'meeting', internal.meeting_line(g.meeting_day, g.meeting_time, p_locale),
    'location', g.location,
    'leaders_line', coalesce(
      (
        select replace(
          internal.t('community.group.leaders', p_locale),
          '{names}',
          string_agg(p.display_name, internal.t('community.list_separator', p_locale) order by p.display_name)
        )
        from public.group_leaders l
        join public.profiles p on p.id = l.user_id
        where l.group_id = g.id
        having count(*) > 0
      ),
      internal.t('community.group.leaders_none', p_locale)
    ),
    'members_title', internal.t('community.group.members_title', p_locale),
    'members', coalesce((
      select jsonb_agg(
        jsonb_strip_nulls(jsonb_build_object(
          'user_id', m.user_id,
          'title', p.display_name,
          'note', case when m.user_id = p_user_id then internal.t('community.group.you', p_locale) end,
          'is_leader', l.user_id is not null
        ))
        order by l.user_id is null, p.display_name, m.user_id
      )
      from public.group_members m
      join public.profiles p on p.id = m.user_id
      left join public.group_leaders l on l.group_id = m.group_id and l.user_id = m.user_id
      where m.group_id = g.id
    ), '[]'::jsonb)
  )
  from internal.community_groups() g
  where g.id = p_group_id;
$$;

revoke all on function internal.group_detail(uuid, uuid, text) from public, anon, authenticated;

-- A group in a list (GroupRow), opening its detail.
create function internal.group_row(p_group_id uuid, p_user_id uuid, p_locale text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_strip_nulls(jsonb_build_object(
    'group_id', g.id,
    'title', g.name,
    'subtitle', concat_ws(
      internal.t('community.separator', p_locale),
      nullif(internal.meeting_line(g.meeting_day, g.meeting_time, p_locale), ''),
      nullif(g.location, '')
    ),
    'badge', case when exists (
      select 1 from public.group_leaders l where l.group_id = g.id and l.user_id = p_user_id
    ) then internal.t('community.group.badge.leader', p_locale) end,
    'action', jsonb_build_object(
      'type', 'navigate',
      'screen_key', 'community.group',
      'params', jsonb_build_object('group_id', g.id),
      'presentation', 'push'
    )
  ))
  from internal.community_groups() g
  where g.id = p_group_id;
$$;

revoke all on function internal.group_row(uuid, uuid, text) from public, anon, authenticated;

-- community.home: exactly one of group (in one group), my_groups (in two or
-- more, led groups first, then the rest, each by name) or empty.
create or replace function internal.screen_community_home(p_locale text, p_params jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := internal.require_active_user();
  v_groups uuid[];
begin
  select array_agg(g.id order by l.user_id is null, g.name, g.id) into v_groups
  from internal.community_groups() g
  join public.group_members m on m.group_id = g.id and m.user_id = v_user_id
  left join public.group_leaders l on l.group_id = g.id and l.user_id = v_user_id;

  if coalesce(cardinality(v_groups), 0) = 0 then
    return jsonb_build_object('empty', jsonb_build_object(
      'title', internal.t('community.home.empty.title', p_locale),
      'message', internal.t('community.home.empty.message', p_locale)
    ));
  elsif cardinality(v_groups) = 1 then
    return jsonb_build_object('group', internal.group_detail(v_groups[1], v_user_id, p_locale));
  end if;

  return jsonb_build_object('my_groups', jsonb_build_object(
    'title', internal.t('community.home.my_groups.title', p_locale),
    'rows', (
      select jsonb_agg(internal.group_row(id, v_user_id, p_locale) order by ord)
      from unnest(v_groups) with ordinality as u(id, ord)
    )
  ));
end;
$$;

-- community.group: one group's detail, for its members (leaders are members)
-- and holders of groups.view_all. Anyone else, or a group that is missing,
-- archived or not a community group, is refused with screen_unavailable.
create function internal.screen_community_group(p_locale text, p_params jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := internal.require_active_user();
  v_group_id uuid;
  v_detail jsonb;
begin
  begin
    v_group_id := (p_params ->> 'group_id')::uuid;
  exception when invalid_text_representation then
    v_group_id := null;
  end;

  if v_group_id is not null and (
    exists (select 1 from public.group_members m where m.group_id = v_group_id and m.user_id = v_user_id)
    or internal.has_permission(v_user_id, 'groups.view_all')
  ) then
    v_detail := internal.group_detail(v_group_id, v_user_id, p_locale);
  end if;

  if v_detail is null then
    raise exception 'screen_unavailable'
      using detail = internal.t('community.group.unavailable', p_locale),
            hint = 'The caller may not see this screen.';
  end if;

  return v_detail;
end;
$$;

revoke all on function internal.screen_community_home(text, jsonb) from public, anon, authenticated;
revoke all on function internal.screen_community_group(text, jsonb) from public, anon, authenticated;

insert into public.screens (key, data_function, signed_in) values
  ('community.group', 'screen_community_group', true);
