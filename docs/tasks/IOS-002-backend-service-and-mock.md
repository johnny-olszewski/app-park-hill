---
type: task
id: IOS-002
title: "Build the iOS backend service layer with production and mock implementations"
area: ios
epic: EP-01
depends_on: [SUP-003, IOS-001]
paired_with: [AND-002]
status: Done
---

# IOS-002: Build the iOS backend service layer with production and mock implementations

## Intent

Put every backend data call behind one abstraction so the app runs against any Supabase backend or entirely on local mocks, chosen at build time. This is the seam that later carries the signed-in token and new environments without touching screens.

## Scope

- `BackendService` protocol with `getEntry(locale:)` and `getScreen(key:locale:params:)`.
- Model: `ScreenEnvelope` (`key`, raw JSON `data`).
- One shared Supabase client provider, built from the binding's environment values, that later tasks reuse for auth.
- `SupabaseBackendService` (production class) calling the RPC functions with the standard headers.
- `MockBackendService` returning mock responses, with a "current persona" input (unused until IOS-005).
- Binding files from IOS-001 updated to declare the service type.
- Unit tests.

## Out of scope

- Auth service and sign-in (IOS-005).
- UI, coordinators, caching (IOS-003).
- Typed decoding of individual screens' `data`; the registry does that.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | All backend data access goes through `BackendService`. No type outside the service layer imports the Supabase SDK or builds a request | One seam to mock, secure and extend |
| AC2 | The Mock binding declares `typealias AppBackendService = MockBackendService`; the Dev binding declares `SupabaseBackendService`. The composition root constructs `AppBackendService` with no conditional | Build time selection, no branching |
| AC3 | Every request from `SupabaseBackendService` carries `X-App-Config`, `X-App-Platform`, `X-App-Version` and `Accept-Language`; a test asserts the header values | Backend can tell configs, platforms and versions apart in logs |
| AC4 | The Supabase client is created once and shared; requests automatically carry the session token when one exists | Signed-in calls work in IOS-005 without changing this layer |
| AC5 | `MockBackendService` loads the JSON files from `/contract/mock_responses` (bundled in the Mock configuration only), selecting by persona when a persona-specific mock response exists | Mocks cannot drift from the contract and can vary by persona |
| AC6 | Decoding tests parse every mock response into the models and pass; unknown fields are ignored | iOS agrees with the contract and tolerates additive changes |
| AC7 | Service errors map to a small typed set: `network`, `unknownScreen`, `unauthorized`, `decoding`, `server` | Callers react without inspecting SDK errors |
| AC8 | An integration test (Dev configuration) calls local Supabase and receives the `auth.sign_in` entry envelope | Proves the real path end to end |

## Technical notes

- Guide 5.1, 5.2, 4.2 and `specs/AUTH.md` 5.6. Names match AND-002.
- supabase-swift inside the Supabase classes only.

## Verification

```
cd ios
xcodebuild -scheme ParkHill-Mock -destination 'platform=iOS Simulator,name=iPhone 16' test
(cd ../backend && supabase start && supabase db reset)
xcodebuild -scheme ParkHill-Dev -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] No environment branching; no mock code in Release (IOS-001 AC8 still holds)
- [ ] No work outside Scope

## Open questions

None.
