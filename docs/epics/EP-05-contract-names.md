# EP-05: Contract names

| Field | Value |
|---|---|
| Status | Draft |
| Spec | None (the guide's 4.1 is updated by SUP-019) |
| Previous epic | [EP-04: People and roles](EP-04-people-and-roles.md) |

## Goal

Backend function names, screen keys and screen data models are written once, in `/contract`, and every platform uses them. A misspelled or missing name fails a build or `make data-check`, not a running app. Independent of EP-02 to EP-04; it can run once the EP-01 auth tasks it touches are done on each platform.

## Out of scope

- Mock-only screen keys (`.mock`): they stay in client mock sources.
- Function parameter names.

## User stories (draft)

| # | Story | Epic-level acceptance criteria |
|---|---|---|
| 1 | As a developer, I write a function name or screen key in one place | `contract/names.json` is the only hand-written source; clients use generated constants |
| 2 | As a developer, a misspelled name fails before anyone runs the app | A typo in a client fails its build; a mismatch between the backend and the list fails `make data-check` |
| 3 | As a developer, Mock and Dev cannot disagree on a name | Mock and Supabase services on each platform use the same generated constant for each function |
| 4 | As a developer, I describe a screen's data once and both clients get its model | The approach is chosen and recorded, proven on `auth.sign_in`, and `make data-check` fails when a recorded response does not match its description |

## Exit criteria

1. All EP-05 tasks are Done.
2. No client source outside tests contains a backend function name or backend screen key as a string literal, except mock fixture file names.
3. The screen model approach is chosen and recorded in the guide; client adoption tasks for it, and a task describing non-screen responses (`whoami`, `sign_in`), are written.

## Slices

Implemented in this order (guide 7.2). Names come first because they stand on their own: a misspelled name fails before anyone runs the app. Screen models build on the names list and are worth having before any client adopts them, because `make data-check` then guards every recorded response.

| Slice | Behavior | Tasks, in order | Depends on | Status |
|---|---|---|---|---|
| [EP-05.A](#ep-05a-a-misspelled-name-fails-the-build-or-the-data-check) | A misspelled backend function name or screen key fails the build or `make data-check` on every platform | SUP-019, IOS-020, AND-020 | EP-02.A | Draft |
| [EP-05.B](#ep-05b-screen-data-is-described-once-and-checked) | Each backend screen's data is described once in `/contract`, client models are generated from it, and `make data-check` fails when a response does not match | SUP-020 | EP-05.A | Draft |

### EP-05.A: A misspelled name fails the build or the data check

| # | Behavior acceptance criterion |
|---|---|
| B1 | Misspelling a function or screen key in `contract/names.json` makes `make data-check` fail, naming it, locally and in backend CI |
| B2 | Adding a screen to the backend without listing it in `names.json` makes `make data-check` fail |
| B3 | Renaming a generated constant by hand breaks the iOS and Android builds, and `make data-check` reports the drift |
| B4 | On iOS and Android, in Mock and Dev, sign-in, tabs and sign-out work as before |
| B5 | Searching client sources outside tests finds no backend function name or screen key as a string literal, except mock fixture file names |

### EP-05.B: Screen data is described once and checked

| # | Behavior acceptance criterion |
|---|---|
| B1 | `contract/README.md` shows the approaches compared, how each scored, and the one chosen |
| B2 | Removing a field from a screen's response on the backend makes `make data-check` fail after `make fixtures` |
| B3 | A backend screen key with no description makes `make data-check` fail, naming it |
| B4 | The generated Swift and Kotlin models for `auth.sign_in` decode its recorded response, and hand-editing a generated model makes `make data-check` fail on drift |

## Tasks

### Backend (SUP)

| Task | Depends on | Status |
|---|---|---|
| [SUP-019: Define backend function names and screen keys once and generate client constants](../tasks/SUP-019-shared-contract-names.md) | SUP-006, SUP-008 | Done |
| [SUP-020: Choose and prove how screen data models are defined once and generated for both clients](../tasks/SUP-020-screen-models.md) | SUP-019 | Draft |

### iOS (IOS)

| Task | Depends on | Status |
|---|---|---|
| [IOS-020: Use the generated contract names in the iOS app](../tasks/IOS-020-contract-names.md) | SUP-019, IOS-008 | Done |

### Android (AND)

| Task | Depends on | Status |
|---|---|---|
| [AND-020: Use the generated contract names in the Android app](../tasks/AND-020-contract-names.md) | SUP-019, AND-008 | Done |
