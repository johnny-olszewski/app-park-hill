---
type: task
id: IOS-026
title: "Handle call actions and lost access, and add leave and swipe to remove on iOS"
area: ios
epic: EP-03
depends_on: [IOS-025, SUP-014]
paired_with: [AND-027]
status: Draft
---

# IOS-026: Handle call actions and lost access, and add leave and swipe to remove on iOS

## Intent

Members leave a group and leaders remove someone with one tap and a confirmation, and nobody stays on a screen they lost access to. This task runs `call` actions generically, applies the lost-access rule on every screen, and adds Leave and swipe to remove to group detail.

## Scope

- `call` actions: show the backend `confirm` (an alert, destructive styling when `role` is `destructive`), call `function` with `params`, then apply `on_success`: `refresh` the screen, `dismiss`, or `none`. A refusal shows the backend message the same way as the lost-access message. When the refresh after a refused call is itself refused with `screen_unavailable`, only the lost-access message is shown. Every call's params get `p_locale` added.
- Lost-access rule on every screen (guide 5.3 rule 9): `dismiss` on a pushed screen closes it and refreshes the screen below; on a tab root it refreshes in place. A refresh refused with `screen_unavailable` closes the screen, refreshes the one below and shows the backend message (an alert with one button).
- Group detail: swipe to remove on rows with `remove`, labelled with its `label`; a Leave footer button from `leave`.
- Mock UI tests for `leader`, `member_one` and `member_two` (the only persona with a pushed group of their own); Local UI tests in `make test-local`: `member_one` leaves, a leader removes a member, a member removed while viewing a pushed group is taken off it on pull to refresh, and a stale remove is refused.
- A Local UI test helper that changes and restores `group_members` and `group_leaders` rows through local Supabase's REST API with the local service-role key (committed local value, test sources only), restoring every row a test changed when it ends.

## Out of scope

- Edit mode (EP-03.D).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | A `call` with `confirm` shows the backend title, message and labels before calling; cancelling calls nothing | Generic one-tap operations with the backend's wording |
| AC2 | Swiping a row with `remove` far enough asks for the backend confirmation; confirming removes the member and refreshes; cancelling returns the row to its place. Rows without `remove` do not swipe. A row with `remove` offers a `remove`-labelled accessibility action that does the same | Remove outside edit mode, behaving the same on both platforms (guide 5.5 rule 5) |
| AC3 | Leave appears only when sent; confirming on a pushed group closes it and refreshes the screen below; on Community home it refreshes home to its new state | Leaving always lands somewhere valid |
| AC4 | A refresh refused with `screen_unavailable` closes the screen, refreshes the one below and shows the backend message | People never stay on something they lost access to |
| AC5 | A call refused with `action_refused` shows its message and refreshes the screen | Stale buttons can never do what the user may not |
| AC6 | Unit tests cover AC1, AC3 and AC4 with mock responses; Mock UI tests cover AC2 and AC3 (the confirmation, the call and the dismiss or refresh; Mock responses are static); Local UI tests in `make test-local` cover leaving, removing, AC4 and AC5 against local Supabase | Verified per persona and end to end |

## Technical notes

- Swipe to remove is `.swipeActions`: a partial swipe reveals the button, a full swipe or a tap on it asks for confirmation. The swipe action is also VoiceOver's action for the row. A `role: .destructive` button animates the row away before the confirmation, so the row may need the destructive tint instead.
- The lost-access alert uses the system's default OK button.
- The stale remove test makes the target member a leader through local Supabase after the screen loads, then removes them: refused, because leaders cannot remove leaders.
- Behavior must match AND-027.

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
