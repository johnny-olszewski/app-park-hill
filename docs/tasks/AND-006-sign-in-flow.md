# AND-006: Build the Android sign-in flow, mock persona picker and signed-in placeholder

| Field | Value |
|---|---|
| Area | android |
| Epic | EP-01 |
| Depends on | AND-003, AND-005 |
| Paired with | IOS-006 |
| Status | Draft |

## Intent

Android twin of IOS-006. Sign in with a seeded account or a mock persona, stay signed in, sign out, with all sign-in text and errors from the backend.

## Scope

- Full `auth.sign_in` screen per `specs/AUTH.md` 5.3 and 6.2.
- `auth.sign_in.mock` persona picker in `src/mock`.
- `AppCoordinator` signed-in state driven by the auth session state.
- Temporary signed-in placeholder in a `temporary` package.
- Backend target label on the sign-in screen in non-release builds.
- UI tests.

## Out of scope

- Tabs (AND-008 replaces the placeholder).
- Secondary actions.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | All text on the sign-in screen comes from its screen data; changing a string in the database changes the screen after refresh | Sign-in is backend driven |
| AC2 | Email field uses the email keyboard and autofill hints; password field is masked with password autofill | Native, platform-correct input |
| AC3 | A wrong password shows exactly the backend's message; no network shows `cannot_connect_message` | The backend decides errors; offline still explains itself |
| AC4 | Successful sign-in shows the placeholder with the signed-in email | Sign-in works end to end |
| AC5 | Relaunching while signed in goes straight to the placeholder, including with no network | People stay signed in |
| AC6 | Sign-out returns to sign-in; relaunch shows sign-in; cached data is gone | Sign-out is complete |
| AC7 | Disable the signed-in persona while the app is open; the next backend request (for example on return to foreground) returns the app to sign-in showing `session_ended_message`, without waiting for the token to expire | A disabled user is signed out immediately and told why |
| AC8 | In `mockDebug` the entry is `auth.sign_in.mock`, listing active personas; tapping one shows the placeholder with no network | Standalone app can be signed in as anyone |
| AC9 | Non-release builds show the target backend URL on the sign-in screen | Overrides are always visible |
| AC10 | UI tests: dev against local Supabase (sign in, wrong password message, sign out, still signed in after relaunch); mock (persona picker signs in) | Flows are verified, not just units |

## Technical notes

- `specs/AUTH.md` 4 and 6.2. Behavior matches IOS-006.
- The placeholder is shown directly by the coordinator, not through the registry, and is deleted in AND-008.

## Verification

```
cd android
./gradlew testMockDebugUnitTest connectedMockDebugAndroidTest
(cd ../backend && supabase start && supabase db reset)
./gradlew connectedDevDebugAndroidTest
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] No environment branching; no mock code in release
- [ ] No work outside Scope

## Open questions

None.
