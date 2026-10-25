---
type: task
id: AND-027
title: "Handle call actions and lost access, and add leave and swipe to remove on Android"
area: android
epic: EP-03
depends_on: [AND-026, SUP-014]
paired_with: [IOS-026]
status: Ready
---

# AND-027: Handle call actions and lost access, and add leave and swipe to remove on Android

## Intent

Members leave a group and leaders remove someone with one tap and a confirmation, and nobody stays on a screen they lost access to. This task runs `call` actions generically, applies the lost-access rule on every screen, and adds Leave and swipe to remove to group detail.

## Scope

- `call` actions: show the backend `confirm` (a Material alert dialog, destructive styling when `role` is `destructive`), call `function` with `params`, then apply `on_success`: `refresh` the screen, `dismiss`, or `none`. A refusal shows the backend message the same way as the lost-access message. When the refresh after a refused call is itself refused with `screen_unavailable`, only the lost-access message is shown. Every call's params get `p_locale` added.
- Lost-access rule on every screen (guide 5.3 rule 9): `dismiss` on a pushed screen closes it and refreshes the screen below; on a tab root it refreshes in place. A refresh refused with `screen_unavailable` closes the screen, refreshes the one below and shows the backend message (a `Snackbar`).
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

- Swipe to remove is `SwipeToDismissBox`, end to start, with the remove label in the destructive color behind the row; passing the threshold asks for confirmation, and the row settles back when it is cancelled. TalkBack gets the remove action as a custom accessibility action (`semantics { customActions }`), which iOS swipe actions provide for free.
- The stale remove test makes the target member a leader through local Supabase after the screen loads, then removes them: refused, because leaders cannot remove leaders.
- Behavior must match IOS-026.

## Verification

```
cd android
./gradlew testMockDebugUnitTest testLocalDebugUnitTest connectedMockDebugAndroidTest
make test-local
./gradlew assembleLocalRelease && scripts/check_release_apk.sh app/build/outputs/apk/local/release/app-local-release-unsigned.apk
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
