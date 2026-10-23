---
type: task
id: IOS-008
title: "Build the iOS backend-fed tab shell and remove the placeholder"
area: ios
epic: EP-02
depends_on: [IOS-006, IOS-021, SUP-008]
paired_with: [AND-008]
status: Done
---

# IOS-008: Build the iOS backend-fed tab shell and remove the placeholder

## Intent

After sign-in, show the tabs the backend sends, on empty pages, with one navigation stack per tab. This replaces the temporary placeholder and is how every future signed-in screen is reached.

## Scope

- `getTabs(locale:)` on `BackendService` (production and mock, per persona mock responses).
- `TabCoordinator` per tab owning its `NavigationStack`, exposing push, present and pop.
- Registered empty screens `home.root` and `community.home`.
- `AssetProvider` with bundled icons for `tab.home`, `tab.community` and a fallback.
- Tabs cache per locale; foreground refresh.
- Temporary "Sign out" button in the Home tab root's toolbar, hardcoded in the client (not backend driven), with a bundled label. Every line of it is marked with the comment `TEMPORARY(EP-04): remove with IOS-015/AND-015`.
- Delete the `Temporary` placeholder.
- Dev tools (EP-06): the screen tracker follows the selected tab, so Current screen shows the selected tab's screen. The Session tool shows the signed-in user's id (tag `devTools.session.user`). UI tests that checked the placeholder's user check this instead.

## Out of scope

- Screen content, roles, deep links, pull to refresh UI.
- A More tab or user reordering of tabs (maximum five; order comes from the backend).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | After sign-in in Dev, tab titles, order and count match `get_tabs`; changing them in the database shows after relaunch or foreground, no rebuild | Tabs are fed from the backend |
| AC2 | In Mock, the signed-in persona's `get_tabs` mock response is shown with no backend | Standalone app works per persona |
| AC3 | Each tab shows its empty root screen | Navigable shell, no content |
| AC4 | Each tab keeps its own stack; a test pushes in one tab, switches away and back, and the stack is intact | Coordinator infrastructure is proven |
| AC5 | A tab with an unregistered screen key is dropped and logged; if none survive, the error screen shows | Backend can ship ahead of the client |
| AC6 | Fetch failure with a cache renders cached tabs; without one, error with retry | Usable offline after first run |
| AC7 | An unknown icon key renders the fallback icon | New icon keys cannot break the tab bar |
| AC8 | A hardcoded "Sign out" toolbar button on Home signs out and clears the tabs cache; every line of its code carries the comment `TEMPORARY(EP-04): remove with IOS-015/AND-015` | Sign-out stays available until EP-04, and its removal is a simple search |
| AC9 | The `Temporary` folder and placeholder no longer exist | No client-owned screen remains |
| AC10 | Unit tests for coordinators, registry and cache; UI test signs in and switches tabs | Verified |
| AC11 | A fresh launch selects the first tab in backend order; returning to a running app keeps the current tab | The landing tab is set by backend order |
| AC12 | At most five tabs are shown; if more ever arrive, the first five in backend order are shown and the rest are logged | Five-tab maximum on both platforms; the backend enforces it, the client guards it |
| AC13 | In debug builds, the dev tools menu's Current screen shows the selected tab's root screen, and Session shows the signed-in user's id; the Mock and Dev UI tests that checked the placeholder check it there | Dev tools keep working with tabs, and tests no longer need the placeholder |

## Technical notes

- Guide 5.1 and 5.3. Behavior matches AND-008.
- Tabs use the system tab bar (`TabView`), styled with brand color and type only (guide 5.5).
- The tabs cache lives under the cache directory sign-out already deletes, so AC8's clearing needs no extra code.

## Verification

```
cd ios
xcodebuild -scheme ParkHill-Mock -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] No environment branching; no mock code in Release
- [ ] No work outside Scope

## Open questions

None. Tab icons are bundled placeholders keyed `tab.home` and `tab.community` (SF Symbols-based on iOS, Material Symbols-based on Android) until design provides artwork under the same keys.
