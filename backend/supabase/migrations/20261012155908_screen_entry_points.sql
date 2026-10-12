-- Entry points returning screen envelopes: { "key": ..., "data": { ... } }.
-- Each screen's data is assembled by the internal function named in its
-- public.screens row. Adding a screen is one registry row plus one function.

-- Returns one screen envelope. Raises unknown_screen for an unregistered key.
create function public.get_screen(p_key text, p_locale text, p_params jsonb default '{}')
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_locale text := coalesce(p_locale, 'en');
  v_function text;
  v_data jsonb;
begin
  select s.data_function into v_function
  from public.screens s
  where s.key = p_key;

  if v_function is null then
    raise exception 'unknown_screen'
      using detail = coalesce(p_key, ''),
            hint = 'The screen key is not registered on this backend.';
  end if;

  execute format('select internal.%I($1, $2)', v_function)
    into v_data
    using v_locale, coalesce(p_params, '{}'::jsonb);

  return jsonb_build_object('key', p_key, 'data', v_data);
end;
$$;

-- Returns the signed-out entry screen envelope. Today always auth.sign_in.
create function public.get_entry(p_locale text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select public.get_screen('auth.sign_in', p_locale, '{}'::jsonb);
$$;

revoke all on function public.get_screen(text, text, jsonb) from public, anon, authenticated;
revoke all on function public.get_entry(text) from public, anon, authenticated;

grant execute on function public.get_screen(text, text, jsonb) to anon, authenticated;
grant execute on function public.get_entry(text) to anon;
