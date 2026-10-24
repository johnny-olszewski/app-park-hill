---
type: task
id: AND-006
title: "Build the Android sign-in flow and signed-in placeholder"
area: android
epic: EP-01
depends_on: [AND-003, AND-005]
paired_with: [IOS-006]
status: Done
---

# AND-006: Build the Android sign-in flow and signed-in placeholder

## Intent

Android twin of IOS-006, as iOS stands after EP-06: Mock shows the production sign-in, with no persona picker. Sign in with a seeded account (Dev) or any credentials (Mock), stay signed in, sign out, with all sign-in text and errors from the backend.

## Scope

- Full `auth.sign_in` screen per `specs/AUTH.md` 5.3 and 6.2.
- Mock entry is the recorded `get_entry.json` (`auth.sign_in`); the mock auth service signs in as the first active persona for any credentials. Choosing the persona and result comes with AND-022.
- `AppCoordinator` signed-in state driven by the auth session state.
- Temporary signed-in placeholder in a `temporary` package.
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
| AC8 | In `mockDebug` the entry is the production sign-in screen; any non-empty credentials show the placeholder signed in as the first active persona, with no network | The standalone app shows what members see and can be signed in |
| AC9 | UI tests: dev against local Supabase (sign in, wrong password message, sign out, still signed in after relaunch); mock (any credentials sign in) | Flows are verified, not just units |

## Technical notes

- `specs/AUTH.md` 4, 5.4 and 6.2. Behavior matches IOS-006 and IOS-022's Mock sign-in with Success armed.
- The backend target is shown by the dev tools pill (AND-021), not by the sign-in screen.
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
