# IOS-004: Add iOS CI on GitHub Actions

| Field | Value |
|---|---|
| Area | ios, ci |
| Epic | EP-01 |
| Depends on | IOS-003, SUP-004 |
| Paired with | AND-004 |
| Status | Done |

## Intent

Enforce the iOS rules on every PR: tests pass, the app agrees with the mock responses, mock code never reaches a release build and no environment branching creeps in.

## Scope

- iOS workflow on a macOS runner, triggered by changes under `/ios`, `/contract` or `/backend` on ready (not draft) PRs.
- The iOS source checks in the pre-push hook.
- Release artifact check for mock code; source check for environment branching.

## Out of scope

- Tests against local Supabase. Client CI runs Mock only (guide 6); Dev tests run locally with `make test-dev`.
- UI tests (IOS-007).
- TestFlight or any distribution.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Mock scheme unit tests pass with no backend, including mock response decoding tests | iOS stays in agreement with the contract |
| AC2 | The job builds the Dev release artifact and fails if its build log shows any source under `ParkHill/Mocks/` or `ParkHill/DevTools/` compiled, or if any symbol containing `Mock`, or any dev tools symbol other than `NoDevTools`, is present | Mock and debug code can never ship, enforced not trusted |
| AC3 | The job fails if Swift source in `/ios` contains `#if` on a build configuration | The no branching rule is enforced |
| AC4 | The job reports on every ready PR; a red check blocks merging by rule (guide 7.1 rule 10) | iOS cannot regress silently |
| AC6 | The pre-push hook runs the iOS source checks (AC3) before a push that changes `/ios` | The cheapest iOS failure is caught before CI |
| AC5 | `/ios/README.md` lists the Dev integration test command to run locally before merging, since CI runs Mock only | No silent gap in coverage |

## Technical notes

- Guide 5.2 and 6.
- Run `make project` (pinned XcodeGen) before building.

## Verification

Open a PR that adds a `Mock` reference to app sources, and one that adds `#if DEBUG`. Each fails the job. Revert; green.

## Definition of done

- [ ] All acceptance criteria pass
- [ ] No work outside Scope

## Open questions

None.
