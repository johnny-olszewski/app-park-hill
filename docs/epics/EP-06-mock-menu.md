# EP-06: Mock menu

| Field | Value |
|---|---|
| Status | Draft |
| Spec | `specs/AUTH.md` (updated by SUP-021) |
| Design | [Park Hill Mock Menu brief](https://claude.ai/artifact/2UqQWahHZ5j7r8xMvwjtPe) |
| Previous epic | [EP-05: Contract names](EP-05-contract-names.md) |

## Goal

The Mock build shows the production app, starting with the real sign-in screen, and every mock and debug option lives in one menu laid over it. Testers see exactly what members will see, and can still choose who they sign in as and which result the next sign-in gives, including every error. Debug builds get the same menu with app-wide tools, such as the current screen's data. Nothing of it reaches a release build.

## Out of scope

- Demo mode. It will be a real session on the real backend with a private sandbox per demo, and never reuses mock code (design brief, "Future: demo mode").
- Mock tools for screens other than sign-in. Later screen tasks register their own.

## User stories (draft)

| # | Story | Epic-level acceptance criteria |
|---|---|---|
| 1 | As a tester, I see the production sign-in screen in the Mock build | Mock launches to `auth.sign_in` from its recorded response; the persona picker screen and `auth.sign_in.mock` no longer exist |
| 2 | As a tester, I sign in as any persona without knowing credentials | With a persona chosen in the menu and Success armed, any credentials sign in as that persona |
| 3 | As a tester, I can see every sign-in error as members would | Each refusal and connection failure can be armed in the menu and appears on the real screen with the backend's recorded text |
| 4 | As a tester, I never forget a failure is armed | While one is armed, the pill shows an alert icon and the menu opens with a warning naming it |
| 5 | As a developer, I can see what the current screen received | Debug builds show the current screen's key and data from the menu on every screen |
| 6 | As a developer, adding tools for a screen does not touch that screen | Tools are registered by screen key; no production screen references the menu, the pill or the tracker |

## Exit criteria

1. All EP-06 tasks are Done.
2. No screen draws the backend label; the pill is drawn once, above everything the app presents.
3. Release builds on both platforms contain no dev tools or mock symbols, proven on the release artifact.

## Slices

Implemented in this order (guide 7.2). Android tasks are left out until the Android exception ends (guide 7.2 rule 3); they stay listed under Tasks.

| Slice | Behavior | Tasks, in order | Depends on | Status |
|---|---|---|---|---|
| [EP-06.A](#ep-06a-dev-tools-over-the-app) | Debug builds show a pill on every screen that opens a dev tools menu | IOS-021 | None | Done |
| [EP-06.B](#ep-06b-mock-testers-sign-in-through-the-menu) | Mock testers sign in through the menu, as any persona, with any result | SUP-021, IOS-022 | EP-06.A | Draft |

### EP-06.A: Dev tools over the app

Built as a single task (IOS-021) before slices existed.

| # | Behavior acceptance criterion |
|---|---|
| B1 | In the Mock and Dev debug builds, a `MOCK` or `DEV` pill shows at the top of every screen, including sign-in; the release build shows none |
| B2 | Long-pressing the pill opens a menu showing the build's backend, the current screen's key and data, and Sign out when signed in |
| B3 | With the menu closed, every tap outside the pill works as before |

### EP-06.B: Mock testers sign in through the menu

| # | Behavior acceptance criterion |
|---|---|
| B1 | The Mock build opens on the production sign-in screen; there is no persona list screen |
| B2 | In the menu, choose Admin and Success, close it, type anything and tap Sign in: signed in as Admin |
| B3 | Arm Too many attempts: the pill shows an alert icon and the menu says "Next sign-in will fail: Too many attempts"; signing in shows the backend's too-many-attempts message under the password field |
| B4 | Arm No connection: signing in shows the can't-connect message box above the fields |
| B5 | Signed in, Switch persona to Attendee: now signed in as Attendee |

## Tasks

### Backend (SUP)

| Task | Depends on | Status |
|---|---|---|
| [SUP-021: Record every sign-in refusal and update the auth spec for the mock menu](../tasks/SUP-021-sign-in-refusal-responses.md) | SUP-006 | Done |

### iOS (IOS)

| Task | Depends on | Status |
|---|---|---|
| [IOS-021: Build the iOS dev tools overlay: top pill, menu, screen tracker and tool registry](../tasks/IOS-021-dev-tools-overlay.md) | IOS-006 | Done |
| [IOS-022: Show the production sign-in in Mock with persona and result tools](../tasks/IOS-022-mock-sign-in-tools.md) | IOS-021, SUP-021 | Draft |

### Android (AND)

| Task | Depends on | Status |
|---|---|---|
| [AND-021: Build the Android dev tools overlay: top pill, menu, screen tracker and tool registry](../tasks/AND-021-dev-tools-overlay.md) | AND-006 | Draft |
| [AND-022: Show the production sign-in in Mock with persona and result tools](../tasks/AND-022-mock-sign-in-tools.md) | AND-021, SUP-021 | Draft |
