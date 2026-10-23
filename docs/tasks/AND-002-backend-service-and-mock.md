# AND-002: Build the Android backend service layer with production and mock implementations

| Field | Value |
|---|---|
| Area | android |
| Epic | EP-01 |
| Depends on | SUP-003, AND-001 |
| Paired with | IOS-002 |
| Status | Done |

## Intent

Android twin of IOS-002. Every backend data call goes through one abstraction, with the implementation chosen by build flavor.

## Scope

- `BackendService` interface with `getEntry(locale)` and `getScreen(key, locale, params)` (suspend functions).
- Model: `ScreenEnvelope` (`key`, `data` as `JsonObject`).
- One shared Supabase client provider, reused by auth later.
- `SupabaseBackendService` in `src/main` with the standard headers; `MockBackendService` in `src/mock` with a "current persona" input.
- `ServiceBinding.kt` in each flavor source set updated.
- Unit tests.

## Out of scope

- Auth service and sign-in (AND-005).
- UI, navigation, caching (AND-003).
- Typed decoding of individual screens' `data`.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | All backend data access goes through `BackendService`. No class outside the service layer imports the Supabase SDK or builds a request | One seam to mock, secure and extend |
| AC2 | `src/mock/.../ServiceBinding.kt` declares `typealias AppBackendService = MockBackendService`; `src/dev` declares `SupabaseBackendService`. The composition root constructs `AppBackendService` with no conditional | Build time selection, no branching |
| AC3 | Every request from `SupabaseBackendService` carries `X-App-Config`, `X-App-Platform`, `X-App-Version` and `Accept-Language`; a test asserts the header values | Backend can tell configs, platforms and versions apart in logs |
| AC4 | The Supabase client is created once and shared; requests automatically carry the session token when one exists | Signed-in calls work in AND-005 without changing this layer |
| AC5 | `MockBackendService` loads the JSON files from `/contract/mock_responses` (assets of the `mock` source set only), selecting by persona when a persona-specific mock response exists | Mocks cannot drift from the contract and can vary by persona |
| AC6 | Decoding tests parse every mock response into the models and pass; unknown fields are ignored | Android agrees with the contract and tolerates additive changes |
| AC7 | Service errors map to a small typed set: `Network`, `UnknownScreen`, `Unauthorized`, `Decoding`, `Server` | Callers react without inspecting SDK errors |
| AC8 | An integration test in the `dev` flavor calls local Supabase and receives the `auth.sign_in` entry envelope | Proves the real path end to end |

## Technical notes

- Guide 5.1, 5.2, 4.2 and `specs/AUTH.md` 5.6. Names match IOS-002.
- supabase-kt inside the Supabase classes only.
- Point the mock source set's assets and test resources at `../contract/mock_responses` in Gradle. Do not copy files.

## Verification

```
cd android
./gradlew testMockDebugUnitTest
(cd ../backend && supabase start && supabase db reset)
./gradlew connectedDevDebugAndroidTest
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] No environment branching; no mock code in release (AND-001 AC8 still holds)
- [ ] No work outside Scope

## Open questions

None.
