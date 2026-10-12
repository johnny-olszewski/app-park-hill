# AND-011: Build the Android group detail view and screen

| Field | Value |
|---|---|
| Area | android |
| Epic | EP-03 |
| Depends on | AND-010, SUP-012, SUP-014 |
| Paired with | IOS-011 |
| Status | Draft |

## Intent

Show a group's details and members the same way whether it is someone's only group on Community home or a group opened from a list, with Leave and swipe-to-remove driven by what the person may do.

## Scope

- Group detail view: details section with leaders line, member list with leader icon and "You", footer Leave button.
- `community.group` screen and the `group` state of `community.home` both use it.
- Swipe to remove (Compose swipe-to-dismiss) on rows with a `remove` action, with the backend confirmation.
- Leave via its `call` action (`dismiss` on success).

## Out of scope

- Edit mode (from AND-013).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Details, leaders line and member rows render from `GroupDetail` exactly as sent | One view, one contract |
| AC2 | The same view is used on Community home and on a pushed group screen | Consistency and reuse |
| AC3 | Swipe to remove appears only on rows with `remove`; confirming removes the member and refreshes | Remove outside edit mode, with a confirmation |
| AC4 | Leave appears only when sent; confirming leaves and applies the lost-access rule (pushed: back to home refreshed; root: home refreshes to its new state) | Leaving always lands somewhere valid |
| AC5 | Member, leader and staff personas see only their allowed actions in Mock | The UI follows what each person can do |
| AC6 | Unit and Mock UI tests cover AC1 to AC5 | Verified |

## Technical notes

- Behavior must match IOS-011.

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
