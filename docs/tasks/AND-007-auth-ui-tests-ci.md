---
type: task
id: AND-007
title: "Run Android auth UI tests: Mock in CI, Dev locally"
area: android, ci
epic: EP-01
depends_on: [AND-004, AND-006]
paired_with: [IOS-007]
status: Done
---

# AND-007: Run Android auth UI tests: Mock in CI, Dev locally

## Intent

Close the auth checkpoint on Android with sign-in flows verified on every PR against the mock, and a single local command for the same flows against local Supabase.

## Scope

- Mock UI tests in the CI job.
- `make test-dev` in `/android`: starts and resets local Supabase, runs the Dev UI tests.

## Out of scope

- Backend checks (SUP-007).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Mock UI tests (any credentials sign in and sign out) run on every PR; sign-in errors in Mock come with the mock menu (AND-022) | Flows verified without a backend |
| AC2 | `make test-dev` runs the Dev UI tests (sign in, wrong password message, sign out, still signed in after relaunch) against local Supabase seeded from the dataset | The real path is one command away |
| AC3 | The README and pull request template say when to run `make test-dev` (changes under the app, `/backend` or `/contract`) | No silent gap in coverage |
| AC4 | The Mock UI test job reports on the PR; a red check blocks merging by rule (guide 7.1 rule 10) | Checkpoint stays green |

## Technical notes

- Client CI runs Mock only (guide 6, decided 2026-10-10).

## Verification

```
cd android
./gradlew testMockDebugUnitTest connectedMockDebugAndroidTest
make test-dev   # local only
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI
- [ ] No environment branching; no mock code in release builds
- [ ] Contract changes include mock responses
- [ ] No work outside Scope

## Open questions

None.
