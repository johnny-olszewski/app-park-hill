# AND-012: Build the Android people picker and create-group form

| Field | Value |
|---|---|
| Area | android |
| Epic | EP-03 |
| Depends on | AND-009, SUP-013 |
| Paired with | IOS-012 |
| Status | Draft |

## Intent

Let leaders and staff choose people to add, and let staff create groups, with backend-owned labels, fields and selectability. The picker's rows are reused later by the directory.

## Scope

- `people.picker` sheet: `PersonRow` list, on-device search, multi-select, not-selectable rows with their note, Add returns chosen user ids to the opening screen.
- `community.group.create` form sheet from the browse toolbar: fields from the data, `save` call, field errors from the backend, success opens the new group's detail.

## Out of scope

- Adding chosen people to the group (staged in AND-013).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Not-selectable rows show their note and cannot be chosen | The backend decides who can be chosen |
| AC2 | Add returns every chosen user id to the opener and closes the sheet; Cancel returns nothing | A reusable select-people pattern |
| AC3 | Search filters by name as you type | Fast with hundreds of people |
| AC4 | Create shows the backend field errors in place; success opens the new group's detail | Staff can start a group in one flow |
| AC5 | Unit and Mock UI tests cover AC1 to AC4 | Verified |

## Technical notes

- `PersonRow` view is shared and reused by the future directory.
- Behavior must match IOS-012.

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
