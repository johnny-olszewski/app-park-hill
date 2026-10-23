# IOS-015: Build the iOS person detail screen and account entry

| Field | Value |
|---|---|
| Area | ios |
| Epic | EP-04 |
| Depends on | IOS-011, SUP-016 |
| Paired with | AND-015 |
| Status | Draft |

## Intent

Give every person one screen that is their own profile and how others see them, reached from the account button on every tab and from group member lists.

## Scope

- `people.person` screen: header, fields, eye states on own detail, group rows, sign-out on own detail.
- Account toolbar item handled by the generic toolbar (no special code).
- Group member rows navigate to person detail.
- Remove the temporary Home sign-out button from IOS-008: delete all code marked `TEMPORARY(EP-04)`.

## Out of scope

- Edit mode (from IOS-016).
- Edit roles (from IOS-018).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Own detail shows every field with its eye state and the directory switch only when sent | You see what you share |
| AC2 | Someone else's detail shows only the fields in the data | Privacy is backend owned |
| AC3 | Sign out on own detail confirms with the backend text and runs the existing sign-out | Sign-out has its permanent home |
| AC4 | The account button opens own detail from every tab root | Reachable everywhere |
| AC5 | Tapping a group member opens their detail; group rows open the group only when they carry an action | Navigation follows the data |
| AC6 | A search for `TEMPORARY(EP-04)` in `/ios` finds nothing, and Home has no sign-out button | The temporary code is fully removed; one sign-out entry point |
| AC7 | Unit and Mock UI tests per persona cover AC1 to AC5 | Verified |

## Technical notes

- Behavior must match AND-015.

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
