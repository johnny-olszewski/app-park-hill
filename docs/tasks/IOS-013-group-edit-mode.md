---
type: task
id: IOS-013
title: "Build iOS group edit mode with batched changes"
area: ios
epic: EP-03
depends_on: [IOS-012, SUP-024]
paired_with: [AND-013]
status: Ready
---

# IOS-013: Build iOS group edit mode with batched changes

## Intent

Leaders update their group in one pass, and staff change who leads it. This task adds edit mode to group detail: every change is staged with no confirmations, Done saves them all at once, and Cancel undoes them all.

## Scope

- The platform-standard Edit button when the data has `edit`; Done and Cancel labels from it.
- Staging in edit mode, each control only where its capability is sent: a minus button on rows with `remove`; the leader icon as a toggle on rows with `toggle_leader` (filled for leaders, greyed for others); Add member from `add_member`, opening the picker (IOS-012), whose people appear as pending rows; `edit_fields` as inline fields by `kind` (text, multiline, day picker, time picker).
- Done sends one `save` call with the staged batch added as `p_batch` (`specs/COMMUNITY.md` 5.4) and decodes its `SaveResult`: `BackendService.call` now returns the response body, which other calls keep ignoring. Cancel discards every staged change.
- In edit mode the minus only stages a removal (a row's `remove` means the caller may remove them); swipe to remove, Leave and pull to refresh are off; pending rows (people added from the picker) have no leader toggle; staged changes survive a refresh of the data underneath. In Mock a save returns the recorded ok result.
- A failed save keeps edit mode open with each `field_errors` message under its field and each `row_errors` message on its row.
- Local UI tests in `make test-local`: `leader` edits details, adds and removes members, and the changes persist after relaunch; `staff` makes someone a leader.

## Out of scope

- Delete group (EP-03.E). Swipe to remove outside edit mode (IOS-026).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Edit appears only when the data has `edit`; each control appears only where its capability is sent | The UI follows what each person can do |
| AC2 | Nothing staged inside edit mode asks for confirmation | Done is the single commit point |
| AC3 | Done sends exactly the staged changes in one save and leaves edit mode on `ok`; Cancel restores the screen as it was before Edit | All or nothing from the user's side too |
| AC4 | A failed save keeps edit mode open and shows every error at its field or row, with the staged changes kept | Problems are fixable in place |
| AC5 | Unit tests cover staging, the batch sent and Cancel; Mock UI tests cover `leader` and `staff`; Local UI tests cover the flows in Scope against local Supabase | Verified per persona and end to end |

## Technical notes

- Edit mode uses the system `EditButton` behavior and `editMode` environment, with the backend's labels; the minus button is the list's delete control (`deleteDisabled` on rows without `remove`). The system control takes two taps (minus, then its own Delete), where Android stages in one; the behavior, staging with no alert, is the same (guide 5.5 rule 1).
- Behavior must match AND-013.

## Verification

```
cd ios
make project
xcodebuild -scheme ParkHill-Mock -destination "id=$(scripts/simulator.sh)" test
make test-local
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
