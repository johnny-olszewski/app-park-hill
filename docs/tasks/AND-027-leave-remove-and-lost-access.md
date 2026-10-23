# AND-027: Handle call actions and lost access, and add leave and swipe to remove on Android

| Field | Value |
|---|---|
| Area | android |
| Epic | EP-03 |
| Depends on | AND-026, SUP-014 |
| Paired with | IOS-026 |
| Status | Draft |

## Intent

Members leave a group and leaders remove someone with one tap and a confirmation, and nobody stays on a screen they lost access to. This task runs `call` actions generically, applies the lost-access rule on every screen, and adds Leave and swipe to remove to group detail.

## Scope

- `call` actions: show the backend `confirm` (a Material alert dialog, destructive styling when `role` is `destructive`), call `function` with `params`, then apply `on_success`: `refresh` the screen, `dismiss`, or `none`. A refusal shows the backend message the same way as the lost-access message.
- Lost-access rule on every screen (guide 5.3 rule 9): `dismiss` on a pushed screen closes it and refreshes the screen below; on a tab root it refreshes in place. A refresh refused with `screen_unavailable` closes the screen, refreshes the one below and shows the backend message (a `Snackbar`).
- Group detail: swipe to remove on rows with `remove`, labelled with its `label`; a Leave footer button from `leave`.
- Mock UI tests for `leader` and `member_one`; Dev UI tests in `make test-dev`: `member_one` leaves, a leader removes a member, and a stale remove is refused.

## Out of scope

- Edit mode (EP-03.D).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | A `call` with `confirm` shows the backend title, message and labels before calling; cancelling calls nothing | Generic one-tap operations with the backend's wording |
| AC2 | Swiping a row with `remove` reveals the remove button; confirming removes the member and refreshes; cancelling returns the row to its place. Rows without `remove` do not swipe | Remove outside edit mode, behaving the same on both platforms (guide 5.5 rule 5) |
| AC3 | Leave appears only when sent; confirming on a pushed group closes it and refreshes the screen below; on Community home it refreshes home to its new state | Leaving always lands somewhere valid |
| AC4 | A refresh refused with `screen_unavailable` closes the screen, refreshes the one below and shows the backend message | People never stay on something they lost access to |
| AC5 | A call refused with `action_refused` shows its message and refreshes the screen | Stale buttons can never do what the user may not |
| AC6 | Unit tests cover AC1, AC3 and AC4 with mock responses; Mock UI tests cover AC2 and AC3; Dev UI tests in `make test-dev` cover leaving, removing and AC5 against local Supabase | Verified per persona and end to end |

## Technical notes

- Swipe to remove is `SwipeToDismissBox`, end to start, revealing a destructive remove action; the row settles back when the confirmation is cancelled.
- The stale remove test revokes the leader's membership through local Supabase after the screen loads, then taps remove.
- Behavior must match IOS-026.

## Verification

```
cd android
./gradlew testMockDebugUnitTest testDevDebugUnitTest connectedMockDebugAndroidTest
make test-dev
./gradlew assembleDevRelease && scripts/check_release_apk.sh app/build/outputs/apk/dev/release/app-dev-release-unsigned.apk
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
