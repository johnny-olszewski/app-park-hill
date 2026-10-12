# IOS-006: Build the iOS sign-in flow, mock persona picker and signed-in placeholder

| Field | Value |
|---|---|
| Area | ios |
| Epic | EP-01 |
| Depends on | IOS-003, IOS-005 |
| Paired with | AND-006 |
| Status | Draft |

## Intent

Deliver the auth checkpoint on iOS: open the app, sign in with a seeded account or a mock persona, stay signed in across launches, and sign out. Every word on the sign-in screen and every error comes from the backend.

## Scope

- Full `auth.sign_in` screen per `specs/AUTH.md` 5.3 and 6.2.
- `auth.sign_in.mock` persona picker, mock sources only.
- `AppCoordinator` signed-in state, driven by the auth session stream.
- Temporary signed-in placeholder (email, sign-out button, bundled text) in a `Temporary` folder.
- Backend target label on the sign-in screen in non-release builds.
- UI tests.

## Out of scope

- Tabs (IOS-008 replaces the placeholder).
- Secondary actions (forgot password, create account). The screen ignores `secondary_actions` entries it does not support.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | All text on the sign-in screen comes from its screen data; changing a string in the database changes the screen after refresh | Sign-in is backend driven |
| AC2 | Email field uses the email keyboard and username autofill; password field is secure with password autofill | Native, platform-correct input |
| AC3 | A wrong password shows exactly the backend's message; no network shows `cannot_connect_message` | The backend decides errors; offline still explains itself |
| AC4 | Successful sign-in shows the placeholder with the signed-in email | Sign-in works end to end |
| AC5 | Relaunching the app while signed in goes straight to the placeholder, including with no network | People stay signed in |
| AC6 | Sign-out returns to the sign-in screen; relaunch shows sign-in; cached data is gone | Sign-out is complete |
| AC7 | Disable the signed-in persona while the app is open; the next backend request (for example on return to foreground) returns the app to sign-in showing `session_ended_message`, without waiting for the token to expire | A disabled user is signed out immediately and told why |
| AC8 | In the Mock config the entry is `auth.sign_in.mock`, listing active personas from `dataset.json`; tapping one shows the placeholder with no network | Standalone app can be signed in as anyone |
| AC9 | Non-release builds show the target backend URL on the sign-in screen | Overrides are always visible |
| AC10 | UI tests: Dev against local Supabase (sign in, wrong password message, sign out, still signed in after relaunch); Mock (persona picker signs in) | Flows are verified, not just units |

## Technical notes

- `specs/AUTH.md` 4 and 6.2. Behavior matches AND-006.
- The placeholder is not registered in the screen registry; the coordinator shows it directly in the signed-in state. It is the only client-owned screen and is deleted in IOS-008.
- UI tests use persona credentials from `/backend/README.md`, read from a test config, not hardcoded in each test.

## Verification

```
cd ios
xcodebuild -scheme ParkHill-Mock -destination 'platform=iOS Simulator,name=iPhone 16' test
(cd ../backend && supabase start && supabase db reset)
xcodebuild -scheme ParkHill-Dev -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] No environment branching; no mock code in Release
- [ ] No work outside Scope

## Open questions

None.
