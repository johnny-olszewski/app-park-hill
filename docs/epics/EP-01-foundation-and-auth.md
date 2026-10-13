# EP-01: Foundation and authentication

| Field | Value |
|---|---|
| Status | Planning |
| Spec | [specs/AUTH.md](../specs/AUTH.md) |
| Next epic | [EP-02: Tabs](EP-02-tabs.md) |

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

## Milestones and tasks

### Milestone A: foundation

The app launches on both platforms, in Mock and Dev, to a backend-driven entry screen. CI enforces the contract and the no-mock-in-release rule.

#### Backend (SUP)

| Task | Depends on | Status |
|---|---|---|
| [SUP-001: Create the monorepo scaffold](../tasks/SUP-001-monorepo-scaffold.md) | None | Done |
| [SUP-002: Set up the local Supabase backend project](../tasks/SUP-002-local-supabase.md) | SUP-001 | Done |
| [SUP-003: Define the screen contract and implement get_entry and get_screen](../tasks/SUP-003-screen-contract.md) | SUP-002 | Done |
| [SUP-004: Add backend CI on GitHub Actions against local Supabase](../tasks/SUP-004-backend-ci.md) | SUP-003 | Draft |

#### iOS (IOS)

| Task | Depends on | Status |
|---|---|---|
| [IOS-001: Create the iOS project with Mock and Dev build configurations](../tasks/IOS-001-project-and-build-configs.md) | SUP-001 | Done |
| [IOS-002: Build the iOS backend service layer with production and mock implementations](../tasks/IOS-002-backend-service-and-mock.md) | SUP-003, IOS-001 | Done |
| [IOS-003: Build the iOS root coordinator, screen registry and backend-driven entry](../tasks/IOS-003-root-coordinator-and-registry.md) | IOS-002 | Done |
| [IOS-004: Add iOS CI on GitHub Actions](../tasks/IOS-004-ci.md) | IOS-003, SUP-004 | Draft |

#### Android (AND)

| Task | Depends on | Status |
|---|---|---|
| [AND-001: Create the Android project with Mock and Dev build variants](../tasks/AND-001-project-and-build-variants.md) | SUP-001 | Draft |
| [AND-002: Build the Android backend service layer with production and mock implementations](../tasks/AND-002-backend-service-and-mock.md) | SUP-003, AND-001 | Draft |
| [AND-003: Build the Android root coordinator, screen registry and backend-driven entry](../tasks/AND-003-root-coordinator-and-registry.md) | AND-002 | Draft |
| [AND-004: Add Android CI on GitHub Actions](../tasks/AND-004-ci.md) | AND-003, SUP-004 | Draft |

### Milestone B: authentication

Sign in with a seeded account (Dev) or a persona (Mock), stay signed in and sign out, with all sign-in text and errors from the backend.

#### Backend (SUP)

| Task | Depends on | Status |
|---|---|---|
| [SUP-005: Add profiles, seeded personas and a signed-in check function](../tasks/SUP-005-profiles-and-personas.md) | SUP-003 | Done |
| [SUP-006: Build the sign_in Edge Function with backend-decided errors and attempt limiting](../tasks/SUP-006-sign-in-function.md) | SUP-005 | Done |
| [SUP-007: Extend backend CI for auth: Edge Function tests and dataset check](../tasks/SUP-007-auth-ci.md) | SUP-004, SUP-006 | Draft |

#### iOS (IOS)

| Task | Depends on | Status |
|---|---|---|
| [IOS-005: Build the iOS auth service with production and mock implementations](../tasks/IOS-005-auth-service.md) | IOS-002, SUP-006 | Draft |
| [IOS-006: Build the iOS sign-in flow, mock persona picker and signed-in placeholder](../tasks/IOS-006-sign-in-flow.md) | IOS-003, IOS-005 | Draft |
| [IOS-007: Run iOS auth UI tests: Mock in CI, Dev locally](../tasks/IOS-007-auth-ui-tests-ci.md) | IOS-004, IOS-006 | Draft |

#### Android (AND)

| Task | Depends on | Status |
|---|---|---|
| [AND-005: Build the Android auth service with production and mock implementations](../tasks/AND-005-auth-service.md) | AND-002, SUP-006 | Draft |
| [AND-006: Build the Android sign-in flow, mock persona picker and signed-in placeholder](../tasks/AND-006-sign-in-flow.md) | AND-003, AND-005 | Draft |
| [AND-007: Run Android auth UI tests: Mock in CI, Dev locally](../tasks/AND-007-auth-ui-tests-ci.md) | AND-004, AND-006 | Draft |
