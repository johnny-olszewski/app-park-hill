# AND-023: Animate the Android entry in and out like iOS

| Field | Value |
|---|---|
| Area | android |
| Epic | EP-02 |
| Depends on | AND-008 |
| Paired with | None (iOS already has this: its entry is a full-screen cover) |
| Status | Done |

## Intent

On iOS the signed-out entry is a full-screen cover, so it slides in when someone signs out or their session ends, and slides away after they sign in. Android swaps these screens with no transition. Moving between signed in and signed out should feel the same on both platforms.

## Scope

- `AppRoot` animates the change between launching, the signed-out entry and the signed-in destination (the tab shell from AND-008).
- The entry comes up from the bottom over the destination when someone signs out or their session ends, and goes back down after they sign in. This matches the iOS cover.
- Changes inside the entry (loading, the entry screen, the launch error) cross-fade.

## Out of scope

- Navigation inside tabs (AND-008 and later screen tasks).
- The dev tools menu (AND-021).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Signing in slides the entry down to reveal the signed-in destination | Matches iOS |
| AC2 | Signing out, or the session ending, slides the entry up over the destination | Matches iOS |
| AC3 | Launch to the entry or to the destination, and changes within the entry, cross-fade instead of cutting | No abrupt swaps |
| AC4 | With animations off (developer options), every change is instant and the existing UI tests pass unchanged | Accessibility and test stability |
| AC5 | No screen composable knows about the transition; only `AppRoot` does | Screens stay unaware of navigation (guide 5.3) |

## Technical notes

- `AnimatedContent` keyed on the root state (launching, entry, signed in), with a vertical slide for entry ↔ signed in and a fade otherwise. Use Material motion durations.
- Done after AND-008 because AND-008 replaces the placeholder this would otherwise animate.

## Verification

```
cd android
./gradlew connectedMockDebugAndroidTest
```

Run Mock with animator duration scale 10 (developer options) and check AC1 to AC3 against the iOS simulator.

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include fixture and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None.
