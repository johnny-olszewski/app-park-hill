---
type: task
id: AND-012
title: "Build the Android sheet presentation and people picker"
area: android
epic: EP-03
depends_on: [AND-027, SUP-013]
paired_with: [IOS-012]
status: Done
---

# AND-012: Build the Android sheet presentation and people picker

## Intent

Edit mode adds people by picking them from everyone signed up. This task opens `sheet` targets the platform-native way and builds `people.picker`, a reusable multi-select that returns the chosen people to whatever opened it.

## Scope

- `navigate` with `sheet`: a Material modal bottom sheet, fetched with a loading state.
- `people.picker`: one row per `PersonRow` with `title`, optional `subtitle` and `note`; rows that are not `selectable` show their note and cannot be chosen; multi-select; a search field filtering by `title` as you type.
- A `sheet` opens from a tab or from inside a full-screen cover. Replace the temporary `sheet` cases SUP-013 added.
- Add (backend `add_label`) returns every chosen person (`user_id` and `title`, so the opener can show their names) to the opener and closes the sheet; Cancel (backend `cancel_label`) and dismissing the sheet return nothing.
- `PersonRow` view as a shared component (the future directory reuses it).

## Out of scope

- Using the result in edit mode (AND-013).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | A `sheet` target opens from the bottom and can be dragged down to dismiss, on both platforms | Same sheet behavior on both platforms (guide 5.5 rule 5) |
| AC2 | Rows that are not selectable show their note and cannot be chosen | The backend decides who can be chosen |
| AC3 | Add returns every chosen user id to the opener and closes the sheet; Cancel and dragging down return nothing | A reusable select-people pattern |
| AC4 | Search filters by name as you type, keeping chosen people chosen | Fast with hundreds of people |
| AC5 | Unit tests cover AC2 to AC4 with the picker mock responses; a Mock UI test covers AC1 and AC3; the picker's main path (leader: Edit, Add, pick, Done) joins `smoke-mock.txt` and `smoke-local.txt` once IOS-013/AND-013 build it | Verified without a backend |

## Technical notes

- The sheet's result goes back through the coordinator that opened it, never through a global.
- Search is a Material 3 `SearchBar`; selection uses checkboxes in list items.
- Behavior must match IOS-012.

## Verification

```
cd android
./gradlew testMockDebugUnitTest testLocalDebugUnitTest connectedMockDebugAndroidTest
make test-local
./gradlew assembleLocalRelease && scripts/check_release_apk.sh app/build/outputs/apk/local/release/app-local-release-unsigned.apk
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include mock response and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None.
