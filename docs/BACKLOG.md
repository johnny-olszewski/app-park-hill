# Park Hill App: Backlog

Index of epics and tasks. Epics live in `epics/`, tasks in `tasks/`, specs in `specs/`. Tasks follow `TASK_TEMPLATE.md` and are governed by `ENGINEERING_GUIDE.md`.

Each task targets one platform: `SUP` (backend), `IOS`, `AND`, numbered sequentially per platform. Platforms can proceed in parallel; follow each task's "Depends on" for cross-platform order.

**Before the first store upload:** replace the placeholder app identifier root (`app.parkhill.placeholder`) on both platforms; see the guide's decision log.

The Status column here mirrors the Status field in each task. Update both in the same change.

Work is implemented and reviewed by slice (guide 7.2): each epic's Slices table groups its tasks by the behavior they deliver. Epics planned before slices existed are divided into slices when their next work is planned.

### Slice order

1. [EP-01.A](epics/EP-01-foundation-and-auth.md#slices): CI for backend and iOS
2. [EP-01.B](epics/EP-01-foundation-and-auth.md#slices): Android catch-up, launch and CI
3. [EP-01.C](epics/EP-01-foundation-and-auth.md#slices): Android catch-up, sign-in
4. [EP-06.C](epics/EP-06-mock-menu.md#slices): Android catch-up, dev tools and Mock sign-in
5. [EP-02.A](epics/EP-02-tabs.md#slices): tabs after sign-in, on every platform
6. [EP-05.A](epics/EP-05-contract-names.md#slices): contract names on every platform
7. [EP-05.B](epics/EP-05-contract-names.md#slices): screen data described once and checked
8. [EP-05.C](epics/EP-05-contract-names.md#slices): the apps decode screens with the generated models
9. [EP-05.D](epics/EP-05-contract-names.md#slices): every response described once and checked

Android is level after EP-06.C; new feature slices include every platform.

## [EP-01: Foundation and authentication](epics/EP-01-foundation-and-auth.md)

### Slices

| Slice | Behavior | Tasks, in order | Depends on | Status |
|---|---|---|---|---|
| [EP-01.A](epics/EP-01-foundation-and-auth.md#ep-01a-every-pr-is-checked-automatically) | Every PR runs the backend and iOS checks automatically | SUP-004, SUP-007, IOS-004, IOS-007 | None | Done |
| [EP-01.B](epics/EP-01-foundation-and-auth.md#ep-01b-android-launches-to-the-backend-driven-entry) | Android launches to the backend-driven entry, with CI (catch-up) | AND-001, AND-002, AND-003, AND-004 | EP-01.A | Done |
| [EP-01.C](epics/EP-01-foundation-and-auth.md#ep-01c-android-sign-in-matches-ios) | Android sign-in matches iOS (catch-up) | AND-005, AND-006, AND-007 | EP-01.B | Done |


### Milestone A: foundation

#### Backend (SUP)

| Task | Depends on | Status |
|---|---|---|
| [SUP-001: Create the monorepo scaffold](tasks/SUP-001-monorepo-scaffold.md) | None | Done |
| [SUP-002: Set up the local Supabase backend project](tasks/SUP-002-local-supabase.md) | SUP-001 | Done |
| [SUP-003: Define the screen contract and implement get_entry and get_screen](tasks/SUP-003-screen-contract.md) | SUP-002 | Done |
| [SUP-004: Add backend CI on GitHub Actions against local Supabase](tasks/SUP-004-backend-ci.md) | SUP-003 | Done |

#### iOS (IOS)

| Task | Depends on | Status |
|---|---|---|
| [IOS-001: Create the iOS project with Mock and Dev build configurations](tasks/IOS-001-project-and-build-configs.md) | SUP-001 | Done |
| [IOS-002: Build the iOS backend service layer with production and mock implementations](tasks/IOS-002-backend-service-and-mock.md) | SUP-003, IOS-001 | Done |
| [IOS-003: Build the iOS root coordinator, screen registry and backend-driven entry](tasks/IOS-003-root-coordinator-and-registry.md) | IOS-002 | Done |
| [IOS-004: Add iOS CI on GitHub Actions](tasks/IOS-004-ci.md) | IOS-003, SUP-004 | Done |

#### Android (AND)

| Task | Depends on | Status |
|---|---|---|
| [AND-001: Create the Android project with Mock and Dev build variants](tasks/AND-001-project-and-build-variants.md) | SUP-001 | Done |
| [AND-002: Build the Android backend service layer with production and mock implementations](tasks/AND-002-backend-service-and-mock.md) | SUP-003, AND-001 | Done |
| [AND-003: Build the Android root coordinator, screen registry and backend-driven entry](tasks/AND-003-root-coordinator-and-registry.md) | AND-002 | Done |
| [AND-004: Add Android CI on GitHub Actions](tasks/AND-004-ci.md) | AND-003, SUP-004 | Done |

### Milestone B: authentication

#### Backend (SUP)

| Task | Depends on | Status |
|---|---|---|
| [SUP-005: Add profiles, seeded personas and a signed-in check function](tasks/SUP-005-profiles-and-personas.md) | SUP-003 | Done |
| [SUP-006: Build the sign_in Edge Function with backend-decided errors and attempt limiting](tasks/SUP-006-sign-in-function.md) | SUP-005 | Done |
| [SUP-007: Extend backend CI for auth: Edge Function tests and dataset check](tasks/SUP-007-auth-ci.md) | SUP-004, SUP-006 | Done |

#### iOS (IOS)

| Task | Depends on | Status |
|---|---|---|
| [IOS-005: Build the iOS auth service with production and mock implementations](tasks/IOS-005-auth-service.md) | IOS-002, SUP-006 | Done |
| [IOS-006: Build the iOS sign-in flow, mock persona picker and signed-in placeholder](tasks/IOS-006-sign-in-flow.md) | IOS-003, IOS-005 | Done |
| [IOS-007: Run iOS auth UI tests: Mock in CI, Dev locally](tasks/IOS-007-auth-ui-tests-ci.md) | IOS-004, IOS-006 | Done |

#### Android (AND)

| Task | Depends on | Status |
|---|---|---|
| [AND-005: Build the Android auth service with production and mock implementations](tasks/AND-005-auth-service.md) | AND-002, SUP-006 | Done |
| [AND-006: Build the Android sign-in flow and signed-in placeholder](tasks/AND-006-sign-in-flow.md) | AND-003, AND-005 | Done |
| [AND-007: Run Android auth UI tests: Mock in CI, Dev locally](tasks/AND-007-auth-ui-tests-ci.md) | AND-004, AND-006 | Done |

## [EP-02: Tabs](epics/EP-02-tabs.md)

### Slices

| Slice | Behavior | Tasks, in order | Depends on | Status |
|---|---|---|---|---|
| [EP-02.A](epics/EP-02-tabs.md#ep-02a-signed-in-people-see-the-backends-tabs) | Signed-in people see the backend's tabs on iOS and Android | SUP-008, IOS-008, AND-008, AND-023 | EP-06.C | Done |

### Backend (SUP)

| Task | Depends on | Status |
|---|---|---|
| [SUP-008: Implement get_tabs for signed-in users](tasks/SUP-008-get-tabs.md) | SUP-005 | Done |

### iOS (IOS)

| Task | Depends on | Status |
|---|---|---|
| [IOS-008: Build the iOS backend-fed tab shell and remove the placeholder](tasks/IOS-008-tab-shell.md) | IOS-006, IOS-021, SUP-008 | Done |

### Android (AND)

| Task | Depends on | Status |
|---|---|---|
| [AND-008: Build the Android backend-fed tab shell and remove the placeholder](tasks/AND-008-tab-shell.md) | AND-006, AND-021, SUP-008 | Done |
| [AND-023: Animate the Android entry in and out like iOS](tasks/AND-023-entry-transitions.md) | AND-008 | Done |

## [EP-03: Community](epics/EP-03-community.md)

### Backend (SUP)

| Task | Depends on | Status |
|---|---|---|
| [SUP-009: Add data-driven roles, permissions and the permission check](tasks/SUP-009-roles-and-permissions.md) | SUP-005 | Draft |
| [SUP-010: Add the groups schema, server-side rules and group personas](tasks/SUP-010-groups-schema-and-seed.md) | SUP-009 | Draft |
| [SUP-011: Extend the screen contract with toolbar, actions and shared group types](tasks/SUP-011-toolbar-actions-and-shared-types.md) | SUP-003 | Draft |
| [SUP-012: Build the Community screens: home, browse and group detail](tasks/SUP-012-community-screens.md) | SUP-008, SUP-010, SUP-011 | Draft |
| [SUP-013: Build the people picker and create-group screens](tasks/SUP-013-picker-and-create-screens.md) | SUP-012 | Draft |
| [SUP-014: Build the group operations with permission checks and all-or-nothing saves](tasks/SUP-014-group-operations.md) | SUP-010, SUP-011 | Draft |

### iOS (IOS)

| Task | Depends on | Status |
|---|---|---|
| [IOS-009: Build iOS toolbar, action handling and shared screen behavior](tasks/IOS-009-actions-toolbar-and-screen-infrastructure.md) | IOS-008, SUP-011 | Draft |
| [IOS-010: Build the iOS Community home and Browse all groups screens](tasks/IOS-010-community-home-and-browse.md) | IOS-009, SUP-012 | Draft |
| [IOS-011: Build the iOS group detail view and screen](tasks/IOS-011-group-detail.md) | IOS-010, SUP-012, SUP-014 | Draft |
| [IOS-012: Build the iOS people picker and create-group form](tasks/IOS-012-people-picker-and-create-group.md) | IOS-009, SUP-013 | Draft |
| [IOS-013: Build iOS group edit mode with batched changes](tasks/IOS-013-group-edit-mode.md) | IOS-011, IOS-012, SUP-014 | Draft |
| [IOS-014: Add iOS Community UI tests per persona against local Supabase (local)](tasks/IOS-014-community-ui-tests-per-persona.md) | IOS-013, SUP-014 | Draft |

### Android (AND)

| Task | Depends on | Status |
|---|---|---|
| [AND-009: Build Android toolbar, action handling and shared screen behavior](tasks/AND-009-actions-toolbar-and-screen-infrastructure.md) | AND-008, SUP-011 | Draft |
| [AND-010: Build the Android Community home and Browse all groups screens](tasks/AND-010-community-home-and-browse.md) | AND-009, SUP-012 | Draft |
| [AND-011: Build the Android group detail view and screen](tasks/AND-011-group-detail.md) | AND-010, SUP-012, SUP-014 | Draft |
| [AND-012: Build the Android people picker and create-group form](tasks/AND-012-people-picker-and-create-group.md) | AND-009, SUP-013 | Draft |
| [AND-013: Build Android group edit mode with batched changes](tasks/AND-013-group-edit-mode.md) | AND-011, AND-012, SUP-014 | Draft |
| [AND-014: Add Android Community UI tests per persona against local Supabase (local)](tasks/AND-014-community-ui-tests-per-persona.md) | AND-013, SUP-014 | Draft |

## [EP-04: People and roles](epics/EP-04-people-and-roles.md)

### Backend (SUP)

| Task | Depends on | Status |
|---|---|---|
| [SUP-015: Extend profiles with phone, photo and directory visibility](tasks/SUP-015-people-profiles-and-visibility.md) | SUP-010 | Draft |
| [SUP-016: Build the person detail screen and the account toolbar item](tasks/SUP-016-person-screen-and-account-item.md) | SUP-012, SUP-015 | Draft |
| [SUP-017: Add the directory part to Browse and the browse button rule](tasks/SUP-017-directory-in-browse.md) | SUP-015, SUP-016 | Draft |
| [SUP-018: Build profile and role saving with all-or-nothing batches](tasks/SUP-018-profile-and-role-operations.md) | SUP-015 | Draft |

### iOS (IOS)

| Task | Depends on | Status |
|---|---|---|
| [IOS-015: Build the iOS person detail screen and account entry](tasks/IOS-015-person-detail.md) | IOS-011, SUP-016 | Draft |
| [IOS-016: Build iOS profile edit mode with photo upload](tasks/IOS-016-profile-edit-mode.md) | IOS-015, SUP-018 | Draft |
| [IOS-017: Add the iOS directory and segmented control to Browse](tasks/IOS-017-browse-segments-and-directory.md) | IOS-010, SUP-017 | Draft |
| [IOS-018: Build the iOS Edit roles half sheet](tasks/IOS-018-edit-roles-sheet.md) | IOS-015, SUP-018 | Draft |
| [IOS-019: Add iOS people and directory UI tests per persona against local Supabase (local)](tasks/IOS-019-people-ui-tests-per-persona.md) | IOS-016, IOS-017, IOS-018, SUP-018 | Draft |

### Android (AND)

| Task | Depends on | Status |
|---|---|---|
| [AND-015: Build the Android person detail screen and account entry](tasks/AND-015-person-detail.md) | AND-011, SUP-016 | Draft |
| [AND-016: Build Android profile edit mode with photo upload](tasks/AND-016-profile-edit-mode.md) | AND-015, SUP-018 | Draft |
| [AND-017: Add the Android directory and segmented control to Browse](tasks/AND-017-browse-segments-and-directory.md) | AND-010, SUP-017 | Draft |
| [AND-018: Build the Android Edit roles half sheet](tasks/AND-018-edit-roles-sheet.md) | AND-015, SUP-018 | Draft |
| [AND-019: Add Android people and directory UI tests per persona against local Supabase (local)](tasks/AND-019-people-ui-tests-per-persona.md) | AND-016, AND-017, AND-018, SUP-018 | Draft |

## [EP-05: Contract names](epics/EP-05-contract-names.md)

### Slices

| Slice | Behavior | Tasks, in order | Depends on | Status |
|---|---|---|---|---|
| [EP-05.A](epics/EP-05-contract-names.md#ep-05a-a-misspelled-name-fails-the-build-or-the-data-check) | A misspelled backend function name or screen key fails the build or `make data-check` on every platform | SUP-019, IOS-020, AND-020 | EP-02.A | Done |
| [EP-05.B](epics/EP-05-contract-names.md#ep-05b-screen-data-is-described-once-and-checked) | Each backend screen's data is described once in `/contract`, client models are generated from it, and `make data-check` fails when a response does not match | SUP-020 | EP-05.A | Draft |
| [EP-05.C](epics/EP-05-contract-names.md#ep-05c-the-apps-decode-screens-with-the-generated-models) | Both apps decode every screen with the generated models, and no screen model is written by hand | IOS-023, AND-024 | EP-05.B | Draft |
| [EP-05.D](epics/EP-05-contract-names.md#ep-05d-every-response-is-described-once-and-checked) | Every response a client decodes is described once, checked by `make data-check`, and decoded with generated types in both apps | SUP-022, IOS-024, AND-025 | EP-05.C | Draft |

### Backend (SUP)

| Task | Depends on | Status |
|---|---|---|
| [SUP-019: Define backend function names and screen keys once and generate client constants](tasks/SUP-019-shared-contract-names.md) | SUP-006, SUP-008 | Done |
| [SUP-020: Choose and prove how screen data models are defined once and generated for both clients](tasks/SUP-020-screen-models.md) | SUP-019 | Draft |
| [SUP-022: Describe the non-screen responses and the screen envelope once](tasks/SUP-022-response-descriptions.md) | SUP-020 | Draft |

### iOS (IOS)

| Task | Depends on | Status |
|---|---|---|
| [IOS-020: Use the generated contract names in the iOS app](tasks/IOS-020-contract-names.md) | SUP-019, IOS-008 | Done |
| [IOS-023: Decode screens with the generated models in the iOS app](tasks/IOS-023-generated-screen-models.md) | SUP-020 | Draft |
| [IOS-024: Decode every backend response with the generated types in the iOS app](tasks/IOS-024-generated-response-types.md) | SUP-022, IOS-023 | Draft |

### Android (AND)

| Task | Depends on | Status |
|---|---|---|
| [AND-020: Use the generated contract names in the Android app](tasks/AND-020-contract-names.md) | SUP-019, AND-008 | Done |
| [AND-024: Decode screens with the generated models in the Android app](tasks/AND-024-generated-screen-models.md) | SUP-020 | Draft |
| [AND-025: Decode every backend response with the generated types in the Android app](tasks/AND-025-generated-response-types.md) | SUP-022, AND-024 | Draft |

## [EP-06: Mock menu](epics/EP-06-mock-menu.md)

### Slices

| Slice | Behavior | Tasks, in order | Depends on | Status |
|---|---|---|---|---|
| [EP-06.A](epics/EP-06-mock-menu.md#ep-06a-dev-tools-over-the-app) | Debug builds show a pill on every screen that opens a dev tools menu | IOS-021 | None | Done |
| [EP-06.B](epics/EP-06-mock-menu.md#ep-06b-mock-testers-sign-in-through-the-menu) | Mock testers sign in through the menu, as any persona, with any result | SUP-021, IOS-022 | EP-06.A | Done |
| [EP-06.C](epics/EP-06-mock-menu.md#ep-06c-android-dev-tools-and-mock-sign-in) | Android dev tools and Mock sign-in through the menu (catch-up) | AND-021, AND-022 | EP-06.B, EP-01.C | Done |

### Backend (SUP)

| Task | Depends on | Status |
|---|---|---|
| [SUP-021: Record every sign-in refusal and update the auth spec for the mock menu](tasks/SUP-021-sign-in-refusal-responses.md) | SUP-006 | Done |

### iOS (IOS)

| Task | Depends on | Status |
|---|---|---|
| [IOS-021: Build the iOS dev tools overlay: top pill, menu, screen tracker and tool registry](tasks/IOS-021-dev-tools-overlay.md) | IOS-006 | Done |
| [IOS-022: Show the production sign-in in Mock with persona and result tools](tasks/IOS-022-mock-sign-in-tools.md) | IOS-021, SUP-021 | Done |

### Android (AND)

| Task | Depends on | Status |
|---|---|---|
| [AND-021: Build the Android dev tools overlay: top pill, menu, screen tracker and tool registry](tasks/AND-021-dev-tools-overlay.md) | AND-006 | Done |
| [AND-022: Show the production sign-in in Mock with persona and result tools](tasks/AND-022-mock-sign-in-tools.md) | AND-021, SUP-021 | Done |
