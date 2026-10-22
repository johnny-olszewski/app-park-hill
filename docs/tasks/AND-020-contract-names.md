# AND-020: Use the generated contract names in the Android app

| Field | Value |
|---|---|
| Area | android |
| Epic | EP-05 |
| Depends on | SUP-019, AND-008 |
| Paired with | IOS-020 |
| Status | Done |

## Intent

Android twin of IOS-020. Replace the hand-typed backend function names and screen keys with the constants SUP-019 generates from `contract/names.json`, so a misspelled name is a compile error and the Mock and Supabase services cannot disagree on a name.

## Scope

- Compile `contract/generated/ContractNames.kt` into the app in every flavor and build type.
- Use `RpcFunction`, `EdgeFunction` and `ScreenKey` in place of string literals in the Supabase backend service, `SignInClient` (the `sign_in` URL), the mock backend service (response file names), the Mock environment tools (`auth.sign_in`, a real backend key), the shared screen registry and the coordinators' failure logs.
- Update `android/README.md`.

## Out of scope

- Mock fixture file names that are not a bare function name or screen key, such as `sign_in.error.account_disabled` in `MockSignInScenario.kt`: they name recorded responses and stay as literals in mock sources.
- Test sources: tests may keep literals, since asserting the exact wire value is part of their job.
- Generating or changing `names.json` (SUP-019).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `ContractNames.kt` compiles into the app in mockDebug, devDebug and devRelease, and is never copied into `android/` | One generated source, available to every variant |
| AC2 | No file under `app/src` outside test source sets contains a backend function name or backend screen key as a string literal, except the fixture file names in Out of scope | Every real call goes through a generated constant |
| AC3 | The Mock and Supabase backend services name each function with the same `RpcFunction` entry | Mock and Dev cannot disagree on a name |
| AC4 | Renaming an entry in `ContractNames.kt` by hand makes the app fail to compile | A typo is a build error, not a runtime failure |
| AC5 | All existing Mock and Dev unit, integration and UI tests pass unchanged | Behavior is unchanged; only where names come from |
| AC6 | `android/README.md` says where names come from and to run `make names` in `/backend` after editing `names.json` | The next developer knows the source |

## Technical notes

- Add `../contract/generated` to the `main` Kotlin source set in the app module's Gradle file. Gradle compiles only the `.kt` file there; the Swift file next to it is ignored.
- Package `app.parkhill.contract` (SUP-019).
- Guide 4.1 (contract names rule, added by SUP-019) and 5.2.

## Verification

```
cd android
grep -rnE '(get_entry|get_screen|get_tabs|whoami|sign_in|auth\.sign_in|home\.root|community\.home)' app/src --include='*.kt' | grep -v '/src/test\|/src/androidTest'   # only MockSignInScenario's fixture names and comments
./gradlew testMockDebugUnitTest
(cd ../backend && supabase start && supabase db reset)
./gradlew connectedDevDebugAndroidTest
```

For AC4: rename `getEntry` in `contract/generated/ContractNames.kt`, build, see the failure, revert.

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include fixture and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None.
