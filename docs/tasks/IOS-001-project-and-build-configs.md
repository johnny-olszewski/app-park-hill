# IOS-001: Create the iOS project with Mock and Dev build configurations

| Field | Value |
|---|---|
| Area | ios |
| Epic | EP-01 |
| Depends on | SUP-001 |
| Paired with | AND-001 |
| Status | Done |

## Intent

Create the iOS app and the build configuration mechanism every environment will use. The mechanism matters more than the app here: a later QA or Prod environment must be a config file, a developer must be able to point Dev at any backend without committing anything, and mock code must be impossible to ship.

## Scope

- SwiftUI app in `/ios`, iOS 17 minimum, launching to a blank placeholder view.
- Configurations and schemes for Mock and Dev, driven by `.xcconfig` files.
- One binding file per configuration, compiled only in that configuration.
- Optional gitignored override xcconfig for backend URL and key.
- Unit test target with one passing test.

## Out of scope

- Service implementations (IOS-002, IOS-005).
- Coordinators and screens (IOS-003).
- Signing for distribution, App Store setup.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Schemes `ParkHill-Mock` and `ParkHill-Dev` each build and launch on a simulator from a clean checkout, with no extra files | Both environments are one click away; clone and run |
| AC2 | **Mock intent:** the Mock build makes no network connection and needs no backend. Stated in `/ios/README.md` | The app runs completely independently |
| AC3 | **Dev intent:** the Dev build's backend URL and anon key come from `Dev.xcconfig`, defaulting to local Supabase (`http://127.0.0.1:54321`). Stated in `/ios/README.md` | Real end to end path, using no hosted project by default |
| AC4 | If `Dev.local.xcconfig` exists (gitignored, included optionally by `Dev.xcconfig`), its URL and key replace the defaults | Any developer can target any backend without a commit |
| AC5 | At launch the Dev build logs its target backend URL, and the value is available to show in UI (used from IOS-006) | Nobody is surprised by a forgotten override |
| AC6 | Each configuration compiles exactly one binding file (`ServiceBinding+Mock.swift` or `ServiceBinding+Dev.swift`); the other is excluded by `EXCLUDED_SOURCE_FILE_NAMES` | Environment is chosen by the build, not by code |
| AC7 | App source contains no `#if` on configuration and no runtime environment check | No branching for variants |
| AC8 | Everything under `/ios/.../Mocks` is excluded from every Release configuration; a Dev Release build's binary contains no symbol with `Mock` in its name | Mock code is compiled out of production builds |
| AC9 | The local HTTP (non TLS) exception exists only in the Dev configuration | Shipping environments cannot use cleartext endpoints |
| AC10 | `/ios/README.md` documents how to add an environment (one xcconfig plus one binding file) and how to use the override file | Expansion and switching are known in advance |
| AC11 | The project is generated from `ios/project.yml` by `make project`; no `.xcodeproj` is committed, and a fresh clone builds after running it | Agents and people edit a small readable file; no project-file merge conflicts |
| AC12 | The bundle identifier root appears in exactly one file; changing it there changes every configuration | The placeholder can be replaced with one edit before release |

## Technical notes

- Guide 5.2.
- **XcodeGen (decided 2026-10-10):** the project is described in `ios/project.yml`; the generated `.xcodeproj` is gitignored. `make project` in `/ios` regenerates it and is documented in `/ios/README.md`. The XcodeGen version is pinned and installed the same way locally and in CI.
- Bundle identifier root is the placeholder `app.parkhill.placeholder`, defined once in a shared base xcconfig (`PRODUCT_BUNDLE_IDENTIFIER_ROOT`). Configurations append `.mock` and `.dev` so builds install side by side.

## Verification

```
cd ios
make project
xcodebuild -scheme ParkHill-Mock -destination 'platform=iOS Simulator,name=iPhone 16' build test
xcodebuild -scheme ParkHill-Dev  -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -scheme ParkHill-Dev -configuration Dev-Release -sdk iphonesimulator build
nm -a <built app binary> | grep -i mock   # expect no output
grep -rn "#if" ios --include=*.swift       # expect no configuration checks
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] No environment branching in app code; no mock code in Release
- [ ] No work outside Scope

## Open questions

None. (The real bundle identifier root is decided before the first store upload; see the guide's decision log.)
