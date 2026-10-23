# AND-013: Build Android group edit mode with batched changes

| Field | Value |
|---|---|
| Area | android |
| Epic | EP-03 |
| Depends on | AND-012, SUP-024 |
| Paired with | IOS-013 |
| Status | Draft |

## Intent

Leaders update their group in one pass, and staff change who leads it. This task adds edit mode to group detail: every change is staged with no confirmations, Done saves them all at once, and Cancel undoes them all.

## Scope

- The platform-standard Edit button when the data has `edit`; Done and Cancel labels from it.
- Staging in edit mode, each control only where its capability is sent: a minus button on rows with `remove`; the leader icon as a toggle on rows with `toggle_leader` (filled for leaders, greyed for others); Add member from `add_member`, opening the picker (AND-012), whose people appear as pending rows; `edit_fields` as inline fields by `kind` (text, multiline, day picker, time picker).
- Done sends one `save` call with the staged batch (`specs/COMMUNITY.md` 5.4); Cancel discards every staged change.
- A failed save keeps edit mode open with each `field_errors` message under its field and each `row_errors` message on its row.
- Dev UI tests in `make test-dev`: `leader` edits details, adds and removes members, and the changes persist after relaunch; `staff` makes someone a leader.

## Out of scope

- Delete group (EP-03.E). Swipe to remove outside edit mode (AND-027).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Edit appears only when the data has `edit`; each control appears only where its capability is sent | The UI follows what each person can do |
| AC2 | Nothing staged inside edit mode asks for confirmation | Done is the single commit point |
| AC3 | Done sends exactly the staged changes in one save and leaves edit mode on `ok`; Cancel restores the screen as it was before Edit | All or nothing from the user's side too |
| AC4 | A failed save keeps edit mode open and shows every error at its field or row, with the staged changes kept | Problems are fixable in place |
| AC5 | Unit tests cover staging, the batch sent and Cancel; Mock UI tests cover `leader` and `staff`; Dev UI tests cover the flows in Scope against local Supabase | Verified per persona and end to end |

## Technical notes

- Edit is a top app bar action switching the screen into edit mode; Done and Cancel replace it, Cancel on the navigation icon.
- Behavior must match IOS-013.

## Verification

```
cd android
./gradlew testMockDebugUnitTest testDevDebugUnitTest connectedMockDebugAndroidTest
make test-dev
./gradlew assembleDevRelease && scripts/check_release_apk.sh app/build/outputs/apk/dev/release/app-dev-release-unsigned.apk
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include fixture and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None.
