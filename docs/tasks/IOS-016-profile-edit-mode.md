---
type: task
id: IOS-016
title: "Build iOS profile edit mode with photo upload"
area: ios
epic: EP-04
depends_on: [IOS-015, SUP-018]
paired_with: [AND-016]
status: Draft
---

# IOS-016: Build iOS profile edit mode with photo upload

## Intent

Let people change their name, phone, photo and what they share in one batched pass, reusing the group edit-mode pattern.

## Scope

- Edit, Done, Cancel on own detail; staging for name, phone, photo, eye toggles, directory switch.
- Photo from `PhotosPicker` and the camera: square crop, max 1024 px, JPEG, upload on Done before the batch save; remove photo.
- One `save` on Done; all or nothing; errors in place; Cancel discards everything.

## Out of scope

- Other people's details.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Every staged change is visible before Done and Cancel restores the screen as it was | Same model as group edit mode |
| AC2 | A chosen photo is cropped, resized and uploaded only on Done, then referenced in the save | No stray uploads for cancelled edits |
| AC3 | A failed save keeps edit mode open with field errors | Fixable in place |
| AC4 | The directory switch is absent for always-listed personas | Staff cannot unlist themselves |
| AC5 | Unit tests for staging and image processing; Mock UI tests for a member and a staff persona | Verified |

## Technical notes

- Behavior must match AND-016.

## Verification

```
cd ios
xcodebuild -scheme ParkHill-Mock -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI
- [ ] No environment branching; no mock code in release builds
- [ ] Contract changes include mock responses
- [ ] No work outside Scope

## Open questions

None.
