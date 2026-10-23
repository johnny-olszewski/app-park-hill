# AND-005: Build the Android auth service with production and mock implementations

| Field | Value |
|---|---|
| Area | android |
| Epic | EP-01 |
| Depends on | AND-002, SUP-006 |
| Paired with | IOS-005 |
| Status | Done |

## Intent

Android twin of IOS-005. Sign-in, session and sign-out sit behind one abstraction selected by build flavor.

## Scope

- `AuthService` interface per `specs/AUTH.md` 6.1, with a `StateFlow` of session state.
- `SupabaseAuthService` in `src/main`; `MockAuthService` in `src/mock`.
- Encrypted session storage.
- Sign-out data wipe.
- `ServiceBinding.kt` in each flavor updated to declare `AppAuthService`.
- Unit and integration tests.

## Out of scope

- Screens and coordinator wiring (AND-006).
- Other sign-in methods.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `src/mock` declares `typealias AppAuthService = MockAuthService`; `src/dev` declares `SupabaseAuthService`; no conditional in the composition root | Same build-time selection as the backend service |
| AC2 | `signIn` sends credentials only to the `sign_in` function with the standard headers; on success the session is stored in encrypted storage, not plain SharedPreferences | Backend owns sign-in; tokens are stored securely |
| AC3 | On failure, `signIn` returns the backend's `code` and `message` unchanged; on no network it returns a distinct network error | The client displays, never decides, the message |
| AC4 | `restoreSession()` returns signed in when a stored session exists, renewing it if needed, including when offline | People stay signed in, and offline launch still works |
| AC5 | When renewal is refused, the session state emits signed out with reason `SessionEnded` and local data is wiped | Fail safe: disabled or revoked accounts are returned to sign-in |
| AC6 | When any backend request is refused as unauthorized (HTTP 401 or `session_ended`), the service renews once and retries once; if either is refused, it signs out with reason `SessionEnded`. Network errors never sign out. Covered by tests | A refused request always ends in sign-in, never a stuck or half-signed-in app |
| AC7 | `signOut()` revokes the session when online and always deletes the session, the cache directory and user files, even offline | Nothing from the last user remains on a shared device |
| AC8 | After mock `signIn(persona)`, `MockBackendService` returns that persona's mock responses; no network connection is made | Mock build can show any persona's experience |
| AC9 | Integration test (dev flavor, local Supabase): sign in as `attendee`, `whoami()` succeeds; sign out, `whoami()` is refused | Proves the token reaches the backend and sign-out ends access |

## Technical notes

- `specs/AUTH.md` 4.2 to 4.4 and 6.1. Names match IOS-005.
- supabase-kt's default session storage is not encrypted; provide a custom session manager backed by encrypted storage.

## Verification

```
cd android
./gradlew testMockDebugUnitTest
(cd ../backend && supabase start && supabase db reset)
./gradlew connectedDevDebugAndroidTest
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] No environment branching; no mock code in release
- [ ] No work outside Scope

## Open questions

None.
