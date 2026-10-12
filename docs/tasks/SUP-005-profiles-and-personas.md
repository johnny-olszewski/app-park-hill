# SUP-005: Add profiles, seeded personas and a signed-in check function

| Field | Value |
|---|---|
| Area | backend, contract |
| Epic | EP-01 |
| Depends on | SUP-003 |
| Paired with | None |
| Status | Draft |

## Intent

Give every account a profile, give tests and the mock the same set of people, and prove the backend can tell a signed-in caller from a signed-out one. Everything later that is user based builds on this.

## Scope

- `profiles` table (id = auth user id, display name, created at), created automatically when an account is created.
- `/contract/seed/dataset.json`: the single source for personas and all seed data (`specs/AUTH.md` 7). Nobody edits `seed.sql` or mock fixtures by hand.
- `make seed` generates `backend/supabase/seed.sql` from the dataset.
- `make fixtures` loads the seed into local Supabase, signs in as each persona (and anonymously), calls every screen function and writes `/contract/fixtures/<persona>/`.
- `make data-check` regenerates both and fails on any difference from what is committed.
- `seed.sql`: accounts for each persona with the shared local password; `disabled` is banned.
- `require_active_user()`: shared check every signed-in function calls first; raises `session_ended` when there is no valid user or the account is disabled.
- `whoami()` RPC: signed-in callers get their profile; signed-out callers are refused.
- Persona consistency check script.
- pgTAP tests.

## Out of scope

- Roles and the default attendee role (roles schema task, later).
- The `sign_in` function (SUP-006).
- Profile editing.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Creating an account (by seed or admin API) creates its `profiles` row in the same transaction | Every account always has a profile; nothing depends on the client creating one |
| AC2 | After `supabase db reset`, each persona in `dataset.json` exists with its email; `disabled` is banned | Mock, tests and humans share the same people |
| AC3 | `/backend/README.md` documents the persona emails and shared local password, and states they exist only locally | Anyone can sign in locally; no one mistakes them for real accounts |
| AC4 | `whoami()` as a signed-in persona returns that persona's profile; as `anon` it raises a distinct, documented error | Proves signed-in identity reaches backend functions |
| AC5 | A signed-in user cannot read or change another user's profile row directly (RLS) | Profiles are private by default |
| AC6 | `make data-check` fails if `seed.sql` or any fixture differs from what the dataset generates | Seed and mock data are updated in one place and cannot drift |
| AC7 | After the `attendee` account is disabled, `whoami()` called with its still-unexpired token raises `session_ended` | A disabled account loses access on its next request, not when its token expires |
| AC8 | `/backend/README.md` states that every signed-in function must call `require_active_user()` first | Future functions inherit the rule |
| AC9 | pgTAP tests cover AC1, AC2, AC4, AC5 and AC7 | Enforced, not documented |

## Technical notes

- `specs/AUTH.md` sections 7 and 8.
- Profile creation via trigger on `auth.users` insert. Display name defaults from persona data in seed; otherwise from the email local part.
- Persona accounts go in `seed.sql` only, never in migrations.
- `require_active_user()` reads the caller from the request token and checks the account's disabled state in `auth.users`.

## Verification

```
cd backend && supabase db reset && supabase test db
make data-check
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] No work outside Scope

## Open questions

None.
