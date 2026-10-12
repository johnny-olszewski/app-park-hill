# AND-010: Build the Android Community home and Browse all groups screens

| Field | Value |
|---|---|
| Area | android |
| Epic | EP-03 |
| Depends on | AND-009, SUP-012 |
| Paired with | IOS-010 |
| Status | Draft |

## Intent

Show each person their own Community home (empty, their one group, or their groups list) and let staff browse every group, using shared views so lists look the same everywhere.

## Scope

- Shared views: group list view (`GroupRow`) and empty view.
- `community.home`: infer the state from which part is present (`group`, then `my_groups`, then `empty`); none present is unusable.
- The `group` state reuses the group detail view (built in AND-011; placeholder until then).
- `community.browse` as a full-screen cover with on-device search by title; search resets on close.
- Mock fixtures per persona.

## Out of scope

- Group detail content (from AND-011).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Each persona in Mock sees the correct home state from its fixture | State inference matches the contract |
| AC2 | A response with none of the three parts shows the cached copy, else the error screen | Unknown shapes never render blank |
| AC3 | Group rows show backend title, subtitle and badge, and tapping pushes `community.group` | Same row contract everywhere |
| AC4 | Staff and admin personas see the browse toolbar button on every home state; others do not | The UI follows what each person can do |
| AC5 | Browse filters rows by title as you type and shows the "No leader" badge where sent | Fast local search for staff |
| AC6 | Pull to refresh works on home and browse | Fresh data on demand |
| AC7 | Unit tests cover state inference; UI tests in Mock cover AC1, AC4 and AC5 | Verified |

## Technical notes

- Views are client components only; the backend knows only screens.
- Behavior must match IOS-010.

## Verification

```
cd android
./gradlew testMockDebugUnitTest connectedMockDebugAndroidTest
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI
- [ ] No environment branching; no mock code in release builds
- [ ] Contract changes include fixtures
- [ ] No work outside Scope

## Open questions

None.
