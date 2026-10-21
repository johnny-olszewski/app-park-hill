# EP-02: Tabs

| Field | Value |
|---|---|
| Status | Draft |
| Spec | None yet |
| Previous epic | [EP-01: Foundation and authentication](EP-01-foundation-and-auth.md) |

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

| Slice | Behavior | Tasks, in order | Depends on | Status |
|---|---|---|---|---|
| [EP-02.A](#ep-02a-signed-in-people-see-the-backends-tabs) | Signed-in people see the backend's tabs on iOS and Android | SUP-008, IOS-008, AND-008, AND-023 | EP-06.C | Draft |

### EP-02.A: Signed-in people see the backend's tabs

| # | Behavior acceptance criterion |
|---|---|
| B1 | On iOS and Android, in Mock and Dev, signing in shows Home and Community tabs in backend order, each on an empty page, with the first tab selected; the placeholder screen is gone |
| B2 | In Dev, renaming, reordering or disabling a tab in the database shows on both apps after relaunch or returning to the app, with no rebuild |
| B3 | After one signed-in launch, relaunching with no connection still shows the tabs |
| B4 | Home's Sign out button signs out and returns to sign-in on both apps |
| B5 | In debug builds, the dev tools menu's Current screen shows the selected tab's screen and changes when switching tabs |
| B6 | On Android, signing in slides the sign-in screen away and signing out slides it back up, as on iOS |

## Tasks

### Backend (SUP)

| Task | Depends on | Status |
|---|---|---|
| [SUP-008: Implement get_tabs for signed-in users](../tasks/SUP-008-get-tabs.md) | SUP-005 | Draft |

### iOS (IOS)

| Task | Depends on | Status |
|---|---|---|
| [IOS-008: Build the iOS backend-fed tab shell and remove the placeholder](../tasks/IOS-008-tab-shell.md) | IOS-006, IOS-021, SUP-008 | Draft |

### Android (AND)

| Task | Depends on | Status |
|---|---|---|
| [AND-008: Build the Android backend-fed tab shell and remove the placeholder](../tasks/AND-008-tab-shell.md) | AND-006, AND-021, SUP-008 | Draft |
| [AND-023: Animate the Android entry in and out like iOS](../tasks/AND-023-entry-transitions.md) | AND-008 | Draft |
