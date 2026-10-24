---
type: task
id: AND-024
title: "Decode screens with the generated models in the Android app"
area: android
epic: EP-05
depends_on: [SUP-020]
paired_with: [IOS-023]
status: Done
---

# AND-024: Decode screens with the generated models in the Android app

## Intent

SUP-020 generates each screen's Kotlin model from its description in `contract/screens/`. The app already compiles them (it compiles all of `contract/generated/`) but still decodes with its own hand-written copies. This task switches the app to the generated models and deletes the hand-written ones, so a screen's fields are written once and every later screen (from EP-03) needs no model code in the app.

## Scope

- Delete the hand-written `SignInScreenData`, `HomeRootData` and `CommunityHomeData` from `android/app/src/main/java/app/parkhill/screens/`; the screen registry and screens use the generated types in `app.parkhill.contract`.
- `secondary_actions` becomes required, as on iOS: the generated model has no `= emptyList()` default.
- Update the `sourceSets` comment in `android/app/build.gradle.kts`: `contract/generated` now holds the screen models as well as the names.
- Decoding tests read `contract/mock_responses` and decode with the generated types through `ContractJson`.

## Out of scope

- Responses that are not screen data (`whoami`, `sign_in`, `get_tabs`, the envelope): EP-05.D (AND-025).
- Any change to screen behavior or appearance.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `SignInScreenData`, `HomeRootData` and `CommunityHomeData` are each defined only in `contract/generated/`; a search of `android/` finds no definition of them | One definition per screen model |
| AC2 | Every variant (mockDebug, devDebug, devRelease) builds with the generated models, and a new `.kt` file that `make models` adds to `contract/generated/` is compiled with no Gradle change | A new screen's model needs no client project change |
| AC3 | Removing `title` from `contract/screens/auth.sign_in.schema.json` and running `make models` breaks the Android build at the screen that reads it (then reverted) | The app follows the description, so drift fails the build |
| AC4 | Decoding tests decode every recorded screen in `contract/mock_responses` with its generated type | Generated models match the backend's recorded output |
| AC5 | In Mock and Dev, sign-in (success and each refusal), tabs and sign-out work as before | No behavior change |

## Technical notes

- Decode screen data with `ContractJson` (`ignoreUnknownKeys`), as today; generated classes do not configure this themselves (`contract/README.md`, Screen data).
- Behavior must match IOS-023.

## Verification

```
cd android
./gradlew testMockDebugUnitTest testDevDebugUnitTest connectedMockDebugAndroidTest
make test-dev
./gradlew assembleDevRelease && scripts/check_release_apk.sh app/build/outputs/apk/local/release/app-dev-release-unsigned.apk
grep -rn "class SignInScreenData\|class HomeRootData\|class CommunityHomeData" app/src   # no output
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
