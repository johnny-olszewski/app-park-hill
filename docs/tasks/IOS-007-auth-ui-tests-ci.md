# IOS-007: Run iOS auth UI tests: Mock in CI, Dev locally

| Field | Value |
|---|---|
| Area | ios, ci |
| Epic | EP-01 |
| Depends on | IOS-004, IOS-006 |
| Paired with | AND-007 |
| Status | Draft |

## Intent

Close the auth checkpoint on iOS with sign-in flows verified on every PR against the mock, and a single local command for the same flows against local Supabase.

## Scope

- Mock UI tests in the CI job.
- `make test-dev` in `/ios`: starts and resets local Supabase, runs the Dev UI tests.

## Out of scope

- Backend checks (SUP-007).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Mock UI tests (persona picker signs in; sign-in errors from fixtures) run on every PR | Flows verified without a backend |
| AC2 | `make test-dev` runs the Dev UI tests (sign in, wrong password message, sign out, still signed in after relaunch) against local Supabase seeded from the dataset | The real path is one command away |
| AC3 | The README and pull request template say when to run `make test-dev` (changes under the app, `/backend` or `/contract`) | No silent gap in coverage |
| AC4 | The Mock UI test job is required to merge | Checkpoint stays green |

## Technical notes

- Client CI runs Mock only (guide 6, decided 2026-10-10).

## Verification

```
cd ios
make project
xcodebuild -scheme ParkHill-Mock -destination 'platform=iOS Simulator,name=iPhone 16' test
make test-dev   # local only
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI
- [ ] No environment branching; no mock code in release builds
- [ ] Contract changes include fixtures
- [ ] No work outside Scope

## Open questions

None.
