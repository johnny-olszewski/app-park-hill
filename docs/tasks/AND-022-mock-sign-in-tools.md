# AND-022: Show the production sign-in in Mock with persona and result tools

| Field | Value |
|---|---|
| Area | android |
| Epic | EP-06 |
| Depends on | AND-021, SUP-021 |
| Paired with | IOS-022 |
| Status | Done |

## Intent

Android twin of IOS-022. Mock testers see the production sign-in screen and sign in without credentials, as any persona, with any result, chosen in the mock menu.

## Scope

- The mock backend service already returns the recorded `get_entry.json` and Android has no persona picker (AND-006); nothing to remove.
- A mock scenario state in `src/mock` holding the chosen persona and next result.
- Sign-in tools registered for `auth.sign_in` in the mock flavor: "Sign in as" (active personas from the bundled dataset, default first) and "Next sign-in" (the same eight results as IOS-022; default Success).
- The mock auth service returns the armed result: Success signs in as the chosen persona; refusals return the recorded response's code and message; No connection and Something went wrong return the network and unexpected errors.
- App tool "Switch persona" in the mock flavor while signed in.
- Mock sign-in UI tests through the pill and menu.
- `android/README.md` updated.

## Out of scope

- The overlay, pill and menu (AND-021).
- Mock tools for other screens.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Mock launches to the production sign-in screen from `get_entry.json`; a search of `/android` for `auth.sign_in.mock` and `PersonaPicker` finds nothing | Testers see what members see |
| AC2 | With Success armed, any non-empty email and password sign in as the persona chosen in the menu | Sign in without knowing credentials |
| AC3 | With each refusal armed, Sign in shows that refusal's recorded message under the password field | Every server error is visible as members would see it |
| AC4 | With No connection or Something went wrong armed, Sign in shows `cannot_connect_message` in the message box | Client-side failures match production |
| AC5 | Choices stay until changed within a launch; while a result other than Success is armed, the pill shows an alert icon and the menu shows "Next sign-in will fail: <result>" | Nobody forgets a failure is armed |
| AC6 | "Switch persona" while signed in changes the signed-in persona and the screens shown | Personas can be compared without signing out |
| AC7 | Mock UI tests cover Success as a chosen persona, one refusal and No connection, through the pill and menu | The flow stays working |
| AC8 | `android/README.md` describes Mock sign-in through the menu | Docs match the app |

## Technical notes

- Recorded refusals: `sign_in.error.json` (`invalid_credentials`) and `sign_in.error.<code>.json` (SUP-021). Server error follows SUP-021's answer on `unknown`.
- The "disabled" persona is not listed under "Sign in as"; it is reached through Account disabled.
- The sign-in screen and its view model do not change.
- Guide 5.2 rule 3; `specs/AUTH.md` as updated by SUP-021. Design: EP-06 brief.

## Verification

```
cd android
grep -rn 'auth.sign_in.mock\|PersonaPicker' app/src   # no output
./gradlew testMockDebugUnitTest
./gradlew connectedMockDebugAndroidTest
```

Run mock: sign in as Admin with Success; arm each refusal and sign in; arm No connection and sign in.

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include fixture and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None.
