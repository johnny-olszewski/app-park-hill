# IOS-013: Build iOS group edit mode with batched changes

| Field | Value |
|---|---|
| Area | ios |
| Epic | EP-03 |
| Depends on | IOS-011, IOS-012, SUP-014 |
| Paired with | AND-013 |
| Status | Draft |

## Intent

Let leaders and staff change a group in one deliberate pass: everything is staged on screen, Done saves it all or nothing, and Cancel undoes it all.

## Scope

- Edit button (platform standard) when the data has any edit capability; Done and Cancel labels from data.
- Staging: minus (remove), leader toggle (filled or greyed), pending rows from the picker, inline detail fields (text, multiline, day, time).
- Done sends one `save` with every staged change; Cancel discards all.
- Errors shown in place under fields and on rows; edit mode stays open on failure.
- Delete group footer button for staff in edit mode (immediate `call` with confirmation, `dismiss`).

## Out of scope

- Swipe to remove outside edit mode (from IOS-011).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Edit appears only when the data has an edit capability; each control appears only where its capability is present | The UI follows what each person can do |
| AC2 | No confirmation is shown for anything staged inside edit mode | Done is the single commit point |
| AC3 | Done sends exactly the staged changes in one save; Cancel restores the screen as it was | All or nothing from the user's side too |
| AC4 | A failed save keeps edit mode open with every error shown at its field or row | Problems are fixable in place |
| AC5 | Delete group confirms, archives and applies the lost-access rule | Safe delete for staff |
| AC6 | Unit tests cover staging and Cancel; Mock UI tests cover a leader and a staff persona | Verified |

## Technical notes

- Behavior must match AND-013.

## Verification

```
cd ios
xcodebuild -scheme ParkHill-Mock -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI
- [ ] No environment branching; no mock code in release builds
- [ ] Contract changes include fixtures
- [ ] No work outside Scope

## Open questions

None.
