---
type: task
id: IOS-025
title: "Build the iOS toolbar, full-screen cover and Browse all groups"
area: ios
epic: EP-03
depends_on: [IOS-010, SUP-023]
paired_with: [AND-026]
status: Done
---

# IOS-025: Build the iOS toolbar, full-screen cover and Browse all groups

## Intent

Staff open every group from a toolbar button on Community home. This task renders any envelope's toolbar, opens `full_screen_cover` targets the platform-native way, and builds `community.browse` with on-device search, reusing the group list view.

## Scope

- Toolbar from the envelope on every backend screen: items in backend order with the backend label and `icon_key` through `AssetProvider`; items beyond what the platform's bar fits go to its overflow menu, in order (the platform decides how many fit).
- `navigate` with `full_screen_cover`: a `fullScreenCover` with its own stack, a client-drawn close button (platform icon and accessibility label), fetched fresh with a loading state each time it opens.
- Group rows draw a badge with `badge_tone` `attention` in the danger color.
- `community.browse`: the group list view from IOS-010 with a search field filtering loaded rows by title as you type; search resets on close; pull to refresh; rows push `community.group` inside the cover.
- Bundled placeholder icon for `toolbar.browse`.
- Mock UI tests for `staff` and `member_one`; Local UI test for `staff` in `make test-local`.

## Out of scope

- The "Create group" item and `sheet` (EP-03.D, EP-03.E).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Toolbar items render with the backend label and icon in backend order; items the bar cannot fit go to the overflow menu in order; a screen without `toolbar` shows none | One toolbar pattern for every screen |
| AC2 | `staff` and `admin` see the browse button on every home state; other personas do not | The UI follows what each person can do |
| AC3 | The cover slides up from the bottom when opened and down when closed, on both platforms, and has a close button with the platform's icon and accessibility label | Same presentation behavior on both platforms (guide 5.5 rule 5) |
| AC4 | Browse shows a loading state, then every group with its badges; typing filters by title; closing and reopening clears the search and refetches | Fast local search for staff, always fresh |
| AC5 | Tapping a browse row pushes its group detail inside the cover; back returns to browse | Staff can open any group |
| AC6 | Mock UI tests cover AC2, AC4 and AC5; a Local UI test covers AC4 for `staff` against local Supabase | Verified per persona |

## Technical notes

- Toolbar items are `ToolbarItem`s with a `Menu` for overflow; search is `.searchable`.
- Behavior must match AND-026.

## Verification

```
cd ios
make project
xcodebuild -scheme ParkHill-Mock -destination "id=$(scripts/simulator.sh)" test
make test-local
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
