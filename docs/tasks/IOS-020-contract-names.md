# IOS-020: Use the generated contract names in the iOS app

| Field | Value |
|---|---|
| Area | ios |
| Epic | EP-05 |
| Depends on | SUP-019, IOS-008 |
| Paired with | AND-020 |
| Status | Done |

## Intent

Replace the hand-typed backend function names and screen keys in the iOS app with the constants SUP-019 generates from `contract/names.json`. A misspelled name becomes a compile error, and the Mock and Supabase services can no longer disagree on a name.

## Scope

- Compile `contract/generated/ContractNames.swift` into the app target in every configuration.
- Use `RPCFunction`, `EdgeFunction` and `ScreenKey` in place of string literals in:
  - `ParkHill/Services/Supabase/SupabaseBackendService.swift`
  - `ParkHill/Services/Supabase/SupabaseAuthService.swift`
  - `ParkHill/Mocks/MockBackendService.swift` (response file names)
  - `ParkHill/Mocks/MockSignInTools.swift` (`auth.sign_in`, a real backend key)
  - `ParkHill/Navigation/ScreenRegistry+Shared.swift`
  - the failure logs in `ParkHill/Navigation/AppCoordinator.swift` and `ShellCoordinator.swift`
- Update `ios/README.md`.

## Out of scope

- Mock fixture file names that are not a bare function name or screen key, such as `sign_in.error.account_disabled` in `MockSignInScenario.swift`: they name recorded responses and stay as literals in mock sources.
- Test sources: tests may keep literals, since asserting the exact wire value is part of their job.
- Generating or changing `names.json` (SUP-019).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `ContractNames.swift` compiles into the app in Mock-Debug, Dev-Debug and Dev-Release, and is never copied into `ios/` | One generated source, available to every configuration |
| AC2 | No file under `ParkHill/` contains a backend function name or backend screen key as a string literal, except the fixture file names in Out of scope | Every real call goes through a generated constant |
| AC3 | The Mock and Supabase backend services name each function with the same `RPCFunction` case | Mock and Dev cannot disagree on a name |
| AC4 | Renaming a case in `ContractNames.swift` by hand makes the app fail to compile | A typo is a build error, not a runtime failure |
| AC5 | All existing Mock and Dev unit, integration and UI tests pass unchanged | Behavior is unchanged; only where names come from |
| AC6 | `ios/README.md` says where names come from and to run `make names` in `/backend` after editing `names.json` | The next developer knows the source |

## Technical notes

- Add `../contract/generated/ContractNames.swift` as a source of the `ParkHill` target in `project.yml`, by file path so the Kotlin file next to it is not added. Run `make project`.
- `App.xcconfig` excludes only `*/contract/fixtures` and `*/contract/seed`, so the generated file reaches Dev and release builds without xcconfig changes. Confirm with `xcodebuild -showBuildSettings`.
- `MockBackendService` builds response file names from the function name: `"get_screen.\(key)"` becomes `"\(RPCFunction.getScreen.rawValue).\(key)"`.
- Guide 4.1 (contract names rule, added by SUP-019) and 5.2.

## Verification

```
cd ios
make project
grep -rnE '"(get_entry|get_screen|get_tabs|whoami|sign_in|auth\.sign_in|home\.root|community\.home)' ParkHill   # only MockSignInScenario's fixture names
xcodebuild -scheme ParkHill-Mock -destination 'platform=iOS Simulator,name=iPhone 16' test
xcodebuild -scheme ParkHill-Dev  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

For AC4: change `case getEntry` in `contract/generated/ContractNames.swift`, build, see the failure, revert.

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include fixture and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None.
