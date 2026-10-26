---
type: task
id: SUP-024
title: "Send group edit capabilities and save every change at once"
area: contract, backend
epic: EP-03
depends_on: [SUP-013]
paired_with: []
status: Ready
---

# SUP-024: Send group edit capabilities and save every change at once

## Intent

Leaders update their group in one pass: details, people added and removed, and (for staff) who leads it, saved together or not at all. This task sends each person exactly the edit capabilities they hold, and adds the one function that applies a whole batch in a single transaction, returning every problem in place.

## Scope

- Contract (`specs/COMMUNITY.md` 5.3 and 5.4), in `contract/types/`:
  - `GroupDetail` gains optional `edit` (`edit_label`, `done_label`, `cancel_label`), present when the caller holds any edit capability; optional `add_member` (`ActionButton`, `navigate` to `people.picker` as a `sheet`); optional `edit_fields` (list of `EditField`); optional `save` (`CallAction` to `save_group_changes`, `on_success` `refresh`)
  - `MemberRow` gains optional `toggle_leader` (`true` when the caller may make or remove this leader)
  - `EditField`: `id`, `label`, `kind` (enum `text`, `multiline`, `day`, `time`), `value` (a string: day `"1"` to `"7"`, time `"19:00"`), optional `options` (a list of `EditFieldOption`: `value`, `label`, for `day`). Name, day and time are required: an empty one is a field error ("Enter a name." for the name)
  - `SaveResult`: `ok`, optional `field_errors` (field id to message), optional `row_errors` (user id to message)
- `save_group_changes(p_group_id, p_batch, p_locale)`; `save`'s `params` carry `p_group_id`, and the client adds `p_batch` and `p_locale`. A save returns `SaveResult` (HTTP 200 whether `ok` or not), which clients decode. `p_batch` = `{ fields: { <id>: value }, add: [user_id], remove: [user_id], make_leader: [user_id], remove_leader: [user_id] }`: one transaction, permission checked per change; any problem applies nothing and returns `SaveResult` with every error localized.
- Row errors include "Already a member", "No longer in this group" and the refusal message; a change on a row the caller may not make is a row error.
- Add the function to `contract/names.json`; map its ok and failed results in `contract/responses.json`; strings in migrations; mock responses for `leader`, `staff` and `admin`, including the `people.picker` each one's `add_member` opens (mapped in `responses.json`), and for one ok and one failed save: `make mock-responses` records `save_group_changes.ok.json` and `save_group_changes.failed.json` (shared, not per persona) after every persona, then resets local Supabase so nothing it saved remains.

## Out of scope

- Delete group (EP-03.E).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `leader` gets `edit`, `edit_fields`, `add_member`, `save` and `remove` on non-leader rows for their group, and no `toggle_leader`; `staff` also gets `toggle_leader` on every row; members get none | Each capability only for people who hold it |
| AC2 | A valid batch applies every change; a batch with any invalid item applies none and returns `ok: false` with each error keyed to its field or row | All or nothing, with problems shown in place |
| AC3 | Every change is permission checked individually; one disallowed item fails the whole batch with a row or field error | Stale capabilities cannot slip through |
| AC4 | Making a non-member a leader adds them as a member; removing a member removes their leadership (SUP-010) | Leadership always sits on top of membership |
| AC5 | A disabled account is refused with `session_ended` | Server-side enforcement on every call |
| AC6 | `make data-check` passes with the new types, mappings and mock responses | Mocks show edit mode per persona |
| AC7 | pgTAP tests cover AC1 to AC5, with one allowed and one refused test for `groups.edit_details`, `groups.add_member` and `groups.assign_leader` | Every permission matrix row tested both ways |

## Technical notes

- `security definer` with a fixed `search_path`; `require_active_user()` then `has_permission` per change.
- Day and time values are stored in the church time zone setting (SUP-010); `options` labels are localized.

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
