# SUP-012: Build Community home and group detail for each person

| Field | Value |
|---|---|
| Area | backend |
| Epic | EP-03 |
| Depends on | SUP-008, SUP-010, SUP-011 |
| Paired with | None |
| Status | Draft |

## Intent

Each person's Community tab should show their own groups, decided entirely by the backend: nothing when they are in none, the group itself when they are in one, a list when they are in several. This task builds `community.home` and `community.group` read-only, so the clients can render every state from data alone.

## Scope

- `community.home` data: exactly one of `group` (`GroupDetail`), `my_groups` (`{ title, rows: [GroupRow] }`), `empty` (`{ title, message }`), per `specs/COMMUNITY.md` 4.1. "My groups" lists led groups first, then the rest, each by name.
- `community.group` with `group_id` param: `GroupDetail` for members, leaders and holders of `groups.view_all`; anyone else is refused with `screen_unavailable` and its localized message.
- Member rows: display name, "You" note on the caller's row, `is_leader`. No row actions (EP-03.C) and no edit capabilities (EP-03.D).
- The Community entry in `get_tabs` embeds `community.home` for the caller.
- All Community screens list only community-type, non-archived groups.
- Add `community.group` to `contract/names.json`; describe both screens in `contract/screens/` using the SUP-011 types.
- All strings in migrations; per-persona mock responses generated into `contract/mock_responses/<persona>/get_screen.<key>.json`, with `community.group` recorded for one group each persona may open.

## Out of scope

- Browse and toolbars (EP-03.B), leave and remove (EP-03.C), edit mode and the picker (EP-03.D), create and delete (EP-03.E).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `attendee` and `staff` get `empty`; `member_one`, `leader` and `admin` get `group`; `member_two` gets `my_groups` (personas in `specs/COMMUNITY.md` 8) | The backend decides the state; the client only maps it |
| AC2 | "My groups" lists led groups first, then the rest, each by name (pgTAP adds a user who leads one group and is in two others) | Ordering is backend owned |
| AC3 | `community.group` is refused with `screen_unavailable` for a user who is not a member, a leader or a holder of `groups.view_all`, and returned for each of those | Access rules hold even with a direct request |
| AC4 | The details, `leaders_line` ("Leaders: none yet" when leaderless), "You" note and `is_leader` match the seed data for each persona | One correct picture of a group for everyone allowed in |
| AC5 | Changing a Community string in the database changes the next response | Wording is remote |
| AC6 | `make data-check` passes: names, descriptions and per-persona mock responses match live output | Mocks mirror the real backend per persona |
| AC7 | pgTAP tests cover AC1 to AC5 | Enforced, not documented |

## Technical notes

- One assembly function per screen key, reused by `get_screen` and `get_tabs`.
- Every function starts with `require_active_user()`; access uses `has_permission`, never a role name (`specs/ROLES.md` 1).
- Meeting times are formatted in the church time zone setting (SUP-010).

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
