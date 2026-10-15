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
2. No client source outside mock-only code and tests contains a backend function name or backend screen key as a string literal.
3. The screen model approach is chosen and recorded in the guide; client adoption tasks for it are written.

## Tasks

### Backend (SUP)

| Task | Depends on | Status |
|---|---|---|
| [SUP-019: Define backend function names and screen keys once and generate client constants](../tasks/SUP-019-shared-contract-names.md) | SUP-006 | Draft |
| [SUP-020: Choose and prove how screen data models are defined once and generated for both clients](../tasks/SUP-020-screen-models.md) | SUP-019 | Draft |

### iOS (IOS)

| Task | Depends on | Status |
|---|---|---|
| [IOS-020: Use the generated contract names in the iOS app](../tasks/IOS-020-contract-names.md) | SUP-019, IOS-006 | Draft |

### Android (AND)

| Task | Depends on | Status |
|---|---|---|
| [AND-020: Use the generated contract names in the Android app](../tasks/AND-020-contract-names.md) | SUP-019, AND-006 | Draft |
