# Android

Kotlin and Jetpack Compose app, min SDK 26, with `mock` and `dev` product flavors in one `environment` dimension.

## Requirements

- JDK 17 or 21. Gradle 8.11 does not run on newer Java, and recent Android Studio bundles Java 25, so do not use its bundled runtime. A JetBrains Runtime 21 works, for example `export JAVA_HOME=~/Library/Java/JavaVirtualMachines/jbr-21.0.11/Contents/Home`.
- In Android Studio, set Settings → Build, Execution, Deployment → Build Tools → Gradle → Gradle JDK to that JDK 17 or 21.
- Android SDK with platform 35 (`local.properties` with `sdk.dir=...`, or `ANDROID_HOME`). `local.properties` is gitignored.
- Gradle comes from the wrapper (`./gradlew`, Gradle 8.11.1, checksum pinned).

## Getting started

```
cd android
./gradlew assembleMockDebug assembleDevDebug
```

Both variants install side by side: `app.parkhill.placeholder.mock` ("Park Hill Mock") and `app.parkhill.placeholder.dev` ("Park Hill Dev").

## Environments

Selection happens at build time (guide 5.2). App code never checks which flavor it is: each flavor's source set provides one `ServiceBinding.kt`, which declares the environment. `src/main` contains no `BuildConfig.FLAVOR` or `BuildConfig.DEBUG` check.

| Variant | Source set | Backend | Ships |
|---|---|---|---|
| `mockDebug` | `src/mock` | None. No `INTERNET` permission; services read contract fixtures | Never; `mockRelease` is disabled |
| `devDebug`, `devRelease` | `src/dev` | Local Supabase at `http://10.0.2.2:54321` (the host, from the emulator) by default | `devRelease` is the release build |

At launch every build logs its environment and backend, for example `Environment Dev, backend http://10.0.2.2:54321` (tag `ParkHill`). The value is `ServiceBinding.environment.backendLabel`.

**Cleartext** traffic is allowed only to local Supabase, by `src/dev/res/xml/network_security_config.xml`. Shipping environments use TLS.

### Pointing Dev at another backend

Create `android/dev.local.properties` (gitignored). When present it replaces the defaults at build time:

```
backendUrl=https://your-project.supabase.co
backendAnonKey=<anon key>
```

Delete it to return to local Supabase. Never commit hosted keys.

### Adding an environment

For example QA, reusing the Supabase services with different values:

1. In `app/build.gradle.kts`, add a `qa` flavor in the `environment` dimension with `applicationIdSuffix = ".qa"`, its `app_name`, and its `BACKEND_URL` and `BACKEND_ANON_KEY` build config fields (hosted values from CI secrets, never committed).
2. Add `app/src/qa/java/app/parkhill/environment/ServiceBinding.kt` declaring the environment, like the dev one.
3. Give it no cleartext exception.

### Application ID

The root `app.parkhill.placeholder` is defined once, as `appIdRoot` in `gradle.properties`; flavors append `.mock` and `.dev`. **Replace it before the first store upload** (guide decision log). The Kotlin namespace is `app.parkhill` and does not change with it.

## Services

All backend data goes through `BackendService` (`services/backend`). Screens and coordinators depend on it, never on Supabase types; only `services/supabase` imports supabase-kt.

| Type | Flavor | Behavior |
|---|---|---|
| `SupabaseBackendService` | dev | Calls `get_entry` and `get_screen` through the one client from `SupabaseClientProvider`, which adds the standard headers (`X-App-Config`, `X-App-Platform`, `X-App-Version`, `Accept-Language`) on its OkHttp engine |
| `MockBackendService` | mock | Reads the fixtures bundled as mock assets straight from `/contract/fixtures`: `get_entry.json`, `get_screen.<key>.json`, preferring `<persona>/<name>.json` for the current persona |

Each flavor's `ServiceBinding.kt` declares `typealias AppBackendService`; `AppServices` constructs it. Failures reach callers as `BackendError`: `Network`, `UnknownScreen`, `Unauthorized`, `Decoding` or `Server`.

### Auth

Sign-in, session and sign-out go through `AuthService` (`services/auth`), declared by each binding as `AppAuthService`.

| Type | Flavor | Behavior |
|---|---|---|
| `SupabaseAuthService` | dev | Signs in through the backend's `sign_in` function (`SignInClient`, a direct call so the backend's code and message arrive unchanged), then imports the session into the shared client, which renews it |
| `MockAuthService` | mock | Any credentials sign in as the first active persona in the bundled `contract/seed/dataset.json`; `signIn(persona)` sets the persona `MockBackendService` reads fixtures for. No network; not persisted |

- **Session storage:** `EncryptedSessionManager` stores the session in `filesDir/Session/`, encrypted with an AES-GCM key held in the Android Keystore. Never plain `SharedPreferences`.
- **Sign-in errors** are `SignInError`: `Rejected(code, message)` with the backend's text unchanged, plus `Network` and `Unexpected`.
- **Staying signed in:** `restoreSession()` treats a stored session as signed in when offline; a refused renewal signs out with reason `SessionEnded`.
- **Unauthorized rule:** `AppServices.backend` wraps the backend service in `SessionRenewingBackendService`: one renewal and one retry, then the session ends. Network failures never sign anyone out.
- **Sign-out** revokes the session when online and always deletes it, `filesDir/Cache/` and `filesDir/UserFiles/`, even offline.

## Screens and launch

`ParkHillApplication` builds the services and `AppCoordinator` once per process and starts launch; `MainActivity` shows `AppRoot`. Launch restores the session: signed in shows the signed-in destination (the temporary placeholder in `temporary/`, deleted by AND-008), signed out shows the entry: loading, the backend's entry screen (resolved through `ScreenRegistry`) or the launch error. The coordinator follows `AuthService.state`: signing in shows the destination; signing out, or access ending, returns to the entry, with `session_ended_message` when access ended. Returning to the foreground while signed in calls `whoami()`, so a disabled account is signed out on its next foreground.

| Situation | Shows |
|---|---|
| `get_entry` succeeds with a registered key | That screen; the envelope is cached for the locale |
| `get_entry` fails, cached entry exists | The cached screen |
| `get_entry` fails, no usable cache | Error screen with retry (bundled text) |
| `get_entry` returns a key this build does not register | Error screen, even with a cache (guide 5.3 rule 5); logged |
| Return to the foreground | Refetch; a failure keeps the screen showing |

The cache is one JSON file per locale under `filesDir/Cache/entry/`; sign-out will delete `filesDir/Cache/` (AND-005).

**Entry by flavor:** both show `auth.sign_in` from `get_entry`. In mock, any credentials sign in as the first active persona; choosing the persona and result comes with the mock menu (AND-022).

**Sign-in errors:** backend refusals show under the password field in the danger color; `cannot_connect_message` and `session_ended_message` show in a box above the fields.

## Design

`design/Theme.kt` holds the Park Hill tokens from the wireframes, matching iOS: colors with light and dark values, the serif used for headings, 14dp shapes, and primary and secondary buttons and field colors on Material components (guide 5.5). Headings use the system serif until the brand fonts are bundled.

**Adding a screen:** add its `@Serializable` data model and composable under `screens/`, then register its key in `navigation/SharedScreens.kt`. Each flavor's `ServiceBinding.makeScreenRegistry` builds the registry from the screen sets it includes; a mock-only screen would register there in `src/mock`. Composables never create other screens or navigate; coordinators do.

## Tests

```
./gradlew testMockDebugUnitTest testDevDebugUnitTest
```

| Source set | Runs in | Needs |
|---|---|---|
| `src/test` | Both flavors | Nothing. Decodes every recorded screen response; the Supabase service runs against a local `MockWebServer` |
| `src/testMock` | mock | Nothing |
| `src/androidTest` | Both flavors, on a device or emulator | Nothing. The Keystore session cipher; shared UI test helpers |
| `src/androidTestMock` | mock, on a device or emulator | Nothing. Sign-in with any credentials |
| `src/androidTestDev` | dev, on a device or emulator | Local Supabase, reset recently (each run adds one failed sign-in for `admin`, and 5 within 15 minutes lock it): `cd backend && supabase start && supabase db reset`, then `./gradlew connectedDevDebugAndroidTest` |

Client CI runs Mock only (guide 6), so run the dev tests locally before merging changes to `/android`, `/backend` or `/contract`, with an emulator running:

```
make test-dev
```

It starts and resets local Supabase (Docker must be running), then runs `connectedDevDebugAndroidTest`.

### CI

`.github/workflows/android.yml` runs on PRs that change `/android`, `/contract` or `/backend`, on `ubuntu-latest` with JDK 17:

| Step | Script or command |
|---|---|
| No build-variant branching | `scripts/check_sources.sh`: no `BuildConfig.FLAVOR`, `DEBUG` or `BUILD_TYPE` in `src/main` (also run by the pre-push hook) |
| Unit tests | `./gradlew testMockDebugUnitTest testDevDebugUnitTest` |
| No mock code in the release build | Builds `devRelease`, then `scripts/check_release_apk.sh <apk>`: no `app.parkhill` class with `Mock` or in `mocks`, no contract fixtures in assets |
