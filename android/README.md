# Android

Kotlin and Jetpack Compose app, min SDK 26, with `mock` and `local` product flavors in one `environment` dimension.

## Requirements

- JDK 17 or 21. Gradle 8.11 does not run on newer Java, and recent Android Studio bundles Java 25, so do not use its bundled runtime. A JetBrains Runtime 21 works, for example `export JAVA_HOME=~/Library/Java/JavaVirtualMachines/jbr-21.0.11/Contents/Home`.
- In Android Studio, set Settings → Build, Execution, Deployment → Build Tools → Gradle → Gradle JDK to that JDK 17 or 21.
- Android SDK with platform 35 (`local.properties` with `sdk.dir=...`, or `ANDROID_HOME`). `local.properties` is gitignored.
- Gradle comes from the wrapper (`./gradlew`, Gradle 8.11.1, checksum pinned).

## Getting started

```
cd android
./gradlew assembleMockDebug assembleLocalDebug
```

Both variants install side by side: `app.parkhill.placeholder.mock` ("Park Hill Mock") and `app.parkhill.placeholder.local` ("Park Hill Local").

## Environments

Selection happens at build time (guide 5.2). App code never checks which flavor it is: each flavor's source set provides one `ServiceBinding.kt`, which declares the environment. `src/main` contains no `BuildConfig.FLAVOR` or `BuildConfig.DEBUG` check.

| Variant | Source set | Backend | Ships |
|---|---|---|---|
| `mockDebug` | `src/mock` | None. No `INTERNET` permission; services read mock responses | Never; `mockRelease` is disabled |
| `localDebug`, `localRelease` | `src/local` | Local Supabase at `http://10.0.2.2:54321` (the host, from the emulator) by default | `localRelease` is the release build |

At launch every build logs its environment and backend, for example `Environment Local, backend http://10.0.2.2:54321` (tag `ParkHill`). The value is `ServiceBinding.environment.backendLabel`.

**Cleartext** traffic is allowed only to local Supabase, by `src/local/res/xml/network_security_config.xml`. Shipping environments use TLS.

### Pointing Local at another backend

Create `android/local.override.properties` (gitignored). When present it replaces the defaults at build time:

```
backendUrl=https://your-project.supabase.co
backendAnonKey=<anon key>
```

Delete it to return to local Supabase. Never commit hosted keys.

### Adding an environment

For example QA, reusing the Supabase services with different values:

1. In `app/build.gradle.kts`, add a `qa` flavor in the `environment` dimension with `applicationIdSuffix = ".qa"`, its `app_name`, and its `BACKEND_URL` and `BACKEND_ANON_KEY` build config fields (hosted values from CI secrets, never committed).
2. Add `app/src/qa/java/app/parkhill/environment/ServiceBinding.kt` declaring the environment, like the local one.
3. Give it no cleartext exception.

### Application ID

The root `app.parkhill.placeholder` is defined once, as `appIdRoot` in `gradle.properties`; flavors append `.mock` and `.local`. **Replace it before the first store upload** (guide decision log). The Kotlin namespace is `app.parkhill` and does not change with it.

## Services

All backend data goes through `BackendService` (`services/backend`). Screens and coordinators depend on it, never on Supabase types; only `services/supabase` imports supabase-kt.

| Type | Flavor | Behavior |
|---|---|---|
| `SupabaseBackendService` | local | Calls `get_entry`, `get_screen`, `get_tabs` and `whoami` through the one client from `SupabaseClientProvider`, which adds the standard headers (`X-App-Config`, `X-App-Platform`, `X-App-Version`, `Accept-Language`) on its OkHttp engine |
| `MockBackendService` | mock | Reads the mock responses bundled as mock assets straight from `/contract/mock_responses`: `get_entry.json`, `get_screen.<key>.json`, and the signed-in persona's `get_tabs.json` and `whoami.json`, preferring `<persona>/<name>.json` for the current persona |

Each flavor's `ServiceBinding.kt` declares `typealias AppBackendService`; `AppServices` constructs it. Failures reach callers as `BackendError`: `Network`, `UnknownScreen`, `Unauthorized`, `Decoding` or `Server`.

### Contract names

Backend function names and screen keys come from `/contract/generated/ContractNames.kt` (`RpcFunction`, `EdgeFunction`, `ScreenKey`, package `app.parkhill.contract`), generated from `/contract/names.json`. Every response type is generated beside it, in the same package, by `make models`: screen data models (`SignInScreenData`, `HomeRootData`, `CommunityHomeData`) from `/contract/screens`, and the screen envelope and other responses (`ScreenEnvelope`, `TabsResponse`, `TabItem`, `Profile`, `SignInSuccess`, `SignInSession`, `SignInFailure`) from `/contract/types`. No response type is written by hand in `app/src`; only request bodies such as `SignInRequest` are, and responses decode with `ContractJson`. The `main` source set compiles every Kotlin file in `/contract/generated` in place for every variant, so a new model needs no Gradle change. Never write a backend function name or screen key as a string literal in `app/src`, and never edit or copy the generated file: edit `names.json` and run `make names` in `/backend`. Tests may use literals to assert wire values; mock response file names such as `sign_in.error.account_disabled` stay as text.

### Auth

Sign-in, session and sign-out go through `AuthService` (`services/auth`), declared by each binding as `AppAuthService`.

| Type | Flavor | Behavior |
|---|---|---|
| `SupabaseAuthService` | local | Signs in through the backend's `sign_in` function (`SignInClient`, a direct call so the backend's code and message arrive unchanged), then imports the session into the shared client, which renews it |
| `MockAuthService` | mock | Any credentials give the result armed in its `MockSignInScenario` (Mock sign-in, below); `signIn(persona)` sets the persona `MockBackendService` reads mock responses for. No network; not persisted |

- **Session storage:** `EncryptedSessionManager` stores the session in `filesDir/Session/`, encrypted with an AES-GCM key held in the Android Keystore. Never plain `SharedPreferences`.
- **Sign-in errors** are `SignInError`: `Rejected(code, message)` with the backend's text unchanged, plus `Network` and `Unexpected`.
- **Staying signed in:** `restoreSession()` treats a stored session as signed in when offline; a refused renewal signs out with reason `SessionEnded`.
- **Unauthorized rule:** `AppServices.backend` wraps the backend service in `SessionRenewingBackendService`: one renewal and one retry, then the session ends. Network failures never sign anyone out.
- **Sign-out** revokes the session when online and always deletes it, `filesDir/Cache/` and `filesDir/UserFiles/`, even offline.

## Screens and launch

`ParkHillApplication` builds the services and `AppCoordinator` once per process and starts launch; `MainActivity` shows `AppRoot`. Launch restores the session: signed in shows the tabs, signed out shows the entry: loading, the backend's entry screen (resolved through `ScreenRegistry`) or the launch error. The coordinator follows `AuthService.state`: signing in shows the tabs; signing out, or access ending, returns to the entry, with `session_ended_message` when access ended. A new signed-in user gets a new `ShellCoordinator`.

| Situation | Shows |
|---|---|
| `get_entry` succeeds with a registered key | That screen; the envelope is cached for the locale |
| `get_entry` fails, cached entry exists | The cached screen |
| `get_entry` fails, no usable cache | Error screen with retry (bundled text) |
| `get_entry` returns a key this build does not register | Error screen, even with a cache (guide 5.3 rule 5); logged |
| Return to the foreground | Refetch; a failure keeps the screen showing |

The cache is one JSON file per locale under `filesDir/Cache/entry/` (`LocaleCache`; the tabs use `Cache/tabs/`). Sign-out deletes `filesDir/Cache/` (AND-005).

**Tabs:** `ShellCoordinator` fetches `get_tabs` and shows the tabs in the Material navigation bar (`SignedInShell`), each in its own `TabCoordinator` with a stack and a sheet, kept while switching tabs. Only the selected tab is composed; each tab's saveable state is kept. Returning to the foreground fetches the tabs again; the request also checks the session, so a disabled account is signed out on its next foreground.

| Situation | Shows |
|---|---|
| `get_tabs` succeeds | Up to five tabs in backend order, first selected on a fresh shell; cached for the locale |
| A tab's root screen key is not registered | That tab is dropped and logged; if none is left, the error screen |
| More than five tabs | The first five; the rest logged |
| `get_tabs` fails, cached tabs exist | The cached tabs |
| `get_tabs` fails, no cache | Error screen with retry |
| Foreground refetch | Tabs update; unchanged tabs keep their stacks and the selected tab stays |

Tab icons come from `AssetProvider` (`design/`): bundled placeholder drawables for `tab.home` and `tab.community`, and a fallback for any other key. **Toolbar:** every backend screen's envelope `toolbar` shows as top app bar actions, in backend order (`ScreenToolbar.kt`): each item's icon from `AssetProvider` (a placeholder for `toolbar.browse`, a fallback for any other key) with its label as the content description, and items beyond three go to the overflow menu, in order (`ToolbarLayout`). Home's top app bar has a temporary Sign out button, marked `TEMPORARY(EP-04)`, until the account entry replaces it.

**Transitions:** `AppRoot` moves the entry like the iOS full-screen cover: after sign-in it slides down to reveal the tabs, and on sign-out or access ending it slides back up over them. Launch and changes inside the entry cross-fade. With animations off (developer options) every change is instant. Screens know nothing about it.

**Entry by flavor:** both show the production `auth.sign_in` from `get_entry`. In mock, the persona and result come from the mock menu (Mock sign-in, below).

**Sign-in errors:** backend refusals show under the password field in the danger color; `cannot_connect_message` and `session_ended_message` show in a box above the fields.

## Design

`design/Theme.kt` holds the Park Hill tokens from the wireframes, matching iOS: colors with light and dark values, the serif used for headings, 14dp shapes, and primary and secondary buttons and field colors on Material components (guide 5.5). Headings use the system serif until the brand fonts are bundled.

**Adding a screen:** add its `@Serializable` data model and composable under `screens/`, then register its key in `navigation/SharedScreens.kt`. Each flavor's `ServiceBinding.makeScreenRegistry` builds the registry from the screen sets it includes; a mock-only screen would register there in `src/mock`. Composables never create other screens or navigate; coordinators do.

## Dev tools

Debug builds (`mockDebug`, `localDebug`) show a pill with the environment name (`MOCK`, `LOCAL`) centered below the status bar on every screen. Long-press it to open the menu, a bottom sheet with:

1. Armed warnings, when a tool has armed something other than the normal result. The pill then shows an alert icon.
2. The current screen's tools, if any registered for its key.
3. App tools: Build (environment and backend), Screen (current screen key; tap for its data as JSON, copyable), Data (clear `filesDir/Cache/`, after confirming) and Session (Sign out when signed in).

| Source set | Holds |
|---|---|
| `src/debug/.../devtools` | `DevTools` (`typealias AppDevTools`), the overlay, pill and menu, `CurrentScreenTracker`, `DevToolRegistry` and `AppTools` |
| `src/release/.../devtools` | `NoDevTools`: no tracker, nothing drawn. Release builds compile no other dev tools class (`scripts/check_release_apk.sh`) |
| `src/mockDebug`, `src/localDebug` | `registerEnvironmentTools`: each environment's own tools |

`ParkHillApplication` creates `AppDevTools` and installs it: activity lifecycle callbacks add the overlay to each activity's window, above its content. Only the pill takes touches. Dialogs and bottom sheets are separate windows and cover the pill while open (guide decision log). `ScreenRegistry` reports every resolved screen to the `ScreenTracker` it is given; the newest one showing is the current screen.

**Adding a screen tool:** in the source set for the variants that should have it, register it in that environment's `registerEnvironmentTools`:

```kotlin
registry.register(
    DevTool(id = "events.feed", title = "Feed", warningText = { if (failing) "Feed will fail" else null }) {
        ToolActionRow("Fail next load") { failing = true }
    },
    forScreen = "events.feed",
)
```

It shows only while that screen is current. Read state the tool changes from Compose snapshot state, so the menu and pill update. Production screens never reference dev tools.

### Mock sign-in

The mock build adds tools in `src/mockDebug` (specs/AUTH.md 5.4). On sign-in, the menu offers:

- **Sign in as:** the active personas in the bundled `contract/seed/dataset.json`, first one by default. The disabled persona is reached through Account disabled.
- **Next sign-in:** Success (default), the five recorded refusals (`sign_in.error*.json`, shown under the password field with the backend's text), No connection and Something went wrong (both show `cannot_connect_message`).

Any email and password then give the armed result. While a result other than Success is armed, the pill shows an alert icon and the menu starts with "Next sign-in will fail: <result>". Choices last until changed or the app is relaunched. While signed in, **Switch persona** (on every screen) signs in as another persona without signing out.

## Tests

```
./gradlew testMockDebugUnitTest testLocalDebugUnitTest
```

| Source set | Runs in | Needs |
|---|---|---|
| `src/test` | Both flavors | Nothing. Decodes every recorded screen response; the Supabase service runs against a local `MockWebServer` |
| `src/testDebug` | Both debug variants | Nothing. Dev tools registry, current screen and JSON formatting |
| `src/testMock` | mock | Nothing |
| `src/androidTest` | Both flavors, on a device or emulator | Nothing. The Keystore session cipher; shared UI test helpers |
| `src/androidTestMock` | mock, on a device or emulator | Nothing. The dev tools pill and menu; sign-in as a chosen persona, a refusal, No connection and Switch persona through the menu |
| `src/androidTestLocal` | local, on a device or emulator | Local Supabase, reset recently (each run adds one failed sign-in for `admin`, and 5 within 15 minutes lock it): `cd backend && supabase start && supabase db reset`, then `./gradlew connectedLocalDebugAndroidTest` |

Client CI runs Mock only (guide 6), so run the local tests on your machine before merging changes to `/android`, `/backend` or `/contract`, with an emulator running:

```
make test-local
```

It starts and resets local Supabase (Docker must be running), then runs `connectedLocalDebugAndroidTest`: the integration tests and the local UI tests (sign in, wrong password message, sign out, still signed in after relaunch).

### CI

`.github/workflows/android.yml` runs on PRs that change `/android`, `/contract` or `/backend`, on `ubuntu-latest` with JDK 17:

| Step | Script or command |
|---|---|
| No build-variant branching | `scripts/check_sources.sh`: no `BuildConfig.FLAVOR`, `DEBUG` or `BUILD_TYPE` in `src/main` (also run by the pre-push hook) |
| Unit tests | `./gradlew testMockDebugUnitTest testLocalDebugUnitTest` |
| Mock UI tests | A second job runs `connectedMockDebugAndroidTest` on an API 34 emulator |
| No mock code in the release build | Builds `localRelease`, then `scripts/check_release_apk.sh <apk>`: no `app.parkhill` class with `Mock` or in `mocks`, no dev tools class except `NoDevTools`, no mock responses in assets |
