---
type: task
id: IOS-009
title: "Open backend screens by push, with refresh and a per-screen cache on iOS"
area: ios
epic: EP-03
depends_on: [IOS-024, SUP-011]
paired_with: [AND-009]
status: Draft
---

# IOS-009: Open backend screens by push, with refresh and a per-screen cache on iOS

## Intent

Community rows open other backend screens. This task gives every backend screen the shared behavior that needs: a `navigate` action with `push` opens the target screen in the current tab, any screen can be pulled to refresh, and each screen's last good copy is shown when a fetch fails. Later slices add presentations, toolbars and `call` on top.

## Scope

- Decode `Action` with the generated types (SUP-011).
- `navigate` with `push`: fetch `get_screen(screen_key, locale, params)`, show a loading state, then push the registered screen onto the current tab's stack (`NavigationStack`). Back returns to the previous screen as it was.
- An action of unknown `type`, or a target screen key this build does not register, leaves the item not tappable or pushes nothing, and is logged (contract rule 3).
- Pull to refresh on every backend screen refetches it through `get_screen`.
- Screen cache per screen key and params, last good copy (guide 5.3 rule 10): a failed fetch shows the cached copy, else the error screen with retry. Sign-out wipes it.

## Out of scope

- `full_screen_cover` and toolbars (EP-03.B), `call` and the lost-access rule (EP-03.C), `sheet` (EP-03.D).
- Community screens (from IOS-011).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Tapping an item with a `push` action shows a loading state, then the target screen; the pushed screen slides in from the trailing edge and slides back out on back | Navigation targets come from the backend, with the platform's push behavior on both (guide 5.5 rule 5) |
| AC2 | Back returns to the previous screen unchanged, with the back button and with the system gesture (edge swipe) | Standard back navigation on both platforms |
| AC3 | An unknown action `type` makes the item not tappable; an unregistered target key pushes nothing; both are logged | Clients drop what they do not know |
| AC4 | Pull to refresh on a backend screen refetches it and shows the new data | Fresh data on demand |
| AC5 | A failed fetch shows the cached copy for that key and params, else the error screen with retry; sign-out wipes the cache | Usable offline, private after sign-out |
| AC6 | Unit tests cover AC3 to AC5 using mock responses | Verified without a backend |

## Technical notes

- The tab coordinator owns the stack (guide 5.1); screens never navigate themselves.
- Pull to refresh is `.refreshable`.
- Behavior must match AND-009.

## Verification

```
cd ios
make project
xcodebuild -scheme ParkHill-Mock -destination "id=$(scripts/simulator.sh)" test
make test-dev
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include mock response and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None.
