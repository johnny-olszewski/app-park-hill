---
type: task
id: IOS-022
title: "Show the production sign-in in Mock with persona and result tools"
area: ios
epic: EP-06
depends_on: [IOS-021, SUP-021]
paired_with: [AND-022]
status: Done
---

# IOS-022: Show the production sign-in in Mock with persona and result tools

## Intent

Mock testers should see the production sign-in screen and still sign in without credentials, as any persona, with any result. This task stops Mock from replacing the entry screen with a persona picker, and adds the sign-in tools to the mock menu: who to sign in as and what the next sign-in returns.

## Scope

- `MockBackendService` returns the recorded `get_entry.json` (`auth.sign_in`); remove the entry substitution.
- Remove `PersonaPickerScreen`, `PersonaPickerData`, `auth.sign_in.mock` and its registration.
- A mock scenario state in `ParkHill/Mocks/` holding the chosen persona and next result.
- Sign-in tools registered for `auth.sign_in` in Mock: "Sign in as" (active personas from the bundled dataset, default first) and "Next sign-in" (Success, Wrong email or password, Account disabled, Too many attempts, Invalid request, Server error, No connection, Something went wrong; default Success).
- `MockAuthService.signIn(email:password:)` returns the armed result: Success signs in as the chosen persona; refusals return the recorded response's code and message; No connection and Something went wrong return `.network` and `.unexpected`.
- App tool "Switch persona" in Mock while signed in.
- Replace `ParkHillUITests/Mock/PersonaPickerUITests.swift` with mock sign-in UI tests.
- `ios/README.md` updated.

## Out of scope

- The overlay, pill and menu (IOS-021).
- Mock tools for other screens.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Mock launches to the production `SignInScreen` from `get_entry.json`; a search of `/ios` for `auth.sign_in.mock` and `PersonaPicker` finds nothing | Testers see what members see |
| AC2 | With Success armed, any non-empty email and password sign in as the persona chosen in the menu | Sign in without knowing credentials |
| AC3 | With each refusal armed, Sign in shows that refusal's recorded message under the password field | Every server error is visible as members would see it |
| AC4 | With No connection or Something went wrong armed, Sign in shows `cannot_connect_message` in the message box | Client-side failures match production |
| AC5 | Choices stay until changed within a launch; while a result other than Success is armed, the pill shows an alert icon and the menu shows "Next sign-in will fail: <result>" | Nobody forgets a failure is armed |
| AC6 | "Switch persona" while signed in changes the signed-in persona and the screens shown | Personas can be compared without signing out |
| AC7 | Mock UI tests cover Success as a chosen persona, one refusal and No connection, through the pill and menu | The flow stays working |
| AC8 | `ios/README.md` describes Mock sign-in through the menu and no longer mentions the persona picker | Docs match the app |

## Technical notes

- Recorded refusals: `sign_in.error.json` (`invalid_credentials`) and `sign_in.error.<code>.json` (SUP-021). Server error follows SUP-021's answer on `unknown`.
- The "disabled" persona is not listed under "Sign in as"; it is reached through Account disabled.
- The sign-in tools and scenario state live in `ParkHill/Mocks/`, registered through IOS-021's tool registry from the Mock binding.
- `SignInScreen` and `SignInViewModel` do not change.
- Guide 5.2 rule 3; `specs/AUTH.md` as updated by SUP-021. Design: EP-06 brief.

## Verification

```
cd ios
make project
grep -rn 'auth.sign_in.mock\|PersonaPicker' ParkHill ParkHillTests ParkHillUITests   # no output
xcodebuild -scheme ParkHill-Mock -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Run Mock: sign in as Admin with Success; arm each refusal and sign in; arm No connection and sign in.

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include mock response and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None.
