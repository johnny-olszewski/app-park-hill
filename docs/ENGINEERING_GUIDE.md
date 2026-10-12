# Park Hill App: Engineering Guide

Status: v0.2 (planning). This document governs every task. If a task conflicts with this guide, the guide wins until it is changed in its own PR.

## 1. Goals

1. **Iteration velocity over release cadence.** Anything that can change without an app release should be able to.
2. **Remote driven, natively rendered.** The backend decides what is shown and where taps go. Clients decide how it looks, using native components. No webviews as the norm.
3. **Scalable by configuration.** New tabs, screens, environments and roles are added by extending config and registries, not by adding conditionals.
4. **Two clients, one contract.** iOS (SwiftUI) and Android (Kotlin, Compose) are built in parallel against the same backend contract and the same fixtures.

## 2. Responsibility split

| Concern | Backend | Client |
|---|---|---|
| User based logic (roles, permissions, what a user sees) | Owns | Never re-implements |
| Strings, including error messages | Returns final localized text for the requested locale | Displays as given. Bundles only the strings needed when the backend is unreachable |
| Images | Returns image keys | Resolves keys to assets through an `AssetProvider` |
| Flow and screens | Returns screen keys and each screen's data | Maps a screen key to a native screen through a registry |
| Layout, styling, animation | Never | Owns |
| Navigation mechanics (stacks, modals, tab bar) | Never | Owns, through coordinators |
| Security | Enforces on every operation (RLS, function checks) | Treats its UI as possibly stale |

Rule of thumb: if changing it should not need a release, it belongs to the backend. If it is about pixels or platform conventions, it belongs to the client.

Two further principles:

1. **Navigation targets come from the backend** in each action, so they can change without a release, provided the target screen already exists in the app.
2. **The UI is driven by the user's actions.** The backend includes a button, row or capability only when the user may use it; the client renders what it receives. Server-side checks still apply to every request.

## 3. Repository

Monorepo.

```
/backend     Supabase project: migrations, seed, Edge Functions, tests
/contract    API contract docs, JSON fixtures and personas (single source of truth for both clients)
/ios         SwiftUI app
/android     Kotlin + Compose app
/docs        This guide, the task template, the backlog, epics, specs, tasks
/.github     GitHub Actions workflows and the pull request template
```

A contract change lands in one PR: migration, fixture, and both client models together.

## 4. Backend

- Platform: Supabase. Local Supabase (CLI) is the only instance for now. It is also the permanent target for automated tests in GitHub Actions.
- API style: Postgres RPC functions returning JSON, called through PostgREST. Edge Functions only where a task justifies one. Justified so far: `sign_in` (see `specs/AUTH.md`).
- All schema changes are migrations. Nothing is configured by hand in a dashboard.
- **App configuration is migration data; seed is test data.** Screens, strings and tabs go in migrations so they reach hosted projects. `seed.sql` holds only test accounts and test content, and never reaches a hosted project.
- Backend tests are pgTAP; Edge Functions have their own tests.

### 4.1 Contract

**Screen envelope.** The one shape for any screen's content, wherever it comes from:

```json
{ "key": "auth.sign_in", "data": { }, "toolbar": [ ] }
```

`toolbar` is optional (added in EP-03; backward compatible). Each item has `id`, `label`, `icon_key` and an `action`.

**Actions** are how anything tappable is described: `navigate` (`screen_key`, `params`, `presentation`: `push`, `sheet`, `full_screen_cover`) and `call` (backend `function`, `params`, optional backend-written `confirm`, `on_success`: `refresh`, `dismiss`, `none`). Either may carry `role: destructive`. Details in `specs/COMMUNITY.md` 3.

**Screens, not views.** The backend knows screens; each screen's data model carries everything that screen needs. Shared data types (for example `GroupRow`) are defined once and embedded in several screens. Views are client components for consistency and reuse, invisible to the backend.

**Screen keys** are lowercase and dot separated. A key ending in `.mock` is registered only in the Mock configuration and is never returned by the real backend.

**Entry points:**

| Function | Caller | Returns |
|---|---|---|
| `get_entry(p_locale)` | Signed out (`anon`) | The signed-out entry screen envelope. Today always `auth.sign_in` |
| `get_screen(p_key, p_locale, p_params)` | Depends on the screen | One screen envelope. Used for refresh and for screens reached by navigation |
| `get_tabs(p_locale)` | Signed in only | Tabs in order, each with its root screen envelope embedded (SUP-008) |

Contract rules:

1. Changes are additive. Fields are never removed or repurposed. A breaking change is a new function or a new screen key.
2. Clients ignore unknown fields.
3. Clients drop anything with an unknown screen key and log it. The backend may ship ahead of clients.
4. One screen key maps to exactly one data model. Every variant of a screen is expressible in that one model, except mock variants, which have their own key.
5. Unknown locale falls back to `en`.
6. `/contract/fixtures` holds a JSON example of every response. Client mocks and client decoding tests read these files. Backend tests assert the live functions match their shape.

### 4.2 Standard request headers

Every request from a production service class carries `X-App-Config`, `X-App-Platform`, `X-App-Version` and `Accept-Language`. They are labels for logging and diagnostics, never used for access decisions. Details in `specs/AUTH.md` 5.6.

## 5. Clients

### 5.1 Layers

```
App composition root  ->  Coordinators  ->  Screens (views + view models)
                              |                     |
                        ScreenRegistry     AuthService      BackendService
                                                |                 |
                                   Supabase* classes (share one Supabase client)
                                   Mock* classes (share one current persona)
```

- **Screens** render one data model. They know nothing about navigation, the network or other screens.
- **Coordinators** own navigation. The app coordinator owns launch, the signed-out and signed-in states, and (later) the tab bar. One tab coordinator per tab owns that tab's stack (iOS: `NavigationStack`; Android: Navigation Compose).
- **ScreenRegistry** maps screen key to a screen factory. Adding a screen is registering one entry. No switch statements over screen keys scattered through the code.
- **AuthService** owns sign-in, session and sign-out. **BackendService** is the only path to backend data. Screens and coordinators depend on these abstractions, never on Supabase types.
- **AssetProvider** resolves image keys. First implementation reads bundled assets and returns a defined fallback for unknown keys.

### 5.2 Build configurations and services

| Config | Service classes | Backend | Intent |
|---|---|---|---|
| Mock | `MockAuthService`, `MockBackendService` | None. Reads contract fixtures; signs in as a chosen persona | App runs fully standalone: UI work, previews, demos, UI tests with no backend |
| Dev | `SupabaseAuthService`, `SupabaseBackendService` | Whatever the config names. Default: local Supabase | Real end to end path on a developer machine and in CI |

Later environments (QA, Prod) are added by adding a config file that reuses the Supabase classes with different values. No code changes.

Rules:

1. **Selection is at build time.** Each configuration compiles in exactly one binding file that declares the service types (typealiases) and environment values.
2. **No branching on environment.** No `#if`, no `BuildConfig.FLAVOR` or `BuildConfig.DEBUG` checks, no runtime environment switch in app code. The build system chooses which files are compiled.
   - iOS: project generated by XcodeGen from `ios/project.yml`; per-configuration `.xcconfig` files; mock sources and the non-selected binding are excluded via `EXCLUDED_SOURCE_FILE_NAMES`.
   - Android: product flavors with flavor source sets (`src/mock`, `src/dev`), each providing the binding.
3. **Mock and debug code never ships.** It lives where release configurations do not compile it, including `.mock` screens. CI proves it on the release artifact.
4. **Credentials:** any Supabase-backed build needs a URL and key. Committed config files hold the local Supabase values. An optional gitignored override file per developer replaces them. Hosted values come from CI secrets. No hosted key is ever committed.
5. Every non-release build shows which backend it targets.

### 5.3 Launch, cache and failure

1. Launch restores the session (`specs/AUTH.md` 4.1).
2. Signed out: call `get_entry`, render the screen, cache the envelope per locale as last good.
3. Signed in: show the signed-in destination (placeholder until IOS-008 and AND-008, then tabs via `get_tabs`, cached the same way).
4. Fetch failure with a cache: render the cache. Without a cache: full screen error with retry, using bundled strings.
5. Unknown screen keys are dropped. If nothing usable remains, treat as failure with no cache: show the error screen with retry, even when a cached copy exists.
6. Return to foreground refetches and applies changes.
7. Sign-out deletes all user data on the device, including caches.
8. A request refused as unauthorized gets one silent renewal and retry; if still refused, the user is signed out and returned to sign-in. Network failures never sign anyone out (`specs/AUTH.md` 4.3).
9. **Lost access:** a `dismiss` closes a pushed screen and refreshes the one below (refreshes in place on a root). A refresh refused with `screen_unavailable` closes the screen, refreshes the one below and shows the backend's message.
10. Every screen is cached per screen key and params as last good; pull to refresh refetches it.

### 5.4 Platform floor

iOS 17. Android API 26. English is the only seeded language; locale is passed on every call from the start.

### 5.5 Native platform feel

Each client uses its platform's own components and conventions. The backend says what a thing means (a tab, a toolbar item, a message, a destructive action, a presentation hint); each client decides how it looks and behaves. Behavior must match across platforms; presentation is not expected to.

| Need | iOS | Android |
|---|---|---|
| Tabs | System tab bar (`TabView`) | Material navigation bar |
| Screen title and toolbar | Navigation bar, large title on tab roots | Material top app bar |
| Toolbar overflow | System menu | Overflow menu |
| Brief message after something happened (for example lost access) | Alert with one button | `Snackbar` |
| Confirmation before a `call` | Alert | Material alert dialog |
| `sheet` presentation | Sheet with detents | Modal bottom sheet |
| `full_screen_cover` presentation | Full-screen cover with a close button | Full-screen dialog with a close button |
| Swipe to remove | Swipe action | Swipe to dismiss |
| Loading | `ProgressView` | Circular progress indicator |
| Pull to refresh, pickers, switches, text fields, back navigation | System control | Material control |

Rules:

1. Use the system component when one exists. Do not build a custom control to make the platforms look alike.
2. Brand shows through color, type and spacing applied to system components, not through custom chrome.
3. A custom component needs a decision log entry saying why no system component fits.
4. Specs and tasks describe behavior and name the platform pattern for each client. Where they say "match IOS-###" or "match AND-###", that means behavior, not appearance.

## 6. Testing

- Backend: pgTAP per function; Edge Function tests.
- Clients: unit tests for decoding (against contract fixtures), services, coordinators and view models. UI tests for flows.
- **Client CI runs Mock only.** iOS and Android CI never start Supabase. Tests against local Supabase (Dev integration and UI tests) run locally with `make test-dev`, required before merging changes to an app, `/backend` or `/contract`.
- **Backend CI** runs against local Supabase on Linux and owns correctness of logic and permissions.
- **One canonical dataset:** `/contract/seed/dataset.json` holds personas and all seed data. `make seed` generates `seed.sql`; `make fixtures` generates the per-persona mock fixtures from the real backend's output. `make data-check` in CI fails on any drift. Nothing generated is edited by hand.
- Mock fixtures are static: saves in the mock show success but do not persist. Mock UI tests check UI behavior; backend tests check data changes.
- CI (GitHub Actions): starts local Supabase, runs backend tests, builds and tests both clients, verifies mock code is absent from release builds.
- A task is not done until its tests run in CI.

## 7. Working agreements

- **Temporary code** is allowed only when a task says so, and every line carries `TEMPORARY(<epic>): <what removes it>`. The removing task has an AC that a search for the marker finds nothing.


1. Plan before building. Work is grouped into epics (`/docs/epics/EP-##-name.md`), each with a goal, user stories, epic-level acceptance criteria, exit criteria and its task list. Larger features also get a spec in `/docs/specs`. Every piece of work is a task written from `TASK_TEMPLATE.md`, kept flat in `/docs/tasks`, tagged with its epic and listed in `BACKLOG.md`.
2. One task, one PR, one reviewer (Johnny). Tasks are sized for a single agent session.
3. Every task targets one platform, because different developers with different skills may own them. IDs are per platform and sequential: `SUP-###` (backend), `IOS-###`, `AND-###`. iOS and Android tasks for the same behavior are counterparts with matching acceptance criteria. Platform idioms may differ; behavior may not.
4. An agent that finds ambiguity or a conflict with this guide stops and asks. It does not guess and does not expand scope.
5. Decisions that change this guide are recorded in section 8 in the same PR.

### 7.1 Git workflow

The repo is `app-park-hill` on GitHub (private). `main` only changes through merged pull requests.

1. **One branch per task**, created from an up-to-date `main` and named `task/` plus the task file name without `.md`, for example `task/SUP-002-local-supabase`. The `task/` prefix groups task branches; other kinds of branches get their own prefix when needed.
2. **Commits are standalone and logical**, ordered for review. Each does one thing, leaves the repo consistent and reads on its own. Prefer several small commits to one large one. Separate mechanical changes (moves, renames, generated files) from hand-written ones.
3. **Commit message format:**

   ```
   [SUP-002][1/n] Add Supabase CLI project

   - Run supabase init in /backend
   - Pin the API port to 54321 in config.toml
   ```

   - Subject: `[<TASK-ID>][<k>/n] <summary>`. `<k>` numbers the task's commits from 1 in order. `n` is always the literal letter `n`. The summary is a few words in the imperative, usually taken from the task's Scope.
   - Body: a blank line, then a short bulleted list of brief details.
   - No mention of tools, assistants or agents, and no co-author or "generated with" trailers.
4. **One pull request per task.** Title `[<TASK-ID>] <task title>`. Body follows `.github/pull_request_template.md`, with the same no-mention rule.
5. **Task status:** the branch's last commit sets the task's status to Done in the task file, its epic and `BACKLOG.md`. Merging the PR makes it true. An open PR is how a task shows as in review.
6. **Merging keeps every commit.** PRs merge with a merge commit; squash and rebase merging are disabled. The branch is deleted on merge.
7. Review changes are new commits continuing the numbering, not rewrites of reviewed commits.
8. The only direct commit to `main` was `[SUP-001][1/n] Add planning docs`, which created it.

## 8. Decision log

| Date | Decision |
|---|---|
| 2026-10-07 | iOS and Android built in parallel |
| 2026-10-07 | Configs: Mock and Dev. QA and Prod deferred, added by config |
| 2026-10-07 | Monorepo |
| 2026-10-07 | Image keys resolve to bundled assets first; remote later behind `AssetProvider` |
| 2026-10-07 | Backend returns resolved localized strings in payloads |
| 2026-10-07 | Launch failure: last good cache, drop unknown screen keys, error with retry when nothing usable |
| 2026-10-07 | Tabs payload embeds each tab's root screen data; shared envelope plus `get_screen` |
| 2026-10-07 | Postgres RPC functions for the API |
| 2026-10-07 | Tasks are agent-run, Markdown in `/docs`; `BACKLOG.md` is the index, tasks are separate files |
| 2026-10-08 | Auth before tabs. Tabs require a signed-in user. Supersedes "no auth in the foundation" |
| 2026-10-08 | Auth decisions per `specs/AUTH.md` section 9 |
| 2026-10-08 | Edge Functions allowed where a task justifies one; `sign_in` is the first |
| 2026-10-08 | App configuration in migrations, test data in seed |
| 2026-10-08 | Dev builds target whatever backend their config names; committed local defaults plus gitignored override |
| 2026-10-08 | Standard request headers on every Supabase call; labels only |
| 2026-10-08 | Screen key naming: lowercase, dotted; `.mock` suffix for mock-only variants |
| 2026-10-09 | One platform per task; IDs `SUP-###`, `IOS-###`, `AND-###`, sequential per platform. Replaces `PH-###` |
| 2026-10-09 | Epics as files in `/docs/epics` with `EP-##` IDs; tasks stay flat in `/docs/tasks` with an Epic field. "Cards" are now called tasks |
| 2026-10-09 | EP-01 Foundation and authentication; EP-02 Tabs |
| 2026-10-10 | Refused-as-unauthorized requests sign the user out after one failed renewal; signed-in functions check the account is active on every call |
| 2026-10-10 | Navigation targets in backend actions; UI driven by the user's actions; screens not views in the contract |
| 2026-10-10 | Envelope gains `toolbar`; actions `navigate` and `call` |
| 2026-10-10 | Lost-access rule: close and refresh below, with a backend message |
| 2026-10-10 | EP-03 Community (specs/COMMUNITY.md, specs/ROLES.md); EP-04 People and roles |
| 2026-10-10 | Fresh launch opens the first tab in backend order. Maximum five tabs: the backend never sends more (database check); clients show at most five. No More tab; users cannot reorder tabs |
| 2026-10-10 | EP-04 renamed People and roles (specs/PEOPLE.md): person detail, profile edit mode, directory in browse, Edit roles. EP-04 follows EP-03 |
| 2026-10-10 | Typed groups with data-driven derived roles; every rule checks a permission, never a role name; one narrow absence check for `directory.always_listed` |
| 2026-10-10 | iOS project generated with XcodeGen from `ios/project.yml`; `.xcodeproj` not committed; `make project` regenerates; version pinned locally and in CI. Chosen over Tuist (heavier than needed, some features tied to a paid service) and a hand-maintained project (agent edits to `project.pbxproj` are error-prone, frequent merge conflicts) |
| 2026-10-10 | Client CI (iOS and Android) runs Mock only; Dev tests are local (`make test-dev`). Chosen over Intel Mac runners with Colima (Apple Silicon runners cannot run Docker) and a self-hosted Mac |
| 2026-10-10 | One canonical dataset generates both the Supabase seed and the mock fixtures; CI fails on drift |
| 2026-10-10 | Repo `app-park-hill` on GitHub. Bundle and application ID root is the placeholder `app.parkhill.placeholder`, defined once per platform. **Must be replaced before the first store upload**, once store listing ownership (church or personal) is decided |
| 2026-10-10 | Between EP-02 and EP-04, sign-out is a hardcoded client toolbar button on Home, marked `TEMPORARY(EP-04)` on every line and removed by IOS-015/AND-015. Tab icons are bundled placeholders until design delivers artwork under the same keys |
| 2026-10-10 | Native platform feel (5.5): each client uses its platform's system components; behavior matches across platforms, presentation does not have to. The lost-access message is an alert on iOS and a `Snackbar` on Android; the custom iOS notice view is dropped |
| 2026-10-12 | Git workflow (7.1): one branch and PR per task, commit subjects `[<TASK-ID>][<k>/n] <summary>` with a bulleted body, no tool or agent mentions, merge commits only. Repo is private and created in SUP-001 |
| 2026-10-12 | 5.3 rule 5: a response with nothing usable (for example an entry screen key this build does not register) shows the error screen even when a cached copy exists. Chosen over falling back to the cache |

## 9. Known risks

- **Placeholder app identifiers:** bundle and application IDs are permanent once published. Replace `app.parkhill.placeholder` before the first store upload.

- **Parallel platforms** double client effort before the paradigm is proven. Mitigation: shared fixtures and paired tasks.
- **Embedded root screen data** makes launch as slow as the slowest tab's query once screens have content. Mitigation: `get_screen` exists, so a tab can switch to lazy loading by returning empty data.
- **Sign-in through our Edge Function** puts passwords through our code and hides client addresses from Supabase's own limits. Mitigation: our own attempt limiting, no body logging, tests for both (`specs/AUTH.md` 5.5).
- **Mock fidelity:** client CI trusts the mock. Generated fixtures and `make data-check` keep it faithful; `make test-dev` before merging catches what the mock cannot.
