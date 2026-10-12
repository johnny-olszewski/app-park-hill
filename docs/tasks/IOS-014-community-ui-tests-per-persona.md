# IOS-014: Add iOS Community UI tests per persona against local Supabase (local)

| Field | Value |
|---|---|
| Area | ios |
| Epic | EP-03 |
| Depends on | IOS-013, SUP-014 |
| Paired with | AND-014 |
| Status | Draft |

## Intent

Prove each persona gets the right Community experience end to end on the real backend, including refusals for stale actions.

## Scope

- UI smoke test per persona in Dev against local Supabase (seeded data).
- A stale-action test: an action is revoked server side, then tapped, and is refused with the backend message.

## Out of scope

- Exhaustive permission coverage (backend tests own that).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Each persona signs in and sees the Community home state and actions the spec gives it | End-to-end check per role |
| AC2 | A leader adds and removes members in edit mode and the changes persist after relaunch | The main leader flow works for real |
| AC3 | A revoked action is refused with the backend message and the screen refreshes | Stale UI can never do what the user may not |
| AC4 | Tests reset the database to the seed before running | Deterministic results |

## Technical notes

- Persona credentials come from the test config, not hardcoded.
- Runs locally with `make test-dev`; CI runs Mock tests only (guide 6).

## Verification

```
cd ios
xcodebuild -scheme ParkHill-Dev -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally with `make test-dev`
- [ ] No environment branching; no mock code in release builds
- [ ] Contract changes include fixtures
- [ ] No work outside Scope

## Open questions

None.
