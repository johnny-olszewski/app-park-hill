---
type: task
id: AND-025
title: "Decode every backend response with the generated types in the Android app"
area: android
epic: EP-05
depends_on: [SUP-022, AND-024]
paired_with: [IOS-024]
status: Done
---

# AND-025: Decode every backend response with the generated types in the Android app

## Intent

After SUP-022, the screen envelope, `get_tabs`, `whoami` and the `sign_in` responses have generated Kotlin types. This task makes the app use them and deletes its hand-written copies, so no response shape is written by hand in the app.

## Scope

- Use the generated `ScreenEnvelope`, `TabsResponse`, `TabItem`, `Profile`, `SignInSuccess`, `SignInSession` and `SignInFailure` from `contract/generated/` (package `app.parkhill.contract`).
- Delete the hand-written ones in `android/app/src/main/java/app/parkhill/services/backend/ScreenEnvelope.kt` (keeping `ContractJson`), `Tabs.kt`, `Profile.kt` and `services/auth/SignInResponse.kt`; `SignInRequest` stays (request bodies are not described).
- Code that used `SignInSuccess.Session` uses `SignInSession`.

## Out of scope

- Request bodies and PostgREST error bodies.
- Any behavior or appearance change.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | A search of `android/` finds no definition of the seven types in Scope; each is defined only in `contract/generated/` | One definition per response shape |
| AC2 | Cached envelopes and tabs written by the previous build still load after updating (same encoding), or are discarded and refetched without an error screen | Updating the app never shows an error for an old cache |
| AC3 | Decoding tests decode every file in `contract/mock_responses` with its type from `contract/responses.json` | The app decodes exactly what the backend records |
| AC4 | In Mock and Dev, sign-in (success and each refusal), tabs, return to foreground and sign-out work as before | No behavior change |

## Technical notes

- Decode with `ContractJson` (`ignoreUnknownKeys`), as today.
- Behavior must match IOS-024.

## Verification

```
cd android
./gradlew testMockDebugUnitTest testDevDebugUnitTest connectedMockDebugAndroidTest
make test-dev
./gradlew assembleDevRelease && scripts/check_release_apk.sh app/build/outputs/apk/local/release/app-dev-release-unsigned.apk
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include mock response and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None.
