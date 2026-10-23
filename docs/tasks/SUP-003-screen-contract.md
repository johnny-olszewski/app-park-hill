# SUP-003: Define the screen contract and implement get_entry and get_screen

| Field | Value |
|---|---|
| Area | backend, contract |
| Epic | EP-01 |
| Depends on | SUP-002 |
| Paired with | None |
| Status | Done |

## Intent

Make the backend the source of what a signed-out user sees first, and establish the screen envelope every screen will use. After this task, the sign-in screen's wording is a data change, not a release, and both clients have mock responses to build against.

## Scope

- Tables: `screens` (registry of screen keys), `strings` (key, locale, value).
- Functions `get_entry(p_locale)` and `get_screen(p_key, p_locale, p_params)` per guide 4.1.
- Migration data (not seed): screen `auth.sign_in` and its English strings per `specs/AUTH.md` 5.3.
- `/contract/README.md` with the envelope, entry points, contract rules and screen key naming rule.
- `/contract/mock_responses/get_entry.json`, `get_screen.auth.sign_in.json`.
- pgTAP tests.

## Out of scope

- Sign-in itself, profiles, personas (SUP-005, SUP-006).
- `get_tabs` (SUP-008).
- Client code.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `get_entry('en')` called as `anon` returns `{key: "auth.sign_in", data: {...}}` matching `get_entry.json` | One call tells a signed-out client what to show |
| AC2 | All text in `data` is resolved for the locale. An unseeded locale (for example `es`) returns English | Strings are backend content |
| AC3 | Changing a string in the `strings` table changes the next response with no other change | Proves the screen is remotely driven |
| AC4 | `get_screen('auth.sign_in', locale, '{}')` returns the same envelope `get_entry` returns | One parser per screen regardless of source |
| AC5 | `get_screen` with an unregistered key raises a distinct, documented error | Clients can tell "unknown screen" from "network failed" |
| AC6 | `anon` can execute both functions and cannot read or write the underlying tables directly (RLS enabled, no policies for `anon`) | All access goes through functions, where user logic will live |
| AC7 | `screens` and `strings` rows are created by migrations; `supabase db reset` with an empty `seed.sql` still returns AC1 | Configuration reaches hosted projects, not just local |
| AC8 | pgTAP tests cover AC1 to AC7 and pass via `supabase test db` | The contract is enforced, not just documented |

## Technical notes

- Guide 4.1 and `specs/AUTH.md` 5.1 to 5.3 are the spec. Contract rules go into `/contract/README.md` verbatim.
- Assemble each screen's data in one internal function per screen key (for example `screen_auth_sign_in(p_locale, p_params)`) dispatched from `get_screen` and reused by `get_entry`. Adding a screen is a registry row plus one function.
- Functions are `security definer` with a fixed `search_path`.

## Verification

```
cd backend && supabase db reset && supabase test db
curl -s -X POST http://127.0.0.1:54321/rest/v1/rpc/get_entry \
  -H "apikey: <local anon key>" -H "Content-Type: application/json" \
  -d '{"p_locale":"en"}'
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Mock responses committed and match live output
- [ ] No work outside Scope

## Open questions

None.
