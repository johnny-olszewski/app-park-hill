---
type: epic
id: EP-02
title: "Tabs"
status: Draft
specs: []
depends_on: []
---

# EP-02: Tabs

## Goal

After sign-in, people see the tabs the backend sends, each with its own navigation, on empty pages. This replaces the EP-01 placeholder and is how every later signed-in feature is reached.

## Out of scope

- Screen content on any tab.
- Per-user tab content (EP-03 makes the Community tab's embedded data differ per user; the tab list itself stays the same for everyone).

## User stories (draft)

| # | Story | Epic-level acceptance criteria |
|---|---|---|
| 1 | As a signed-in person, I see the app's tabs and can move between them | Home and Community appear on iOS and Android after sign-in; each tab keeps its own navigation history |
| 2 | As the product owner, I can rename, reorder, add or hide tabs without an app release | A backend data change shows on both platforms after relaunch or return to the app |
| 3 | As a signed-in person, the app still opens with no signal | The last tabs I saw are shown from cache |
| 4 | As the product owner, I can ship a backend tab before every app version supports it | Apps that do not know a tab's screen skip it instead of breaking |
| 5 | As a signed-in person, I can still sign out | Sign-out is reachable from the tab shell and clears cached tabs |
| 6 | As the product owner, I choose which tabs appear and where people land | Up to five tabs; a fresh launch opens the first tab in backend order; people cannot reorder tabs |

## Exit criteria

1. All EP-02 tasks are Done.
2. The temporary signed-in placeholder is deleted on both platforms.
3. Sign-out is a temporary hardcoded Home toolbar button marked `TEMPORARY(EP-04)`, removed by EP-04. Tab icons are placeholders until design delivers artwork.

## Slices

Implemented in this order (guide 7.2). One slice: the backend alone, or one platform's shell alone, is not worth having on its own (rule 2).

- [EP-02.A: Signed-in people see the backend's tabs](../slices/EP-02.A-signed-in-people-see-the-backends-tabs.md)

## Tasks

Every file in `docs/tasks/` with `epic: EP-02`. `docs/backlog.base` lists them with their status.
