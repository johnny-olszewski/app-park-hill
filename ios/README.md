# iOS

SwiftUI app, iOS 17 minimum. The Xcode project is generated with XcodeGen from `project.yml`; the `.xcodeproj` is not committed.

## Requirements

- Xcode 26 or later
- XcodeGen **2.46.0**: `brew install xcodegen`. `make project` refuses other versions; when upgrading, update the pin in `Makefile` and here together.

## Getting started

```
cd ios
make project
open ParkHill.xcodeproj
```

Run `make project` again whenever you pull changes to `project.yml` or add, move or delete files.

## Environments

Selection happens at build time (guide 5.2). App code never checks which environment it is in: each configuration compiles exactly one binding file, which declares the environment and, from IOS-002, the service types.

| Scheme | Configurations | Bundle ID | Backend |
|---|---|---|---|
| `ParkHill-Mock` | `Mock-Debug` | `<root>.mock` | None |
| `ParkHill-Dev` | `Dev-Debug` (run, test), `Dev-Release` (archive, profile) | `<root>.dev` | Local Supabase by default |

Mock and Dev install side by side.

**Mock** makes no network connections and needs no backend. Services read the mock responses; sign-in is the production screen, with the persona and result chosen in the mock menu. Use it for UI work, previews, demos and UI tests. Mock never ships, so it has no Release configuration.

**Dev** is the real end-to-end path. Its backend URL and anon key come from `Config/Dev.xcconfig` and default to local Supabase at `http://127.0.0.1:54321` (start it from `/backend`). No hosted project is used unless you override it.

At launch every build logs its environment and backend target, for example `Environment Dev, backend http://127.0.0.1:54321`. The value is available as `ServiceBinding.environment.backendLabel`. Debug builds also show the environment on screen in the dev tools pill (see Dev tools).

### Pointing Dev at another backend

Create `Config/Dev.local.xcconfig`. It is gitignored and, when present, replaces the defaults:

```
BACKEND_URL = https:/$()/your-project.supabase.co
BACKEND_ANON_KEY = <anon key>
```

`/$()/` is required: `//` would start a comment in an xcconfig. Delete the file to return to local Supabase. Never commit hosted keys.

### How selection works

| File | Role |
|---|---|
| `Config/Base.xcconfig` | Shared by every configuration and target. Holds `PRODUCT_BUNDLE_IDENTIFIER_ROOT`, the only place the bundle identifier root appears |
| `Config/App.xcconfig` | App target settings. Excludes every `ServiceBinding+*.swift`, `DevToolsBinding+*.swift` and `DevTools+*.swift`, everything under `Mocks/` and the mock responses, then includes `ServiceBinding+$(APP_ENVIRONMENT).swift` and `DEV_TOOLS_SOURCES` (`DevToolsBinding+Enabled.swift` and `DevTools+$(APP_ENVIRONMENT).swift`) |
| `Config/Mock.xcconfig` | `APP_ENVIRONMENT = Mock`; the one configuration that compiles `Mocks/` and bundles `/contract/mock_responses` |
| `Config/Dev.xcconfig` | `APP_ENVIRONMENT = Dev`, backend values, optional `Dev.local.xcconfig`; `Dev-Release` sets `DEV_TOOLS_SOURCES = DevToolsBinding+Disabled.swift` and excludes `DevTools/` |
| `Config/Dev-Info.plist` | Puts the backend values into Info.plist, plus the local HTTP exception (`NSAllowsLocalNetworking`), which exists only in Dev |
| `ParkHill/Environment/ServiceBinding+Dev.swift` | Dev binding: `AppBackendService = SupabaseBackendService` |
| `ParkHill/Mocks/ServiceBinding+Mock.swift` | Mock binding: `AppBackendService = MockBackendService` |
| `Config/Tests-Mock.xcconfig`, `Config/Tests-Dev.xcconfig` | Test target: Mock excludes `ParkHillTests/Integration/`, Dev excludes `ParkHillTests/Mocks/` (and `ParkHillTests/DevTools/` in `Dev-Release`) |
| `ParkHill/DevTools/DevToolsBinding+Enabled.swift`, `ParkHill/Environment/DevToolsBinding+Disabled.swift` | Dev tools binding: `AppDevTools = DevTools` in debug configurations, `NoDevTools` in release |

### Adding an environment

For example, QA, reusing the Supabase services with different values:

1. Add `Config/QA.xcconfig`: include `App.xcconfig`, set `APP_ENVIRONMENT = QA`, `APP_ENVIRONMENT_ID = qa`, `APP_DISPLAY_NAME`, `BACKEND_URL`, `BACKEND_ANON_KEY` and `INFOPLIST_FILE = Config/QA-Info.plist`. Leave dev tools out of its release configuration: `DEV_TOOLS_SOURCES[config=QA-Release] = DevToolsBinding+Disabled.swift` and `DEV_TOOLS_EXCLUDED[config=QA-Release] = */DevTools/*`. Add `ParkHill/DevTools/DevTools+QA.swift` declaring its tools (none, like `DevTools+Dev.swift`).
2. Add `Config/QA-Info.plist` with the `BackendURL` and `BackendAnonKey` keys only. No HTTP exception: shipping environments use TLS.
3. Add `ParkHill/Environment/ServiceBinding+QA.swift`, declaring the environment and service types like the Dev binding.
4. In `project.yml`, add `QA-Debug: debug` and `QA-Release: release` under `configs`, map them in every `configFiles` section (project, app and tests; QA tests use `Tests-Dev.xcconfig`), and add a `ParkHill-QA` scheme.
5. `make project`.

Hosted values come from CI secrets, never from committed files.

## Services

All backend data goes through `BackendService` (`ParkHill/Services/Backend/`). Screens and coordinators depend on it, never on Supabase types.

| Type | Configurations | Behavior |
|---|---|---|
| `SupabaseBackendService` | Dev | Calls `get_entry`, `get_screen`, `get_tabs` and `whoami` through the shared client from `SupabaseClientProvider`, with the standard request headers |
| `MockBackendService` | Mock | Reads the bundled mock responses: `get_entry.json`, `get_screen.<key>.json`, and the signed-in persona's `get_tabs.json` and `whoami.json`, preferring `<persona>/<name>.json` for the current persona |

### Contract names

Backend function names and screen keys come from `/contract/generated/ContractNames.swift` (`RPCFunction`, `EdgeFunction`, `ScreenKey`), generated from `/contract/names.json` and compiled into the app in every configuration by `project.yml`. Never write a backend function name or screen key as a string literal in `ParkHill/`, and never edit or copy the generated file: edit `names.json`, run `make names` in `/backend`, then `make project`. Tests may use literals to assert wire values.

The Supabase SDK (supabase-swift, pinned in `project.yml`) is imported only under `ParkHill/Services/Supabase/` (and by the Dev-only integration tests). Failures reach callers as `BackendError`: `network`, `unknownScreen`, `unauthorized`, `decoding` or `server`.

### Auth

Sign-in, session and sign-out go through `AuthService` (`ParkHill/Services/Auth/`), declared by each binding as `AppAuthService`.

| Type | Configurations | Behavior |
|---|---|---|
| `SupabaseAuthService` | Dev | Signs in through the backend's `sign_in` function, then hands the session to the shared Supabase client, which stores it in the Keychain and renews it |
| `MockAuthService` | Mock | `signIn(email:password:)` gives the result armed in `MockSignInScenario`, whatever was typed: Success signs in as the chosen persona; refusals throw the recorded `sign_in.error*.json` message. `signIn(persona:)` sets the persona `MockBackendService` reads mock responses for. No network; not persisted across launches |

- **Sign-in errors** are `SignInError`: `rejected(code:message:)` carries the backend's text unchanged, plus `network` and `unexpected`.
- **Staying signed in:** `restoreSession()` treats a stored session as signed in when offline; a refused renewal signs out with reason `sessionEnded`.
- **Unauthorized rule:** `AppServices.backend` wraps the backend service in `SessionRenewingBackendService`. A request refused as unauthorized gets one renewal and one retry; if either is refused, the session ends. Network failures never sign anyone out.
- **Sign-out** deletes the session (revoking it when online), `Application Support/Cache/` and `Application Support/UserFiles/`, even offline.
- `stateChanges()` streams the current `AuthState`, then every change. IOS-006 drives the coordinator from it.

## Screens and launch

`AppCoordinator` (`ParkHill/Navigation/`) owns launch and the root. The root is the signed-in shell of tabs; the signed-out entry is a full-screen cover over it, holding a loading indicator, the backend's entry screen (resolved through `ScreenRegistry`) or the launch error. Signing in hides the cover to reveal the destination; signing out or access ending presents it again, and the destination is cleared once the cover is up. A cold start that is signed out shows the cover without animation. On return to the foreground the entry is fetched again.

| Situation | Shows |
|---|---|
| `get_entry` succeeds with a registered key | That screen; the envelope is cached for the locale |
| `get_entry` fails, cached entry exists | The cached screen |
| `get_entry` fails, no usable cache | Error screen with retry (bundled text) |
| `get_entry` returns a key this build does not register | Error screen, even with a cache (guide 5.3 rule 5); logged |
| Foreground refetch fails | The screen already showing |

The cache is one JSON file per locale under `Application Support/Cache/entry/` (`LocaleCache`; the tabs use `Cache/tabs/`). Sign-out deletes `Application Support/Cache/` (IOS-005).

**Signed in:** the coordinator follows `AuthService.stateChanges()`. Launch with a stored session goes straight to the tabs; signing out, or access ending, returns to the entry screen, with `session_ended_message` shown when access ended. A new signed-in user gets a new `ShellCoordinator`.

**Tabs:** `ShellCoordinator` fetches `get_tabs` and shows the tabs in the system tab bar (`SignedInShellView`), each in its own `TabCoordinator` with a navigation stack and a sheet, kept while switching tabs. Returning to the foreground fetches the tabs again; the request also checks the session, so a disabled account is signed out on its next foreground.

| Situation | Shows |
|---|---|
| `get_tabs` succeeds | Up to five tabs in backend order, first selected on a fresh shell; cached for the locale |
| A tab's root screen key is not registered | That tab is dropped and logged; if none is left, the error screen |
| More than five tabs | The first five; the rest logged |
| `get_tabs` fails, cached tabs exist | The cached tabs |
| `get_tabs` fails, no cache | Error screen with retry |
| Foreground refetch | Tabs update; unchanged tabs keep their stacks and the selected tab stays |

Tab icons come from `AssetProvider` (`ParkHill/Design/`): bundled placeholder symbols for `tab.home` and `tab.community`, and a fallback for any other key. Home's toolbar has a temporary Sign out button, marked `TEMPORARY(EP-04)`, until the account entry replaces it.

**Entry by configuration:** Dev shows `auth.sign_in` from `get_entry`. Mock shows the same `auth.sign_in`, from the recorded `get_entry.json`; the mock menu decides what signing in does (Dev tools, Mock tools).

**Environment on screen:** debug builds show `MOCK` or `DEV` in the dev tools pill on every screen; the full backend address is in the menu's Build tool. Release builds show nothing. Screens never draw it themselves.

**Adding a screen:** add its data model and view under `ParkHill/Screens/`, then register its key in `ScreenRegistry+Shared.swift`. A Mock-only screen (a `.mock` key) would register from the Mock binding in `ParkHill/Mocks/`; there are none today. Each binding builds the registry from the screen sets its configuration includes. Views never create other screens or change navigation; coordinators do.

## Dev tools

Debug configurations (`Mock-Debug`, `Dev-Debug`) put a pill at the top of every screen, centered just below the status bar, showing the environment (`MOCK`, `DEV`). **Long-press the pill** to open the menu. There is no on-screen hint; the gesture is for the team.

The pill lives in its own window (`DevToolsWindow`) one level above the app's window, so it stays above the sign-in full-screen cover and any sheet. That window takes touches only on the pill and while the menu is open; everything else reaches the app. Closing the menu hands key status back to the app's window.

The menu shows, in order:

1. **Warnings**: every armed failure reported by any tool. While one exists, the pill shows an alert icon.
2. **Screen tools**: tools registered for the current screen's key.
3. **App tools**: Build (environment and backend address), Screen (current screen key and data as copyable JSON), Data (clear cached data, with confirmation), Session (sign out).

**Current screen:** `ScreenRegistry` reports every screen it resolves to a `ScreenTracker` when it appears and disappears. The dev tools tracker treats the newest visible one as current. Screens never reference the tracker; release builds pass none.

**Adding a tool:** build a `DevTool` (an id, a section title, optional `warning`, and the rows as a view) and register it on `DevTools.registry`: `register(_:forScreen:)` for one screen key, or `registerAppTool(_:)` for every screen. A tool that arms a non-normal result returns its warning text from `warning` while armed. Keep tools under `ParkHill/DevTools/` (all debug builds) or `ParkHill/Mocks/` (Mock only), never under `ParkHill/Screens/`.

**Environment tools:** each debug environment adds its own tools in `DevTools+<environment>.swift`, selected by `DEV_TOOLS_SOURCES`: `ParkHill/Mocks/DevTools+Mock.swift` and `ParkHill/DevTools/DevTools+Dev.swift` (none).

**Mock tools** (`ParkHill/Mocks/MockSignInTools.swift`, specs/AUTH.md 5.4):

- On sign-in, **Sign in as** (the active personas in the bundled dataset; default the first) and **Next sign-in** (Success, each `sign_in` refusal, No connection, Something went wrong; default Success). Choices last until changed for the launch; any credentials then give that result.
- While a result other than Success is armed, the pill shows an alert icon and the menu opens with "Next sign-in will fail: <result>".
- When signed in, **Switch persona** signs in as another persona directly.

**Release builds:** `Dev-Release` compiles `NoDevTools` instead: no window, no pill, no tracking, and no file from `DevTools/`. Check a release binary with `nm` for `DevTools` symbols: only `NoDevTools` may appear.

## Design

`ParkHill/Design/Theme.swift` holds the Park Hill tokens from the wireframes: colors with light and dark values, the serif used for titles and headings, and styles for system buttons and text fields. Brand comes through color and type on system components (guide 5.5); there are no custom controls. Headings use the iOS system serif until the brand fonts are bundled.

## Tests

```
xcodebuild -scheme ParkHill-Mock -destination 'platform=iOS Simulator,name=iPhone 16' test
xcodebuild -scheme ParkHill-Dev  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

| Folder | Runs in | Needs |
|---|---|---|
| `ParkHillTests/Services/`, `Auth/`, `Navigation/`, top level | Mock and Dev | Nothing. Supabase services are tested against a stubbed transport and in-memory session storage |
| `ParkHillTests/Mocks/` | Mock | Nothing |
| `ParkHillTests/DevTools/` | Mock and Dev-Debug | Nothing |
| `ParkHillUITests/Mock/` | Mock | Nothing. UI tests for the dev tools pill and menu, and sign-in through the mock menu |
| `ParkHillUITests/Dev/` | Dev | Local Supabase, reset recently: each run adds one failed sign-in for `admin`, and 5 within 15 minutes lock it |
| `ParkHillTests/Integration/` | Dev | The configured backend running: `cd backend && supabase start && supabase db reset`. Persona credentials come from the bundled `contract/seed/dataset.json` |

Client CI runs Mock only (guide 6), so run the Dev tests locally before merging changes to `/ios`, `/backend` or `/contract`:

```
make test-dev
```

It starts and resets local Supabase (Docker must be running), then runs the Dev unit, integration and UI tests on an available iPhone simulator.

### CI

`.github/workflows/ios.yml` runs on ready (not draft) PRs that change `/ios`, `/contract` or `/backend`, on `macos-26` with Xcode 26.5 and XcodeGen 2.46.0:

| Step | Script or command |
|---|---|
| No build-configuration branching | `scripts/check_sources.sh` (also run by the pre-push hook) |
| Mock unit and UI tests | `xcodebuild -scheme ParkHill-Mock … test` |
| No mock or dev tools code in the release build | Builds `Dev-Release` from clean derived data, then `scripts/check_release_build_log.sh <build log>` (no `Mocks/` or `DevTools/` source compiled) and `scripts/check_release_binary.sh <ParkHill.app>` (no such symbols) |

`scripts/simulator.sh` prints an available iPhone simulator's id, for `-destination "id=…"`.

## Rules

- No `#if` on configuration and no runtime environment checks in app code.
- Mock-only code lives under `ParkHill/Mocks/`. It is compiled only in `Mock-Debug` and never in any Release configuration.
- Dev tools code lives under `ParkHill/DevTools/`. It is compiled only in debug configurations and never in any Release configuration.
- Only the service layer imports the Supabase SDK or builds requests.
- Edit `project.yml` and the xcconfigs, never the generated project.
- Backend function names and screen keys come from the generated `ContractNames.swift`, never string literals.
