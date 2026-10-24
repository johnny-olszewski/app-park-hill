---
type: task
id: AND-018
title: "Build the Android Edit roles half sheet"
area: android
epic: EP-04
depends_on: [AND-015, SUP-018]
paired_with: [IOS-018]
status: Draft
---

# AND-018: Build the Android Edit roles half sheet

## Intent

Let admins make someone staff or admin, or remove those roles, from that person's detail.

## Scope

- Edit roles toolbar button opens a partially expanded `ModalBottomSheet` with backend role toggles and descriptions.
- Save sends one `save_roles`; Cancel discards; backend errors (for example last admin) shown in the sheet.

## Out of scope

- Showing derived or automatic roles.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | The sheet lists exactly the roles in the data with their current state | Only assignable roles |
| AC2 | Save applies all toggles together; Cancel discards | Same commit model as edit modes |
| AC3 | A refused save keeps the sheet open with the backend message | The last admin cannot be removed |
| AC4 | Unit and Mock UI tests for the admin persona cover AC1 to AC3 | Verified |

## Technical notes

- Behavior must match IOS-018.

## Verification

```
cd android
./gradlew testMockDebugUnitTest connectedMockDebugAndroidTest
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI
- [ ] No environment branching; no mock code in release builds
- [ ] Contract changes include mock responses
- [ ] No work outside Scope

## Open questions

None.
