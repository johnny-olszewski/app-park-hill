# AND-001: Create the Android project with Mock and Dev build variants

| Field | Value |
|---|---|
| Area | android |
| Epic | EP-01 |
| Depends on | SUP-001 |
| Paired with | IOS-001 |
| Status | Done |

## Intent

Android twin of IOS-001. Environments are chosen by the build, Dev can target any backend without a commit, later environments are added by configuration, and mock code cannot ship.

## Scope

- Kotlin + Jetpack Compose app in `/android`, min SDK 26, launching to a blank placeholder screen.
- Product flavors `mock` and `dev` in one `environment` dimension.
- One binding file per flavor in its flavor source set.
- Optional gitignored override properties file for backend URL and key.
- Unit test source set with one passing test.

## Out of scope

- Service implementations (AND-002, AND-005).
- Coordinators and screens (AND-003).
- Release signing, Play Store setup.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `mockDebug` and `devDebug` each build and launch on an emulator from a clean checkout, with no extra files | Both environments are one click away; clone and run |
| AC2 | **Mock intent:** the mock variant makes no network connection and needs no backend. Its manifest does not request `INTERNET`. Stated in `/android/README.md` | The app runs completely independently |
| AC3 | **Dev intent:** the dev variant's backend URL and anon key come from committed flavor config, defaulting to local Supabase (`http://10.0.2.2:54321`). Stated in `/android/README.md` | Real end to end path, using no hosted project by default |
| AC4 | If `dev.local.properties` exists (gitignored), its URL and key replace the defaults at build time | Any developer can target any backend without a commit |
| AC5 | At launch the dev variant logs its target backend URL, and the value is available to show in UI (used by the dev tools pill, AND-021) | Nobody is surprised by a forgotten override |
| AC6 | `ServiceBinding.kt` exists once in `src/mock` and once in `src/dev`, not in `src/main` | Environment is chosen by the build, not by code |
| AC7 | `src/main` contains no check of `BuildConfig.FLAVOR`, `BuildConfig.DEBUG` or build type | No branching for variants |
| AC8 | All mock code lives under `src/mock`. `mockRelease` is disabled by a variant filter. `devRelease` output contains no class with `Mock` in its name | Mock code is compiled out of production builds |
| AC9 | Cleartext traffic is permitted only by a network security config in `src/dev` | Shipping environments cannot use cleartext endpoints |
| AC10 | `/android/README.md` documents how to add an environment (one flavor plus one source set) and how to use the override file | Expansion and switching are known in advance |
| AC11 | The application ID root appears in exactly one file; changing it there changes every variant | The placeholder can be replaced with one edit before release |

## Technical notes

- Guide 5.2.
- Gradle Kotlin DSL with a version catalog.
- Application ID root is the placeholder `app.parkhill.placeholder`, defined once in `gradle.properties` (`appIdRoot`). Flavors append `.mock` and `.dev` so builds install side by side.

## Verification

```
cd android
./gradlew assembleMockDebug testMockDebugUnitTest assembleDevDebug assembleDevRelease
./gradlew tasks --all | grep -i mockRelease     # expect no output
# inspect devRelease dex for "Mock": expect none
grep -rn "BuildConfig.FLAVOR\|BuildConfig.DEBUG" app/src/main   # expect no output
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] No environment branching in app code; no mock code in release
- [ ] No work outside Scope

## Open questions

None. (The real application ID root is decided before the first store upload, matching iOS.)
