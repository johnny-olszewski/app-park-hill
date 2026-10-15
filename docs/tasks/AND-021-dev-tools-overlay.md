# AND-021: Build the Android dev tools overlay: top pill, menu, screen tracker and tool registry

| Field | Value |
|---|---|
| Area | android |
| Epic | EP-06 |
| Depends on | AND-006 |
| Paired with | IOS-021 |
| Status | Draft |

## Intent

Android twin of IOS-021. Mock and debug options get one home above the production app, without any production screen knowing about it: a pill at the top of every screen, a menu opened from it, and the mechanisms that let each screen contribute its own tools.

## Scope

- A dev tools overlay in debug builds holding the pill and presenting the menu, above every screen, dialog and bottom sheet.
- The pill: the backend target text, with an alert icon while any tool reports an armed warning. Long press opens the menu.
- The menu as a modal bottom sheet: armed warnings at the top, then the current screen's tools, then app tools.
- App tools: Build, Current screen (key, and data as formatted JSON on its own page, copyable), Clear cached data (with confirmation), Sign out (when signed in).
- A screen tracker reported to by the screen registry; a tool registry keyed by screen key, with optional armed warnings.
- Remove the backend label from the sign-in and persona picker screens.
- `android/README.md` updated.

## Out of scope

- Mock sign-in tools and removing the persona picker (AND-022).
- Switch persona (AND-022, mock flavor only).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | In mockDebug and devDebug, the pill shows on every screen, including over the sign-in full-screen dialog and over bottom sheets, and does not cover status bar items or top app bar titles on a small and a large phone at default and largest font scale | One persistent entry point, never in the way |
| AC2 | No production screen composable draws the backend label or references the pill, menu, tracker or tool registry | Production screens are unaware of dev tools |
| AC3 | Touches anywhere except the pill reach the app; existing mock and dev UI tests pass | The overlay never changes app behavior |
| AC4 | Long-pressing the pill opens the menu; Current screen shows the key and data of the most recently shown backend-driven screen, reported by the screen registry | Developers can see what any screen received |
| AC5 | A tool registered for a key appears only while that screen is current; a tool reporting a warning puts an alert icon on the pill and its text at the top of the menu (unit tests with a test tool) | Per-screen tools and armed warnings work for any future screen |
| AC6 | devRelease shows no pill; the release artifact contains no dev tools class | Dev tools never ship |
| AC7 | Selection is by source sets; app code contains no `BuildConfig.DEBUG`, `BuildConfig.FLAVOR` or runtime environment check | Same mechanism as the service bindings (guide 5.2) |
| AC8 | `android/README.md` explains the pill, the menu, how to register a screen tool and which variants include them | The next developer can add a tool |

## Technical notes

- Dev tools in `src/debug` (debug build type only), a no-op binding in `src/release`; mock-only tools later in `src/mock`.
- Dialogs and modal bottom sheets are separate windows on Android, so an overlay inside the activity's content is hidden behind them. The mechanism that keeps the pill above them is the implementer's choice, documented in the README.
- Guide 5.1, 5.2 and 5.5. Design: EP-06 brief.

## Verification

```
cd android
./gradlew testMockDebugUnitTest
./gradlew connectedMockDebugAndroidTest
./gradlew assembleDevRelease
```

Inspect the devRelease artifact: no dev tools classes. Screenshot the pill on a small and a large phone at the largest font scale, on sign-in and over a bottom sheet.

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include fixture and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None.
