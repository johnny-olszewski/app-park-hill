# Android

Kotlin and Jetpack Compose app, min SDK 26, with `mock` and `dev` product flavors in one `environment` dimension.

## Requirements

- JDK 17. Android Studio's bundled runtime works: `export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"`.
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

## Tests

```
./gradlew testMockDebugUnitTest testDevDebugUnitTest
```

| Source set | Runs in | Needs |
|---|---|---|
| `src/test` | Both flavors | Nothing. Decodes every recorded screen response; the Supabase service runs against a local `MockWebServer` |
| `src/testMock` | mock | Nothing |
| `src/androidTestDev` | dev, on a device or emulator | Local Supabase running: `cd backend && supabase start && supabase db reset`, then `./gradlew connectedDevDebugAndroidTest` |
