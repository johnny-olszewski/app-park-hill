-- The people picker (SUP-013, specs/COMMUNITY.md 5.8): every active person by
-- display name, for adding to a group. The backend marks who cannot be
-- chosen, so clients never decide eligibility. Only display names are sent
-- (specs/ROLES.md 2, rule 3).

insert into public.strings (key, locale, value) values
  ('people.picker.title', 'en', 'Add people'),
  ('people.picker.search_placeholder', 'en', 'Search people'),
  ('people.picker.add', 'en', 'Add'),
  ('people.picker.cancel', 'en', 'Cancel'),
  ('people.picker.already_member', 'en', 'Already a member'),
  ('people.picker.unavailable', 'en', 'You can no longer add people to this group.');

-- people.picker with {"group_id"}: for holders of groups.add_member on that
-- community group; anyone else, or a missing or archived group, is refused
-- with screen_unavailable.
create function internal.screen_people_picker(p_locale text, p_params jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := internal.require_active_user();
  v_group_id uuid;
begin
  begin
    v_group_id := (p_params ->> 'group_id')::uuid;
  exception when invalid_text_representation then
    v_group_id := null;
  end;

  if v_group_id is null
    or not exists (select 1 from internal.community_groups() g where g.id = v_group_id)
    or not internal.has_permission(v_user_id, 'groups.add_member', v_group_id) then
    raise exception 'screen_unavailable'
      using detail = internal.t('people.picker.unavailable', p_locale),
            hint = 'The caller may not see this screen.';
  end if;

  return jsonb_build_object(
    'title', internal.t('people.picker.title', p_locale),
    'search_placeholder', internal.t('people.picker.search_placeholder', p_locale),
    'add_label', internal.t('people.picker.add', p_locale),
    'cancel_label', internal.t('people.picker.cancel', p_locale),
    'rows', coalesce((
      select jsonb_agg(
        jsonb_strip_nulls(jsonb_build_object(
          'user_id', p.id,
          'title', p.display_name,
          'note', case when m.user_id is not null then internal.t('people.picker.already_member', p_locale) end,
          'selectable', m.user_id is null
        ))
        order by p.display_name, p.id
      )
      from public.profiles p
      join auth.users u on u.id = p.id
      left join public.group_members m on m.group_id = v_group_id and m.user_id = p.id
      where u.deleted_at is null and (u.banned_until is null or u.banned_until <= now())
    ), '[]'::jsonb)
  );
end;
$$;

revoke all on function internal.screen_people_picker(text, jsonb) from public, anon, authenticated;

insert into public.screens (key, data_function, signed_in) values
  ('people.picker', 'screen_people_picker', true);
