---
type: epic
id: EP-01
title: "Foundation and authentication"
status: Planning
specs: [specs/AUTH.md]
depends_on: []
---

# EP-01: Foundation and authentication

## Goal

A person with an account can sign in, stay signed in and sign out on iOS and Android. The project's working model (backend-driven screens, build-time environments, mocks, CI) is proven end to end.

## Out of scope

- Account creation, password reset, other sign-in methods.
- Roles and permissions.
- Tabs (EP-02). The signed-in destination is a temporary placeholder.

## User stories

| # | Story | Epic-level acceptance criteria |
|---|---|---|
| 1 | As a person with an account, I can sign in with my email and password | Works on iOS and Android. Every word on the screen comes from the backend. A wrong email or password gives the same message, so it does not reveal who has an account |
| 2 | As a signed-in person, I stay signed in | Relaunching skips sign-in, including with no signal. I do not re-enter my password until I sign out or my access is removed |
| 3 | As a signed-in person, I can sign out completely | After sign-out, relaunch shows sign-in and nothing about me remains on the device |
| 4 | As an admin, I can cut off someone's access | Once an account is disabled, the person's next request is refused and their app signs them out and returns to sign-in with an explanation. Any request refused for an expired or invalid session that cannot be renewed does the same |
| 5 | As the product owner, I can change sign-in wording and error messages without an app release | A string change in the backend shows on both platforms after refresh |
| 6 | As a developer, I can run the app with no backend and sign in as any persona | Mock builds make no network calls and list the shared personas. No mock code is in release builds |
| 7 | As a developer, I can point a Dev build at any backend without committing anything | A local override file switches the target, and the app shows which backend it is using |
| 8 | As a new contributor, a fresh clone builds and runs against local Supabase | Documented commands only; no hand-configured dashboards or missing files |
| 9 | As the team, every change is verified before it merges | Backend, iOS and Android checks run on every pull request, and merging is blocked on failure |
| 10 | As the owner of user data, sign-in is protected against abuse | Password guessing is limited per email and per device address, and passwords never appear in logs or storage |

## Exit criteria

1. All EP-01 tasks are Done.
2. A written demo script passes on both platforms in Mock and Dev, covering stories 1 to 7.
3. `specs/AUTH.md` matches what was built.
4. Open questions in EP-01 tasks are resolved and recorded in the guide's decision log.

## Slices

Implemented in this order (guide 7.2). Tasks Done before slices existed (SUP-001 to SUP-003, SUP-005, SUP-006, IOS-001 to IOS-003, IOS-005, IOS-006) have no slice. EP-01.B and EP-01.C are Android catch-up slices (guide 7.2 rule 3) mirroring that iOS work.

- [EP-01.A: Every PR is checked automatically](../slices/EP-01.A-every-pr-is-checked-automatically.md)
- [EP-01.B: Android launches to the backend-driven entry](../slices/EP-01.B-android-launches-to-the-backend-driven-entry.md)
- [EP-01.C: Android sign-in matches iOS](../slices/EP-01.C-android-sign-in-matches-ios.md)

## Milestones and tasks

### Milestone A: foundation

The app launches on both platforms, in Mock and Dev, to a backend-driven entry screen. CI enforces the contract and the no-mock-in-release rule.

Tasks: [SUP-001](../tasks/SUP-001-monorepo-scaffold.md), [SUP-002](../tasks/SUP-002-local-supabase.md), [SUP-003](../tasks/SUP-003-screen-contract.md), [SUP-004](../tasks/SUP-004-backend-ci.md), [IOS-001](../tasks/IOS-001-project-and-build-configs.md), [IOS-002](../tasks/IOS-002-backend-service-and-mock.md), [IOS-003](../tasks/IOS-003-root-coordinator-and-registry.md), [IOS-004](../tasks/IOS-004-ci.md), [AND-001](../tasks/AND-001-project-and-build-variants.md), [AND-002](../tasks/AND-002-backend-service-and-mock.md), [AND-003](../tasks/AND-003-root-coordinator-and-registry.md), [AND-004](../tasks/AND-004-ci.md).

### Milestone B: authentication

Sign in with a seeded account (Dev) or a persona (Mock), stay signed in and sign out, with all sign-in text and errors from the backend.

Tasks: [SUP-005](../tasks/SUP-005-profiles-and-personas.md), [SUP-006](../tasks/SUP-006-sign-in-function.md), [SUP-007](../tasks/SUP-007-auth-ci.md), [IOS-005](../tasks/IOS-005-auth-service.md), [IOS-006](../tasks/IOS-006-sign-in-flow.md), [IOS-007](../tasks/IOS-007-auth-ui-tests-ci.md), [AND-005](../tasks/AND-005-auth-service.md), [AND-006](../tasks/AND-006-sign-in-flow.md), [AND-007](../tasks/AND-007-auth-ui-tests-ci.md).
