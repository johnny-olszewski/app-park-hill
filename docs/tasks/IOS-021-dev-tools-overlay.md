---
type: task
id: IOS-021
title: "Build the iOS dev tools overlay: top pill, menu, screen tracker and tool registry"
area: ios
epic: EP-06
depends_on: [IOS-006]
paired_with: [AND-021]
status: Done
---

# IOS-021: Build the iOS dev tools overlay: top pill, menu, screen tracker and tool registry

## Intent

Mock and debug options need one home that sits above the production app without any production screen knowing about it. This task builds that layer: a pill at the top of every screen, a menu opened from it, and the mechanisms that let each screen contribute its own tools. It replaces the backend label each entry screen draws today.

## Scope

- A dev tools window above the app's own window, created once at launch in debug configurations, holding the pill and presenting the menu.
- The pill: the environment name (`MOCK`, `DEV`), centered just below the status bar, with an alert icon while any tool reports an armed warning. Long press opens the menu. The full backend address is in the menu's Build tool.
- The menu sheet: armed warnings at the top, then the current screen's tools, then app tools.
- App tools: Build (environment and backend), Current screen (key, and data as formatted JSON on its own page, copyable), Clear cached data (with confirmation), Sign out (when signed in).
- A screen tracker reported to by `ScreenRegistry` for every screen it resolves.
- A tool registry: screen key to tools, plus app tools; tools may report an armed warning.
- Debug and release bindings chosen by build settings.
- Remove `BackendTargetLabel` from `SignInScreen` and `PersonaPickerScreen`.
- `ios/README.md` updated.

## Out of scope

- Mock sign-in tools and removing the persona picker (IOS-022).
- Switch persona (IOS-022, Mock only).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | In Mock-Debug and Dev-Debug, a pill reading `MOCK` or `DEV` shows centered just below the status bar on every screen, including over the sign-in full-screen cover and over sheets; on iPhone 16 and iPhone SE at default and largest text sizes it covers no status bar item and no control other than itself | One persistent entry point that never blocks the app |
| AC2 | No file under `ParkHill/Screens/` draws the backend label or references the pill, menu, tracker or tool registry | Production screens are unaware of dev tools |
| AC3 | Touches anywhere except the pill reach the app; existing Mock and Dev UI tests pass | The overlay never changes app behavior |
| AC4 | Long-pressing the pill opens the menu; Current screen shows the key and data of the most recently shown backend-driven screen, reported by `ScreenRegistry` | Developers can see what any screen received |
| AC5 | A tool registered for a key appears only while that screen is current; a tool reporting a warning puts an alert icon on the pill and its text at the top of the menu (unit tests with a test tool) | Per-screen tools and armed warnings work for any future screen |
| AC6 | Dev-Release builds create no window and show no pill; the release artifact contains no symbol from `ParkHill/DevTools/` | Dev tools never ship |
| AC7 | Selection is by build settings and binding files; app code contains no `#if` and no runtime environment check | Same mechanism as the service bindings (guide 5.2) |
| AC8 | `ios/README.md` explains the pill, the menu, how to register a screen tool and which configurations include them | The next developer can add a tool |

## Technical notes

- An overlay on the root view is hidden behind full-screen covers and sheets, so the pill lives in a second `UIWindow` on the same scene, above the app window, whose hit testing passes through everywhere except the pill. The menu is presented from that window.
- Sources: `ParkHill/DevTools/` compiled in Mock-Debug and Dev-Debug only. Binding files `DevToolsBinding+Enabled.swift` (in `DevTools/`) and `DevToolsBinding+Disabled.swift` (outside it), selected with a `DEV_TOOLS` build setting added to `INCLUDED_SOURCE_FILE_NAMES` in `Config/App.xcconfig`, with `DEV_TOOLS[config=Dev-Release] = Disabled` and `*/DevTools/*` excluded there. Verify with `xcodebuild -showBuildSettings` per configuration.
- `ScreenRegistry` reports through a tracker protocol; the release binding provides one that does nothing.
- Tools are value types with a title, a view and an optional warning; the registry builds the menu from them.
- Pill placement and text were settled during implementation: top center below the status bar, environment name only. It may overlap a centered inline navigation title after scrolling; titles are not tappable, so nothing is blocked.
- Guide 5.1, 5.2 and 5.5. Design: EP-06 brief.

## Verification

```
cd ios
make project
xcodebuild -scheme ParkHill-Mock -destination 'platform=iOS Simulator,name=iPhone 16' test
xcodebuild -scheme ParkHill-Dev  -destination 'platform=iOS Simulator,name=iPhone 16' test
xcodebuild -project ParkHill.xcodeproj -target ParkHill -configuration Dev-Release -showBuildSettings | grep -E 'EXCLUDED_SOURCE|INCLUDED_SOURCE'
```

Build Dev-Release and list its symbols: none from `DevTools/`. Screenshot the pill on iPhone 16 and iPhone SE with the largest text size, on sign-in and over a sheet.

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include mock response and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None.
