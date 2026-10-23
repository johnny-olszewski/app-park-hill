# IOS-017: Add the iOS directory and segmented control to Browse

| Field | Value |
|---|---|
| Area | ios |
| Epic | EP-04 |
| Depends on | IOS-025, SUP-017 |
| Paired with | AND-017 |
| Status | Draft |

## Intent

Let people browse groups, the directory, or both from one place, with the segmented control appearing only when both are available.

## Scope

- Browse shows a segmented control only when both `groups` and `directory` are present; otherwise only the present part.
- Directory view with `PersonRow` (photo when sent, "Not in directory" badge when sent), on-device search, rows open person detail.

## Out of scope

- Group browsing itself (from IOS-025).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | With both parts, a segmented control with backend titles switches instantly between them | One screen, two views |
| AC2 | With one part, no segmented control is shown | Only what the person can use |
| AC3 | Directory search filters by name as you type; rows open person detail | Find people fast |
| AC4 | Personas get the parts their fixtures give them (listed member: directory only; staff: both) | The UI follows the data |
| AC5 | Unit and Mock UI tests cover AC1 to AC4 | Verified |

## Technical notes

- Behavior must match AND-017.

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
