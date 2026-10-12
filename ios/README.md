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

**Mock** makes no network connections and needs no backend. Services read the contract fixtures and sign in as a chosen persona. Use it for UI work, previews, demos and UI tests. Mock never ships, so it has no Release configuration.

**Dev** is the real end-to-end path. Its backend URL and anon key come from `Config/Dev.xcconfig` and default to local Supabase at `http://127.0.0.1:54321` (start it from `/backend`). No hosted project is used unless you override it.

At launch every build logs its environment and backend target, for example `Environment Dev, backend http://127.0.0.1:54321`. The value is available as `ServiceBinding.environment.backendLabel`.

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
| `Config/App.xcconfig` | App target settings. Excludes every `ServiceBinding+*.swift` and everything under `Mocks/`, then includes `ServiceBinding+$(APP_ENVIRONMENT).swift` |
| `Config/Mock.xcconfig` | `APP_ENVIRONMENT = Mock`; the one configuration that compiles `Mocks/` |
| `Config/Dev.xcconfig` | `APP_ENVIRONMENT = Dev`, backend values, optional `Dev.local.xcconfig` |
| `Config/Dev-Info.plist` | Puts the backend values into Info.plist, plus the local HTTP exception (`NSAllowsLocalNetworking`), which exists only in Dev |
| `ParkHill/Environment/ServiceBinding+Dev.swift` | Dev binding |
| `ParkHill/Mocks/ServiceBinding+Mock.swift` | Mock binding |

### Adding an environment

For example, QA, reusing the Supabase services with different values:

1. Add `Config/QA.xcconfig`: include `App.xcconfig`, set `APP_ENVIRONMENT = QA`, `APP_ENVIRONMENT_ID = qa`, `APP_DISPLAY_NAME`, `BACKEND_URL`, `BACKEND_ANON_KEY` and `INFOPLIST_FILE = Config/QA-Info.plist`.
2. Add `Config/QA-Info.plist` with the `BackendURL` and `BackendAnonKey` keys only. No HTTP exception: shipping environments use TLS.
3. Add `ParkHill/Environment/ServiceBinding+QA.swift`, declaring the environment like the Dev binding.
4. In `project.yml`, add `QA-Debug: debug` and `QA-Release: release` under `configs`, map them in both `configFiles` sections, and add a `ParkHill-QA` scheme.
5. `make project`.

Hosted values come from CI secrets, never from committed files.

## Rules

- No `#if` on configuration and no runtime environment checks in app code.
- Mock-only code lives under `ParkHill/Mocks/`. It is compiled only in `Mock-Debug` and never in any Release configuration.
- Edit `project.yml` and the xcconfigs, never the generated project.
