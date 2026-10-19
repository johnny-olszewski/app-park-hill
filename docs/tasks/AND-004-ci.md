# AND-004: Add Android CI on GitHub Actions

| Field | Value |
|---|---|
| Area | android, ci |
| Epic | EP-01 |
| Depends on | AND-003, SUP-004 |
| Paired with | IOS-004 |
| Status | Done |

## Intent

Enforce the Android rules on every PR: Mock tests pass, the dev variant builds, the app agrees with the contract, mock code never reaches a release build and no environment branching creeps in.

## Scope

- Android workflow on a Linux runner, triggered by changes under `/android`, `/contract` or `/backend`.
- Release artifact check for mock code; source check for environment branching.

## Out of scope

- UI tests (AND-007).
- Play Store or any distribution.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `testMockDebugUnitTest` passes with no backend, including fixture decoding tests | Android stays in agreement with the contract |
| AC2 | The dev variant builds in CI; its integration tests are documented in `/android/README.md` as a local command (`make test-dev`) | CI runs Mock only; the real path is checked locally |
| AC3 | The job builds `devRelease` and fails if any class containing `Mock` is present | Mock code can never ship, enforced not trusted |
| AC4 | The job fails if `/android/app/src/main` contains `BuildConfig.FLAVOR` or `BuildConfig.DEBUG` | The no branching rule is enforced |
| AC5 | The job reports on every PR; a red check blocks merging by rule (guide 7.1 rule 10) | Android cannot regress silently |
| AC6 | The pre-push hook runs the Android source check (AC4) before a push that changes `/android` | The cheapest Android failure is caught before CI |

## Technical notes

- Emulator via reactivecircus/android-emulator-runner. No Supabase in client CI (guide 6).

## Verification

Open a PR that adds a `Mock` reference to `src/main`, and one that adds a `BuildConfig.FLAVOR` check. Each fails the job. Revert; green.

## Definition of done

- [ ] All acceptance criteria pass
- [ ] No work outside Scope

## Open questions

None.
