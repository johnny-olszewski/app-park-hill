---
type: epic
id: EP-05
title: "Contract names"
status: Draft
specs: []  # the guide's 4.1 is updated by SUP-019
depends_on: []
---

# EP-05: Contract names

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
| 5 | As a developer, no response shape is written by hand in either app | Both apps decode every screen and response with the generated types; a description change that breaks a client fails its build |

## Exit criteria

1. All EP-05 tasks are Done.
2. No client source outside tests contains a backend function name or backend screen key as a string literal, except mock response file names.
3. The screen model approach is chosen and recorded in the guide; client adoption tasks for it, and a task describing non-screen responses (`whoami`, `sign_in`), are written.

## Slices

Implemented in this order (guide 7.2). Names come first because they stand on their own: a misspelled name fails before anyone runs the app. Screen models build on the names list and are worth having before any client adopts them, because `make data-check` then guards every recorded response. The apps then adopt the generated screen models (C), and the remaining responses are described and adopted (D), both before EP-03 so none of its models is written by hand.

- [EP-05.A: A misspelled name fails the build or the data check](../slices/EP-05.A-a-misspelled-name-fails-the-build-or-the-data-check.md)
- [EP-05.B: Screen data is described once and checked](../slices/EP-05.B-screen-data-is-described-once-and-checked.md)
- [EP-05.C: The apps decode screens with the generated models](../slices/EP-05.C-the-apps-decode-screens-with-the-generated-models.md)
- [EP-05.D: Every response is described once and checked](../slices/EP-05.D-every-response-is-described-once-and-checked.md)

## Tasks

Every file in `docs/tasks/` with `epic: EP-05`. `docs/backlog.base` lists them with their status.
