# SUP-025: Build group create and delete for staff

| Field | Value |
|---|---|
| Area | contract, backend |
| Epic | EP-03 |
| Depends on | SUP-024 |
| Paired with | None |
| Status | Draft |

## Intent

Staff start new groups and retire old ones in the app. This task adds the create form screen and its operation, and delete as an archive, each sent only to people with the permission.

## Scope

- `community.browse` envelope: a "Create group" toolbar item for `groups.create` (`navigate` to `community.group.create` as a `sheet`).
- `community.group.create`: `{ title, save_label, cancel_label, fields: [EditField], save: CallAction }` with the detail fields (`specs/COMMUNITY.md` 5.7); refused with `screen_unavailable` without `groups.create`.
- `create_group(p_fields)`: validates and creates a community group, returning `SaveResult` with field errors on failure; on success the client opens the new group's detail (see Open questions).
- `GroupDetail` gains optional `delete` (`ActionButton`, destructive, with confirmation, `on_success` `dismiss`) for `groups.delete`, shown in edit mode.
- `delete_group(p_group_id)` archives the group; it disappears from every list and its detail is refused with `screen_unavailable`.
- Add the screen key and both functions to `contract/names.json`; describe the screen; strings in migrations; fixtures for `staff`.

## Out of scope

- Restoring archived groups.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `staff` and `admin` get the Create item on browse and `delete` on group detail; nobody else does | Each action only for people who may use it |
| AC2 | `create_group` with valid fields creates the group; invalid fields create nothing and return each error at its field | Staff can start a group in one flow, fixing problems in place |
| AC3 | `delete_group` archives; the group is gone from home and browse, and its detail is refused with `screen_unavailable` | Safe, reversible delete |
| AC4 | Both functions refuse a disabled account with `session_ended` and a caller without permission with `action_refused`; the create screen is refused without `groups.create` | Server-side enforcement on every call |
| AC5 | `make data-check` passes with the new screen, mappings and fixtures | Mocks show create and delete for staff |
| AC6 | pgTAP tests cover AC1 to AC4, with one allowed and one refused test for `groups.create` and `groups.delete` | Every permission matrix row tested both ways |

## Technical notes

- `security definer` with a fixed `search_path`; `require_active_user()` then `has_permission`.

## Verification

```
cd backend
supabase db reset && supabase test db && make data-check
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include fixture and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

1. **Opening the new group after create.** `specs/COMMUNITY.md` 5.7 says saving opens the new group's detail, but `on_success` has only `refresh`, `dismiss` and `none`, and the new group's id exists only after the call. Recommendation: `SaveResult` gains an optional `then` (`Action`), which the client performs after closing the sheet; `create_group` returns a `navigate` to `community.group` for the new group, pushed in the cover's stack. Alternative: add `on_success` `navigate_result`. Decide before this slice starts; the paired client tasks follow it.
