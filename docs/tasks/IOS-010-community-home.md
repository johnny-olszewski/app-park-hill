---
type: task
id: IOS-010
title: "Build the iOS Community home for every state"
area: ios
epic: EP-03
depends_on: [IOS-011, SUP-012]
paired_with: [AND-010]
status: Draft
---

# IOS-010: Build the iOS Community home for every state

## Intent

The Community tab shows each person exactly their own groups. This task renders `community.home` in its three states, decided by the backend: an empty message, the person's one group, or a list of their groups. It also proves every persona end to end, in Mock in CI and against local Supabase.

## Scope

- Infer the state from which part is present, checking `group`, then `my_groups`, then `empty`; none present is unusable (cached copy, else the error screen).
- `group`: the group detail view from IOS-011.
- `my_groups`: the group list view, a shared component: one row per `GroupRow` with `title`, `subtitle` and optional `badge`; tapping performs the row's action.
- `empty`: the empty view, with `title` and `message` and no buttons.
- UI tests per persona (`attendee`, `member_one`, `member_two`, `leader`, `staff`, `admin`) in Mock, and the same against local Supabase in `make test-local`.

## Out of scope

- Browse and toolbars (EP-03.B).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Each persona sees its state from `specs/COMMUNITY.md` 8: `attendee` and `staff` the empty view, `member_one`, `leader` and `admin` their group's detail, `member_two` the list of both groups | State inference matches the contract |
| AC2 | A `community.home` with none of the three parts shows the cached copy, else the error screen with retry | Unknown shapes never render blank |
| AC3 | Group rows show `title`, `subtitle` and `badge` as sent; tapping one pushes that group's detail, and back returns to the list | Same row contract everywhere |
| AC4 | Pull to refresh on Community home refetches it | Fresh data on demand |
| AC5 | Mock UI tests cover AC1 and AC3 for every persona; Local UI tests cover AC1 against local Supabase in `make test-local` | Every role checked end to end |
| AC6 | Unit tests cover the state inference, including none present | Verified without a backend |

## Technical notes

- The tab title stays the one `get_tabs` sends ("Community").
- Persona credentials come from `contract/seed/dataset.json`, as the existing Local tests do.
- The empty view is `ContentUnavailableView`.
- Behavior must match AND-010.

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
