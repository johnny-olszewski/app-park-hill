# SUP-021: Record every sign-in refusal and update the auth spec for the mock menu

| Field | Value |
|---|---|
| Area | backend, contract |
| Epic | EP-06 |
| Depends on | SUP-006 |
| Paired with | None |
| Status | Done |

## Intent

The Mock build will let testers arm any sign-in refusal and see it on the real sign-in screen. Only the wrong-password refusal is recorded today, so the other refusals would have no real backend text to show. This task records each refusal the `sign_in` function can give, and updates the auth spec now that Mock shows the production sign-in instead of a persona picker.

## Scope

- `backend/scripts/generate_fixtures.py` records `contract/fixtures/sign_in.error.<code>.json` for `account_disabled`, `too_many_attempts` and `invalid_request`, each from a real call to the local `sign_in` function, and `sign_in.error.unknown.json`, built from the `auth.error.unknown` string in the same shape, because that refusal cannot be triggered on demand.
- `sign_in.error.json` stays as it is: the `invalid_credentials` refusal, already used by client tests.
- `specs/AUTH.md`:
  - remove `auth.sign_in.mock` (5.1 screen keys, 5.4, 6.2 screens) and describe the Mock sign-in as the production `auth.sign_in` with outcomes chosen in the mock menu
  - list the recorded refusal files in section 8
  - state in 5.3 that `secondary_actions` is reserved for backend-enabled entries (for example a future demo entry) and is never used for mock features
- Decision log entry in `ENGINEERING_GUIDE.md` section 8.

## Out of scope

- Client changes (IOS-022, AND-022).
- Changing the `sign_in` function or its messages.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | After `make fixtures`, `contract/fixtures/` holds `sign_in.error.account_disabled.json`, `sign_in.error.too_many_attempts.json` and `sign_in.error.invalid_request.json`, each with the function's real `code` and `message`, and `sign_in.error.unknown.json` with code `unknown` and the `auth.error.unknown` string for `en` | Every armed refusal in Mock shows the backend's own text |
| AC2 | `sign_in.error.json` is unchanged | Existing client tests keep working |
| AC3 | Generating the responses leaves no persona locked: signing in as every active persona with the local password succeeds right after `make fixtures` | Recording the attempt limit must not break local Dev testing |
| AC4 | Running `make fixtures` twice produces no diff | Recorded responses are reproducible |
| AC5 | `make data-check` passes | The new files are guarded like the rest |
| AC6 | `specs/AUTH.md` no longer mentions `auth.sign_in.mock`, describes the mock menu outcomes, lists the refusal files and reserves `secondary_actions` | The spec matches what clients will build |

## Technical notes

- Refusal triggers: `account_disabled` from the `disabled` persona with the local password; `invalid_request` from a body missing `password`; `too_many_attempts` from repeated failures for an email that has no account, from a client address used only for this, so no persona's count is touched.
- Use a dedicated `X-Forwarded-For` value per trigger, as `write_sign_in_fixtures` does today.
- `unknown`: read `auth.error.unknown` for `en` from the strings table (service role) and write `{ "status": "error", "code": "unknown", "message": <string> }`, the shape the function returns (`specs/AUTH.md` 5.5). It is the only refusal file not recorded from a call.
- Guide sections 4.1 and 6.

## Verification

```
cd backend
supabase start
make fixtures && make fixtures && git status --short ../contract/fixtures   # only the new files, no churn
make data-check
make test-functions
```

Then sign in as `attendee` and `admin` with the local password: both succeed.

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include fixture and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None.
