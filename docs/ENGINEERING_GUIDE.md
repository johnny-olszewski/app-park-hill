# Park Hill App: Engineering Guide

Status: v0.2 (planning). This document governs every task. If a task conflicts with this guide, the guide wins until it is changed in its own PR.

**Purpose.** Park Hill is a real app and also a proving ground. Its architecture (backend-driven, natively rendered clients on Supabase) and the way its work is planned and built (agents implementing tasks from these documents, a person reviewing behavior) are meant to transfer to other businesses and use cases. When two designs both work for Park Hill, prefer the one that generalizes and that an agent can follow from the repo alone.

## 1. Goals

1. **Iteration velocity over release cadence.** Anything that can change without an app release should be able to.
2. **Remote driven, natively rendered.** The backend decides what is shown and where taps go. Clients decide how it looks, using native components. No webviews as the norm.
3. **Scalable by configuration.** New tabs, screens, environments and roles are added by extending config and registries, not by adding conditionals.
4. **Two clients, one contract.** iOS (SwiftUI) and Android (Kotlin, Compose) are built in parallel against the same backend contract and the same mock responses.

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
/contract    API contract docs, JSON mock responses and personas (single source of truth for both clients)
/ios         SwiftUI app
/android     Kotlin + Compose app
/docs        This guide, the task template, the backlog, epics, slices, specs, tasks
/.github     GitHub Actions workflows and the pull request template
/.claude     Project skills for agent sessions (/status, /ready-slice, /implement-slice, /review-pr, /address-review)
/scripts     Workflow scripts: check_commits.sh, record.sh
```

A contract change lands in one PR: migration, mock response, and both client models together.

## 4. Backend

- Platform: Supabase. Local Supabase (CLI) is the only instance for now. It is also the permanent target for automated tests in GitHub Actions.
- API style: Postgres RPC functions returning JSON, called through PostgREST. Edge Functions only where a task justifies one. Justified so far: `sign_in` (see `specs/AUTH.md`).
- All schema changes are migrations. Nothing is configured by hand in a dashboard.
- **App configuration is migration data; seed is test data.** Screens, strings and tabs go in migrations so they reach hosted projects. `seed.sql` holds only test accounts and test content, and never reaches a hosted project.
- Backend tests are pgTAP; Edge Functions have their own tests.
- **Organization scoping.** Every table that holds an organization's data (roles and their assignments, groups, memberships, and later tables like them) has a nullable `org_id uuid` column. It is null in every row while Park Hill is the only organization, and nothing reads it yet. When a second organization or a demo sandbox arrives, an `orgs` table, a foreign key and checks are added without migrating the shape of existing tables.

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
6. `/contract/mock_responses` holds a JSON example of every response. Client mocks and client decoding tests read these files. Backend tests assert the live functions match their shape.
7. Every backend function a client calls and every backend screen key is listed once in `contract/names.json`. Clients use the constants generated from it into `contract/generated/`, never string literals; `make data-check` fails when the list and the backend disagree.
8. Every response a client decodes is described once in `/contract`, in the subset of JSON Schema that `contract/README.md` lists: each backend screen key's data in `contract/screens/`, and the screen envelope, every other response and the types they share in `contract/types/`. `contract/responses.json` maps each mock response to its type. `make models` generates each description's Swift and Kotlin model into `contract/generated/`; no client response type is written by hand. `make data-check` fails when a recorded response or screen does not match its description, a mock response or screen key has no description, or the generated models differ from what is committed. Request bodies and PostgREST error bodies are not described.

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
| Mock | `MockAuthService`, `MockBackendService` | None. Reads mock responses; signs in as a chosen persona | App runs fully standalone: UI work, previews, demos, UI tests with no backend |
| Local | `SupabaseAuthService`, `SupabaseBackendService` | Whatever the config names. Default: local Supabase | Real end to end path on a developer machine and in CI |

Later environments (QA, Prod) are added by adding a config file that reuses the Supabase classes with different values. No code changes.

Rules:

1. **Selection is at build time.** Each configuration compiles in exactly one binding file that declares the service types (typealiases) and environment values.
2. **No branching on environment.** No `#if`, no `BuildConfig.FLAVOR` or `BuildConfig.DEBUG` checks, no runtime environment switch in app code. The build system chooses which files are compiled.
   - iOS: project generated by XcodeGen from `ios/project.yml`; per-configuration `.xcconfig` files; mock sources and the non-selected binding are excluded via `EXCLUDED_SOURCE_FILE_NAMES`.
   - Android: product flavors with flavor source sets (`src/mock`, `src/local`), each providing the binding.
3. **Mock and debug code never ships.** It lives where release configurations do not compile it, including `.mock` screens. CI proves it on the release artifact.
4. **Credentials:** any Supabase-backed build needs a URL and key. Committed config files hold the local Supabase values. An optional gitignored override file per developer replaces them. Hosted values come from CI secrets. No hosted key is ever committed.
5. Every non-release build shows which environment it targets on every screen (the dev tools pill), with the backend address in the dev tools menu and in the launch log.

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
5. Behavior a system component provides for free is still written down. When one platform gets a behavior from a system component (a presentation's animation, a gesture, content kept in place during a transition), the paired tasks state it as an acceptance criterion on both platforms, so the platform without it builds it explicitly. Example: the iOS full-screen cover slides the entry in and out; Android needed AND-023 to match.

## 6. Testing

- Backend: pgTAP per function; Edge Function tests.
- Clients: unit tests for decoding (against mock responses), services, coordinators and view models. UI tests for flows.
- **Client CI runs Mock only on PRs.** iOS and Android PR checks never start Supabase. They compile the Local tests, so a slip in them fails the PR that made it, and they run the unit tests and the smoke UI tests (7.2 rule 4). Before merging changes to an app, `/backend` or `/contract`, each app's smoke tests against local Supabase run locally with `make test-local-smoke`.
- **Smoke and full UI tests.** Each app lists its smoke UI tests in `smoke-mock.txt` and `smoke-local.txt`: about one per screen's main path, the merge gate. Every other UI test is in the full set, which `.github/workflows/nightly.yml` runs every night (both apps in Mock, Android against local Supabase) and which `make test-full` and `make test-local` run on demand. A nightly failure opens or updates an issue labelled `nightly-failure`. A new UI test joins the smoke list only when it is the one covering a screen's main path.
- **Backend CI** runs against local Supabase on Linux and owns correctness of logic and permissions.
- **One canonical dataset:** `/contract/seed/dataset.json` holds personas and all seed data. `make seed` generates `seed.sql`; `make mock-responses` generates the per-persona mock responses from the real backend's output. `make data-check` in CI fails on any drift. Nothing generated is edited by hand.
- Mock responses are static: saves in the mock show success but do not persist. Mock UI tests check UI behavior; backend tests check data changes.
- CI (GitHub Actions): on PRs, starts local Supabase and runs the backend tests, builds both clients, runs their unit and smoke UI tests, and verifies mock code is absent from release builds; nightly, runs the full UI tests.
- A task is not done until its tests run in CI.

## 7. Working agreements

- **Temporary code** is allowed only when a task says so, and every line carries `TEMPORARY(<epic>): <what removes it>`. The removing task has an AC that a search for the marker finds nothing.


1. Plan before building. Work is grouped into epics (`/docs/epics/EP-##-name.md`), each with a goal, user stories, epic-level acceptance criteria, and exit criteria. Larger features also get a spec in `/docs/specs`. Every piece of work is a task written from `TASK_TEMPLATE.md`, kept flat in `/docs/tasks` and tagged with its epic. Tasks are grouped into slices (7.2). How these files record status and links is in 7.3.
2. One slice, one PR, one reviewer (Johnny). Tasks are sized for a single agent session; a slice is the few tasks that together deliver one testable change in behavior.
3. Every task targets one platform, because different developers with different skills may own them. IDs are per platform and sequential: `SUP-###` (backend), `IOS-###`, `AND-###`. iOS and Android tasks for the same behavior are counterparts with matching acceptance criteria. Platform idioms may differ; behavior may not.
4. An agent that finds ambiguity or a conflict with this guide stops and asks. It does not guess and does not expand scope.
5. Decisions that change this guide are recorded in section 8 in the same PR.

### 7.1 Git workflow

The repo is `app-park-hill` on GitHub (private). `main` only changes through merged pull requests.

1. **One branch per slice** (7.2), created from an up-to-date `main` and named `slice/` plus the slice ID and a short kebab-case name, for example `slice/EP-06.B-mock-sign-in`. Other kinds of branches get their own prefix (planning: rule 9; chores: rule 12). Work before 2026-10-15 used one `task/<task file name>` branch per task.
2. **Commits are standalone and logical**, ordered for review. Each does one thing, leaves the repo consistent and reads on its own. Prefer several small commits to one large one. Separate mechanical changes (moves, renames, generated files) from hand-written ones.
3. **Commit message format:**

   ```
   [SUP-002][1/n] Add Supabase CLI project

   - Run supabase init in /backend
   - Pin the API port to 54321 in config.toml
   ```

   - Subject: `[<TASK-ID>][<k>/n] <summary>`. `<k>` numbers the task's commits from 1 in order. `n` is always the literal letter `n`. The summary is a few words in the imperative, usually taken from the task's Scope.
   - Body: a blank line, then a short bulleted list of brief details.
   - No mention of tools, assistants or agents, and no co-author or "generated with" trailers. The same holds for everything posted under a person's account (PR bodies, replies); only the automated reviewer's own comments, from its bot account, are exempt (rule 11).
   - On a slice branch each task keeps its own numbering, and one task's commits are finished before the next task's begin.
4. **One pull request per slice.** Title `[<slice ID>] <slice title>`. Body follows `.github/pull_request_template.md`, with the same no-mention rule.
5. **Status:** each task's last commit sets `status: Done` in its task file. The branch's last commit, `[<slice ID>] Mark <slice ID> done`, sets `status: Done` in the slice file. Merging the PR makes them true. An open PR is how a slice and its tasks show as in review.
6. **Merging keeps every commit.** PRs merge with a merge commit; squash and rebase merging are disabled. The branch is deleted on merge.
7. Review changes are new commits continuing the numbering, not rewrites of reviewed commits.
8. The only direct commit to `main` was `[SUP-001][1/n] Add planning docs`, which created it.
9. **Planning branches.** Changes that only add or revise epics, slices, specs, tasks, the backlog or this guide, without implementing a task, use a branch named `plan/` plus a short kebab-case name, for example `plan/contract-names-and-mock-menu`. One planning branch and PR may cover several epics. Commits are `[PLAN][<k>/n] <summary>`, numbered across the branch; the PR title is `[PLAN] <summary>`, and the PR template's task link and checklist are adapted to the epics it changes. A planning PR sets no task to Done. A slice's readiness check is the exception: it goes on the slice branch (7.2 rule 7).
10. **Checks.** CI reports on every ready pull request; draft PRs skip the macOS job. Never merge a PR with a failing or pending check. Branch protection is not available for a private repo on the free plan, so this is a rule, not a setting. `.githooks/pre-push` runs the fast checks before each push; enable it once per clone with `git config core.hooksPath .githooks`.

11. **Automated review and fixes.** `.github/workflows/review.yml` reviews every PR once when it is opened ready or marked ready, following `.claude/skills/review-pr/SKILL.md`: the guide's rules for every PR, plus the slice or plan for `slice/` and `plan/` branches. It posts inline comments, each starting **Must-fix** (breaks a guide rule, an acceptance criterion, the Scope, or is a bug) or **Suggestion**, and one summary comment. It never approves, pushes or merges. The repository owner asks for a re-review by commenting `@claude review`; a re-review checks whether earlier comments were addressed and does not repeat them.
    - When every check has finished, including the review, the session that opened the PR acts on it with `/address-review`: must-fix comments and failing checks are fixed and pushed; suggestions are applied in separate, later commits and listed in a **Suggestions to verify** comment for the reviewer, who reverts any they reject with a new commit. A comment asking to change this guide or to go beyond the Scope waits for the reviewer's decision, whatever its severity.
    - The fix commits follow rule 7. The reviewer still checks the behavior criteria and merges.
    - Setup, once per repository: install the Claude GitHub app and add the `CLAUDE_CODE_OAUTH_TOKEN` secret from `claude setup-token`.
12. **Chore branches.** Changes that neither implement a task nor only plan, such as renames, tooling and other housekeeping, use a branch named `chore/` plus a short kebab-case name, for example `chore/housekeeping`. One chore branch and PR may cover several unrelated items, each in its own commits. Commits are `[CHORE][<k>/n] <summary>`, numbered across the branch; the PR title is `[CHORE] <summary>`, and the PR template's slice, task and behavior sections are replaced by one section per item saying how it was verified. A chore changes no behavior a slice should own and sets no task to Done.

### 7.2 Slices

A slice is the set of tasks, across platforms, that together deliver one change in behavior a person can check: in the app, or for developers (for example a CI check). It is the unit of implementation, review and acceptance. Tasks stay per platform, so each keeps one owner.

1. **One file per slice.** Each slice is a file in `/docs/slices` (7.3): ID (`EP-##.<letter>`, for example `EP-06.B`), a title that states the behavior, behavior acceptance criteria a person checks by using the result, member tasks in implementation order, the slices it depends on, and status. Its epic's Slices section links it and explains the order; `BACKLOG.md` holds the order of all slices. Every task belongs to exactly one slice; a task that delivers behavior on its own is a one-task slice. Tasks Done before slices existed (2026-10-15) belong to their epic without a slice.
2. **Sizing.** Split a behavior into separate slices only where the state between them is worth having on its own; a slice that only prepares for the next is merged into it.
3. **Lockstep.** A slice includes the tasks of every platform its behavior touches (backend, iOS, Android) and is not started until every slice it depends on is Done, so the platforms move together.
   - **Catch-up slices.** A platform that falls behind gets catch-up slices: only its own tasks, with the behavior criteria of the slices they mirror. No new slice starts until every platform has caught up. Android was held back this way until 2026-10-15 while the workflow settled on iOS, and catches up through EP-01.B, EP-01.C and EP-06.C.
4. **Order and checks.** Tasks are implemented in the slice's order, and each check runs at the cheapest point that still catches what it is for:
   - **Every commit builds** (7.1 rule 2): `scripts/check_commits.sh` before pushing compiles each commit's changed apps and their tests and applies its migrations. Commits are not tested one by one.
   - **Every task:** before the next task starts, the unit tests of the platforms it touched run (`make test-unit`; for `/backend` and `/contract`, the backend tests and `make data-check`), and the acceptance criteria they cover are verified.
   - **Merge gate,** once per slice after the last task: every unit and backend test, each app's smoke UI tests in Mock (`make test-smoke`, which CI also runs) and against local Supabase (`make test-local-smoke`), and the release check. A task acceptance criterion that only a UI test or the running app shows is verified here. The runs go in the background while the PR is written.
   - **Nightly:** the full UI suites (6). A UI test outside the smoke set that a slice breaks is found the next morning, not before merging; the reviewer can ask for `make test-full` on a slice that changes shared navigation.
   - **Platforms in parallel.** Once a slice's backend and contract tasks are committed, its iOS and Android tasks depend only on them and touch separate files, so they may run at the same time in two worktrees: the platform the slice lists first on the slice branch, the other on its own branch from it. That branch is then rebased onto the slice branch, so the history keeps the slice's task order and each task's commits together. Only one `make test-local` runs at a time: they share local Supabase. Tasks that must change the contract, mock responses or another platform's files are not split this way.
   - **Recordings.** Each behavior criterion is recorded once, while it is verified, with `scripts/record.sh`: behavior in the apps as a screen recording on iOS and on Android, preferably of a UI test run that shows it, in the build the criterion names (Mock when it names none); a criterion no test shows is driven by hand once, in that build. Behavior for developers (a check, a command) is a terminal transcript. Recordings go in the gitignored `recordings/<slice ID>/` folder, named by criterion, and stay on the implementer's machine for the reviewer; PRs do not link them. Planning PRs have none.
5. **Review.** The PR lists each task with how it was verified, then the slice's behavior criteria as a checklist. The reviewer accepts the slice by checking the behavior criteria, with the recordings to hand; commits stay per task for reading the code.
6. **Status:** Draft, Ready (its readiness check committed, rule 7), In progress, In review (PR open), Done (PR merged).
7. **Readiness check.** A slice is checked against the current code before its tasks are implemented, once every slice it depends on is Done. It is the first step of `/implement-slice` (or `/ready-slice` alone), and its commits come first on the slice branch, with subjects `[<slice ID>][<k>/n] <summary>`, ending with `[<slice ID>][<k>/n] Mark <slice ID> ready`; no separate planning PR. Each task is checked for anything undefined, stale, in conflict, missing on one platform (5.5 rule 5), needing tooling no task builds, assuming test data that does not exist, in the wrong order, or making the slice worth splitting (rule 2). Every finding is settled with the reviewer before any task's code is written, the answers go into the planning docs, and the slice and its tasks are set to Ready. The slice PR lists the findings and how each was settled, and the reviewer reviews them with the code. The implementer still stops and asks about anything the check missed (7 rule 4).

### 7.3 Planning docs

Epics, slices and tasks are Markdown files whose structured facts live once, in YAML frontmatter at the top of the file. The prose below it (goal, scope, acceptance criteria) is for reading; the frontmatter is what views and agents rely on.

1. **One place per fact.** A status, a link or a membership is written in exactly one file and never copied into a table elsewhere. Views are built from the frontmatter, not maintained by hand.
2. **Fields.** Every file has `type` (`epic`, `slice` or `task`), `id`, `title` and `status`. Links are lists of IDs, `[]` when empty, with a `#` comment for any note.
   - Task: `area`, `epic`, `depends_on`, `paired_with`.
   - Slice: `epic`, `tasks` (in implementation order), `depends_on`.
   - Epic: `specs` (paths under `/docs`), `depends_on`, and any other field it needs, such as `design`.
   A task's slice is the slice whose `tasks` list it; it is not repeated in the task.
3. **Order.** `BACKLOG.md` holds the order of slices as a numbered list of links, and nothing else that a frontmatter field holds.
4. **Views.** `docs/backlog.base` is an [Obsidian Bases](https://obsidian.md/help/bases) view of every epic, slice and task by status: open `/docs` as a vault in Obsidian. GitHub shows each file's frontmatter as a table. Agents read the frontmatter directly (`/status`).
5. **New fields** are added to this list, and for tasks to `TASK_TEMPLATE.md`, in the same change, so every file of a type has the same fields.

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
| 2026-10-13 | Park Hill wireframes (EP-01 to EP-04) are the visual reference. iOS applies their tokens (colors, serif headings, button and field styles) to system components from `ios/ParkHill/Design`; headings use the system serif until the brand fonts (Cormorant Garamond, Overpass) are bundled |
| 2026-10-13 | Sign-in messages: `session_ended_message` and `cannot_connect_message` in an inline box above the fields; backend refusals under the password field in the danger color (wireframe proposal) |
| 2026-10-13 | While signed in, return to the foreground calls `whoami()` so a disabled account is signed out on its next foreground, until tabs give the app a backend-driven signed-in screen |
| 2026-10-13 | The signed-out entry is a full-screen cover over the signed-in root (placeholder, then tabs). Sign-in hides it; sign-out and lost access present it. It has no close button: only signing in dismisses it |
| 2026-10-14 | Planning-only changes use `plan/<epic file name>` branches with the epic ID in commit subjects and the PR title (7.1 rule 9) |
| 2026-10-14 | EP-05 Contract names: backend function names and screen keys are listed once in `contract/names.json`; generated constants in `contract/generated/` are compiled by both clients; `make data-check` fails on drift. Generated into `/contract` rather than into each client so the backend task stays within one platform |
| 2026-10-15 | Planning branches (7.1 rule 9) may cover several epics: `plan/<short name>`, commits `[PLAN][<k>/n]`, PR title `[PLAN] <summary>`. Supersedes the 2026-10-14 one-epic-per-plan-branch entry |
| 2026-10-15 | EP-06 Mock menu: Mock shows the production entry screen from its recorded response; `auth.sign_in.mock` and the persona picker are removed. Mock and debug options live in a menu opened by long-pressing a pill at the top of every screen, drawn once in a debug-only overlay window above everything the app presents, never by screens. Per-screen tools are registered by screen key; the screen registry reports the current screen. In Mock, the menu chooses the persona and the next sign-in result. Future demo mode is a real backend session with a private sandbox per demo and never reuses mock code |
| 2026-10-15 | The dev tools pill shows only the environment name (`MOCK`, `DEV`), centered just below the status bar; the full backend address moves to the menu's Build tool. Chosen over the full target text (too wide for the top of the screen) and over top-trailing placement (would block toolbar buttons). 5.2 rule 5 updated |
| 2026-10-15 | Purpose recorded at the top of this guide and in `CLAUDE.md`: Park Hill is also a proving ground for a transferable architecture and agent-driven workflow; prefer designs that generalize |
| 2026-10-15 | Slices (7.2): tasks are grouped by the behavior they deliver; one branch and PR per slice, commits still per task, each task verified before the next, the slice's behavior criteria checked by the reviewer. Replaces one task per branch and PR. Behavior criteria live in a Slices section of each epic |
| 2026-10-15 | Slices are lockstep across platforms and start only when their dependencies are Done. Exception until agents run implementation: Android tasks are left out of slices and Android work waits, while the workflow settles on iOS |
| 2026-10-15 | Slice sizing (7.2 rule 2): split only where the in-between state is worth having on its own; scaffolding-only slices merge into the next. EP-06.A stands alone because Dev builds use the menu without any mock tools |
| 2026-10-15 | Mock sign-in (specs/AUTH.md 5.4): the production `auth.sign_in` with the next result chosen in the dev tools menu; `auth.sign_in.mock` removed. Every `sign_in` refusal is recorded; `unknown` is built from its message because it cannot be triggered. `secondary_actions` is reserved for backend-enabled entries, never mock features |
| 2026-10-15 | Android exception ended: Android starts through catch-up slices (7.2 rule 3) that mirror the iOS slices' behavior criteria: EP-01.B, EP-01.C, EP-06.C. No new feature slice starts until Android is level. CI (EP-01.A) goes first |
| 2026-10-15 | CI checks report on PRs and a red or pending check blocks merging by rule (7.1 rule 10), with a pre-push hook for fast local checks. Chosen over GitHub Pro and over a public repo (branch protection needs one of them). The macOS job runs on ready PRs only, to stay within the free Actions minutes |
| 2026-10-20 | Android dev tools pill lives over the activity's content, added by debug-only lifecycle callbacks. Dialogs and bottom sheets, which are separate windows, cover it while open. Chosen over re-attaching a pill to every window (relies on Android internals) and a system overlay (each tester grants a permission) |
| 2026-10-21 | Behavior a system component provides on one platform is a written acceptance criterion in both paired tasks (5.5 rule 5). Found when Android's entry swapped instantly while iOS's cover slid (AND-023) |
| 2026-10-22 | Sessions start with `/status` and implement with `/implement-slice`, project skills in `.claude/skills/` that follow this guide. Repeatable steps are scripts in `/scripts` (marking Done, checking every commit), not instructions, so they work the same in every session |
| 2026-10-22 | Automated PR review (7.1 rule 11): a GitHub Actions reviewer (`anthropics/claude-code-action`) reviews each PR once when ready, and again on `@claude review`, against this guide and the PR's slice or plan, labelling each comment Must-fix or Suggestion. The PR's session fixes must-fix comments and failing checks, applies suggestions in separate commits for the reviewer to verify, and asks first about guide or Scope changes. The reviewer's bot comments are exempt from the no-mention rule (7.1 rule 3); anything posted under a person's account is not. Chosen over reviewing every push (repeats itself and loops with the fixes), Copilot code review (cannot review against this guide) and hosted review apps (paid for private repos). The prompt is a repo skill, so its general part transfers to other repos |
| 2026-10-22 | Contract names (SUP-019): `contract/names.json` lists every client-called RPC and Edge Function and every backend screen key; `make names` generates `ContractNames.swift` and `ContractNames.kt` (package `app.parkhill.contract`) into `contract/generated/`; `make data-check` checks the list against the database both ways for screens and fails on drift. Contract rule 7 added to 4.1 |
| 2026-10-22 | Screen data descriptions (SUP-020): each backend screen's data is described once in `contract/screens/<key>.schema.json`, a documented subset of JSON Schema; `make models` generates Swift (`Decodable`, `Equatable`) and Kotlin (kotlinx.serialization) models into `contract/generated/`, and `make data-check` validates every recorded screen against its description. A standard-library Python script generates and validates, and refuses keywords outside the subset; keywords are added when a screen first needs them. Chosen over JSON Schema with quicktype (Node, heavier output, no validation), JSON Schema with the `jsonschema` package (first pip dependency) and a format of our own (no tooling, one more format to learn). Comparison in `contract/README.md`. Contract rule 8 added to 4.1 |
| 2026-10-23 | Recordings (7.2 rule 4): every slice's behavior criteria are recorded while they are verified, as iOS and Android screen recordings for app behavior and terminal transcripts for developer behavior, with `scripts/record.sh`, into the gitignored `recordings/<slice ID>/`. They stay local and are not linked from PRs. Earlier slices recorded ad hoc and #29 dropped it; written down so every session does it. Chosen over uploading to PRs (`gh` cannot attach files) and committing them (repository size) |
| 2026-10-23 | Organization scoping (4): tables holding an organization's data get a nullable `org_id`, null for every row for now. Chosen over a required church identifier from the start (an `orgs` table and checks with only one organization) and over adding it later (migrating every table, rule and test after EP-03 and EP-04). Resolves the SUP-009 and SUP-010 open question |
| 2026-10-23 | Chore branches (7.1 rule 12): housekeeping that implements no task and is not planning goes on a `chore/` branch with `[CHORE][<k>/n]` commits, numbered across the branch, and may group several unrelated items. Mirrors planning branches. Chosen over inventing a task for each rename or tooling change (tasks deliver behavior in a slice) |
| 2026-10-23 | "Fixtures" are now called mock responses: `contract/fixtures` became `contract/mock_responses`, `make fixtures` became `make mock-responses`, and client types and tests were renamed to match (`MockResponseStore`, `TestMockResponses`). The files are unchanged: recorded backend responses that the mock builds serve, client decoding tests read and `make data-check` keeps faithful. Earlier decision log rows keep the old word |
| 2026-10-23 | Planning docs (7.3): epics, slices and tasks keep status, links and membership once, in YAML frontmatter; slices moved from epic sections into `/docs/slices`; `BACKLOG.md` keeps only the slice order; `docs/backlog.base` gives an Obsidian view. `scripts/mark_done.py`, which set Done in three tables by regex, is removed: marking Done is one field. Chosen over JSON or YAML data files beside the prose (two files per item that can drift), a generated dashboard (a script to maintain) and GitHub Issues and Projects (the plan would leave the repo) |
| 2026-10-23 | Response descriptions (SUP-022): every response a client decodes is described once, not only screen data. Shared types live in `contract/types/` and are referenced with `$ref`; the screen envelope, `get_tabs`, `whoami` and the `sign_in` responses are types; `contract/responses.json` maps each mock response to its type, and `make data-check` fails on a response with no type. Generated Swift is `Codable, Equatable, Sendable`, so apps cache generated types. Request bodies and PostgREST error bodies stay hand-written. Contract rule 8 widened |
| 2026-10-24 | The Dev environment is now called Local, after the backend it targets by default: `Dev-Debug` and `Dev-Release` became `Local-Debug` and `Local-Release`, the `dev` flavor became `local`, `make test-dev` became `make test-local`, `X-App-Config` sends `local`, and the gitignored overrides are `Local.override.xcconfig` and `local.override.properties`. Client CI now also compiles the Local tests without running them, after a rename slip in Dev-only tests reached `main` unnoticed (#36). Debug and release stay build types and the environment stays a build-time choice (5.2 rule 1); a runtime environment switch was considered and deferred. Earlier decision log rows and Done planning docs keep the old name |
| 2026-10-24 | Faster slices, after EP-03.A took far longer than its tasks suggested: (1) a readiness check (7.2 rule 7) settles every gap between a slice's tasks and the current code before any task's code is written, and is what makes a slice Ready. It is the first step of `/implement-slice`, committed first on the slice branch, so the reviewer sees the plan changes and the code in one PR; chosen over a separate planning PR that must merge first (a second review and a wait for every slice). EP-03.A found its gaps mid-implementation: mock responses with params, the seed's groups, a screen that is a shared type, and a recorded screen the apps did not register yet. (2) Checks run in three tiers (7.2 rule 4): fast checks per commit, unit and backend tests per task, and UI tests, `make test-local` and the release check once per slice. Before, every tier ran per task. (3) A slice's iOS and Android tasks may run in parallel worktrees once its backend and contract tasks are committed, joined by a rebase that keeps the slice's task order. Chosen over smaller slices alone (still serial and re-tested per task), skipping per-commit checks (the history must stay standalone) and separate per-platform PRs (one slice, one PR, 7.1 rule 4) |
| 2026-10-24 | Mock responses for screens with params (SUP-012): `make mock-responses` follows every `navigate` action with params in each persona's recorded responses and records the screen it opens as `get_screen.<key>@<param>=<value>.json`; client mocks look a call up with its params first, then by name alone, and `responses.json` maps the name without params. Chosen over one file per screen key per persona (every row would open the same group in Mock) and over params in subfolders (a second layout for the mocks and the check). A screen whose data is a shared type is an alias screen (`$ref` alone), generated as a typealias, so `community.group` and `community.home`'s `group` part share `GroupDetail` |
| 2026-10-25 | Test tiers (6, 7.2 rule 4): commits only have to build, checked with `scripts/check_commits.sh` building what each commit changed; tasks run the unit tests of the platforms they touched; the merge gate runs every unit and backend test plus a smoke set of UI tests (about one per screen's main path, listed in each app's `smoke-mock.txt` and `smoke-local.txt`) in CI and against local Supabase; the full UI suites run nightly in CI (`nightly.yml`), filing a `nightly-failure` issue on failure. Recordings come from UI test runs where one shows the criterion, recorded once. Replaces running every test per commit and every UI suite per slice, which made EP-03.B take far longer than its code. Chosen over test plans and annotations (one plain list format both apps share) and over running the full suite on PRs only for some paths (every slice touches the shared shell). iOS against local Supabase stays a local run: CI's Mac runners have no Docker |

## 9. Known risks

- **Placeholder app identifiers:** bundle and application IDs are permanent once published. Replace `app.parkhill.placeholder` before the first store upload.

- **Parallel platforms** double client effort before the paradigm is proven. Mitigation: shared mock responses and paired tasks.
- **Embedded root screen data** makes launch as slow as the slowest tab's query once screens have content. Mitigation: `get_screen` exists, so a tab can switch to lazy loading by returning empty data.
- **Sign-in through our Edge Function** puts passwords through our code and hides client addresses from Supabase's own limits. Mitigation: our own attempt limiting, no body logging, tests for both (`specs/AUTH.md` 5.5).
- **Mock fidelity:** client CI trusts the mock. Generated mock responses and `make data-check` keep it faithful; `make test-local` before merging catches what the mock cannot.
