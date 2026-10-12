-- Screen auth.sign_in (specs/AUTH.md 5.3) and its English strings.

create function internal.screen_auth_sign_in(p_locale text, p_params jsonb)
returns jsonb
language sql
stable
set search_path = ''
as $$
  select jsonb_build_object(
    'title', internal.t('auth.sign_in.title', p_locale),
    'email_label', internal.t('auth.sign_in.email_label', p_locale),
    'password_label', internal.t('auth.sign_in.password_label', p_locale),
    'submit_label', internal.t('auth.sign_in.submit_label', p_locale),
    'cannot_connect_message', internal.t('auth.sign_in.cannot_connect_message', p_locale),
    'session_ended_message', internal.t('auth.sign_in.session_ended_message', p_locale),
    'secondary_actions', '[]'::jsonb
  );
$$;

revoke all on function internal.screen_auth_sign_in(text, jsonb) from public, anon, authenticated;

insert into public.screens (key, data_function) values
  ('auth.sign_in', 'screen_auth_sign_in');

insert into public.strings (key, locale, value) values
  ('auth.sign_in.title', 'en', 'Sign in'),
  ('auth.sign_in.email_label', 'en', 'Email'),
  ('auth.sign_in.password_label', 'en', 'Password'),
  ('auth.sign_in.submit_label', 'en', 'Sign in'),
  ('auth.sign_in.cannot_connect_message', 'en', 'Can''t connect. Check your connection and try again.'),
  ('auth.sign_in.session_ended_message', 'en', 'You''ve been signed out. Please sign in again.');
