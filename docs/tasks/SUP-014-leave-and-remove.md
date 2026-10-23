# SUP-014: Add call actions, leaving a group and removing a member

| Field | Value |
|---|---|
| Area | contract, backend |
| Epic | EP-03 |
| Depends on | SUP-012 |
| Paired with | None |
| Status | Draft |

## Intent

Members need to leave a group and leaders need to remove someone quickly, in one tap with a confirmation, enforced by the backend. This task adds the `call` action to the contract and the two operations behind it, and puts each button only where the person may use it.

## Scope

- Contract: `CallAction` (`type` `call`, `function`, `params`, optional `confirm` with `title`, `message`, `confirm_label`, `cancel_label`, `on_success` enum `refresh`, `dismiss`, `none`, optional `role`) joins the `Action` union; `ActionButton` (`label`, `action`) in `contract/types/`. Documented in `contract/README.md` (`specs/COMMUNITY.md` 3.2).
- `MemberRow` gains optional `remove` (`ActionButton`, destructive, with confirmation, `on_success` `refresh`); `GroupDetail` gains optional `leave` (`ActionButton`, destructive, with confirmation, `on_success` `dismiss`).
- `remove_member(p_group_id, p_user_id)` and `leave_group(p_group_id)`; leaving ends membership and leadership and may leave a group leaderless.
- Error `action_refused` with the backend's localized message in `details`, for a call the caller may no longer make; documented with `screen_unavailable`.
- `community.group` refused after leaving carries the message "You're no longer in this group".
- Add both functions to `contract/names.json`; strings in migrations; mock responses regenerated.

## Out of scope

- Edit mode and the batch save (EP-03.D); create and delete (EP-03.E).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `leave` is sent to every member of the group, leaders included; `remove` is sent on non-leader rows to the group's leaders and on every row other than the caller's to holders of `groups.remove_member` for all groups | Each button only for people who may use it |
| AC2 | `leave_group` ends membership and leadership; a group's last leader can leave, leaving it leaderless | Nobody is trapped in a group |
| AC3 | `remove_member` refuses a leader removing another leader with `action_refused` | Leaders cannot bypass assign-leader rules |
| AC4 | Each function refuses a disabled account with `session_ended` and a caller without permission with `action_refused` and a localized message | Server-side enforcement on every call |
| AC5 | After leaving, `get_screen('community.group')` for that group returns `screen_unavailable` with "You're no longer in this group" | Clients can apply the lost-access rule |
| AC6 | `make data-check` passes, including a mock response with `remove` and `leave` for `leader` | Mocks show the buttons per persona |
| AC7 | pgTAP tests cover AC1 to AC5, with one allowed and one refused test for "Leave a group" and `groups.remove_member` | Every permission matrix row tested both ways |

## Technical notes

- Functions are `security definer` with a fixed `search_path`; each starts with `require_active_user()` then `has_permission`.
- `function` in a `CallAction` is a name from `names.json`; clients call it as given.

## Verification

```
cd backend
supabase db reset && supabase test db && make data-check
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
