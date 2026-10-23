---
type: task
id: IOS-005
title: "Build the iOS auth service with production and mock implementations"
area: ios
epic: EP-01
depends_on: [IOS-002, SUP-006]
paired_with: [AND-005]
status: Done
---

# IOS-005: Build the iOS auth service with production and mock implementations

## Intent

Put sign-in, session and sign-out behind one abstraction, selected at build time like the backend service. The production class uses our `sign_in` function and keeps people signed in safely; the mock class signs in as a persona with no network.

## Scope

- `AuthService` protocol per `specs/AUTH.md` 6.1: `restoreSession()`, `signIn(email:password:)`, `signIn(persona:)` on the mock only, `signOut()`, session state stream.
- `SupabaseAuthService`: calls `sign_in`, hands the session to the shared Supabase client, observes renewal.
- `MockAuthService`: sets the current persona shared with `MockBackendService`.
- Sign-out data wipe: session, cache directory, user files.
- Bindings updated to declare `AppAuthService`.
- Unit and integration tests.

## Out of scope

- Screens and coordinator wiring (IOS-006).
- Other sign-in methods.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | The Mock binding declares `typealias AppAuthService = MockAuthService`; Dev declares `SupabaseAuthService`; no conditional in the composition root | Same build-time selection as the backend service |
| AC2 | `signIn` sends credentials only to the `sign_in` function with the standard headers; on success the session is stored by the Supabase client in the Keychain | Backend owns sign-in; tokens are stored securely |
| AC3 | On failure, `signIn` returns the backend's `code` and `message` unchanged; on no network it returns a distinct network error | The client displays, never decides, the message |
| AC4 | `restoreSession()` returns signed in when a stored session exists, renewing it if needed, including when offline | People stay signed in, and offline launch still works |
| AC5 | When renewal is refused, the session state stream emits signed out with reason `sessionEnded` and local data is wiped | Fail safe: disabled or revoked accounts are returned to sign-in |
| AC6 | When any backend request is refused as unauthorized (HTTP 401 or `session_ended`), the service renews once and retries once; if either is refused, it signs out with reason `sessionEnded`. Network errors never sign out. Covered by tests | A refused request always ends in sign-in, never a stuck or half-signed-in app |
| AC7 | `signOut()` revokes the session when online and always deletes the session, the cache directory and user files, even offline | Nothing from the last user remains on a shared device |
| AC8 | After mock `signIn(persona:)`, `MockBackendService` returns that persona's mock responses; no network connection is made | Mock build can show any persona's experience |
| AC9 | Integration test (Dev, local Supabase): sign in as `attendee`, `whoami()` succeeds; sign out, `whoami()` is refused | Proves the token reaches the backend and sign-out ends access |

## Technical notes

- `specs/AUTH.md` 4.2 to 4.4 and 6.1. Names match AND-005.
- The shared Supabase client from IOS-002 is used for both services so the token is attached automatically.
- `MockAuthService` and persona logic live in mock-only sources.

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
