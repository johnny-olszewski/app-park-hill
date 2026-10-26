---
type: task
id: SUP-013
title: "Build the people picker screen"
area: contract, backend
epic: EP-03
depends_on: [SUP-014]
paired_with: []
status: Ready
---

# SUP-013: Build the people picker screen

## Intent

Leaders and staff add people to a group by picking them from everyone signed up. This task builds `people.picker`: every person by name, with the backend marking who cannot be chosen, so clients never decide eligibility. The `PersonRow` it uses is shared with the future directory.

## Scope

- Contract: `PersonRow` (`user_id`, `title`, optional `subtitle`, optional `note`, `selectable`) in `contract/types/`; `NavigateAction.presentation` gains `sheet`. The commit that adds `sheet` also adds a `sheet` case to both clients' presentation switches that logs and does nothing, marked `TEMPORARY(EP-03)`, so every commit builds; IOS-012 and AND-012 replace it.
- `people.picker` with `group_id`: `{ title, search_placeholder, add_label, cancel_label, rows: [PersonRow] }`, every active user by display name, current members not selectable with the note "Already a member" (`specs/COMMUNITY.md` 5.8).
- Refused with `screen_unavailable` without `groups.add_member` on that group.
- Add `people.picker` to `contract/names.json`; describe it in `contract/screens/`; strings in migrations. Its mock responses come with SUP-024, whose `add_member` action is the first to open it (the generator records screens with params only through navigate actions).

## Out of scope

- Opening the picker from group detail and adding the chosen people (SUP-024).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | The picker lists every active user by display name and marks current members not selectable with the backend note | The backend decides who can be chosen |
| AC2 | The picker is refused with `screen_unavailable` for users without `groups.add_member` on that group, and returned for the group's leader and for staff | Only people who can add members can open it |
| AC3 | `make data-check` passes with the new type and description | Mocks mirror the real backend |
| AC4 | pgTAP tests cover AC1 and AC2 | Enforced, not documented |

## Technical notes

- Any signed-in user may see every user's display name (`specs/ROLES.md` 2, rule 3); nothing else about a person is sent.

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
