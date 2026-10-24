---
type: epic
id: EP-06
title: "Mock menu"
status: Draft
specs: [specs/AUTH.md]  # updated by SUP-021
design: https://claude.ai/artifact/2UqQWahHZ5j7r8xMvwjtPe
depends_on: []
---

# EP-06: Mock menu

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

Implemented in this order (guide 7.2). EP-06.C brings Android level with EP-06.A and EP-06.B (catch-up, guide 7.2 rule 3).

- [EP-06.A: Dev tools over the app](../slices/EP-06.A-local-tools-over-the-app.md)
- [EP-06.B: Mock testers sign in through the menu](../slices/EP-06.B-mock-testers-sign-in-through-the-menu.md)
- [EP-06.C: Android dev tools and Mock sign-in](../slices/EP-06.C-android-local-tools-and-mock-sign-in.md)

## Tasks

Every file in `docs/tasks/` with `epic: EP-06`. `docs/backlog.base` lists them with their status.
