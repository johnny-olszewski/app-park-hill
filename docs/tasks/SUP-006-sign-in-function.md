# SUP-006: Build the sign_in Edge Function with backend-decided errors and attempt limiting

| Field | Value |
|---|---|
| Area | backend, contract |
| Epic | EP-01 |
| Depends on | SUP-005 |
| Paired with | None |
| Status | Done |

## Intent

Make sign-in a backend-owned operation: the backend decides whether it succeeded, which error applies and what the user reads, in their language. Because passwords pass through our code, it must also protect against guessing and never record a password.

## Scope

- `sign_in` Edge Function per `specs/AUTH.md` 5.5.
- `auth_attempts` table (hashed email, client address, time, outcome), not readable by clients.
- Error strings `auth.error.*` in migrations.
- Fixtures: `/contract/fixtures/sign_in.ok.json`, `sign_in.error.json`.
- Function tests.

## Out of scope

- Session renewal and sign-out (client library, IOS-005, AND-005).
- Password reset, account creation.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Correct persona credentials return HTTP 200 with `status: ok` and a session matching the fixture | A client can sign in through our backend |
| AC2 | A wrong password and an unknown email both return `invalid_credentials` with identical message and status | Does not reveal which emails have accounts |
| AC3 | The `disabled` persona returns `account_disabled` | Disabled accounts are refused with a clear message |
| AC4 | After 5 failures for one email within 15 minutes, further attempts return `too_many_attempts` without calling Supabase's auth service; the same applies at 20 failures per client address | Guessing is limited by us, not by Supabase's shared-address limits |
| AC5 | Every error message comes from `strings` for the request locale, falling back to `en`; changing a string changes the next response | Error wording is backend content, changeable without a release |
| AC6 | Malformed requests return `invalid_request`; any unexpected failure returns `unknown` with a generic message; responses always use the documented shape | Clients only ever handle one shape |
| AC7 | A test asserts no password and no plain email appears in function logs or in `auth_attempts` | Passwords are never recorded |
| AC8 | Function tests cover AC1 to AC7 and run locally with one command | Enforced, and runnable in CI (SUP-007) |

## Technical notes

- `specs/AUTH.md` 5.5. Function calls Supabase auth's password sign-in server side and returns the session fields only.
- Client address from the request's forwarded-for header. Attempt counting uses the service role inside the function.
- Thresholds live in one constants block so they can be tuned.

## Verification

```
cd backend && supabase start && supabase db reset
supabase functions serve sign_in   # in one terminal
deno test supabase/functions/sign_in   # or the documented test command
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Fixtures committed and match live output
- [ ] No work outside Scope

## Open questions

None.
