---
type: task
id: SUP-011
title: "Describe actions and the shared group types in the contract"
area: contract, backend
epic: EP-03
depends_on: [SUP-022]
paired_with: []
status: Draft
---

# SUP-011: Describe actions and the shared group types in the contract

## Intent

Community screens are built from a few shared shapes: a tappable action, a group row, a group's detail with its members. This task describes them once in `contract/types/` (SUP-022), so every screen embeds the same definitions and both apps get generated types for them. Actions are a tagged union from the start, so EP-03.C can add `call` and later slices can add presentations without changing what exists.

## Scope

- Extend the description subset, generator and check (`backend/scripts/screens.py`, `generate_models.py`, `check_models.py`) with:
  - `enum` of strings: Swift `enum: String, Codable`, Kotlin `enum class` with `@SerialName` per value
  - a tagged union: `oneOf` of `$ref`s, each referenced type fixing `type` with a one-value `enum`. Swift: an `enum` with one case per member plus `unknown`, with a `Decodable` that reads `type`; Kotlin: a sealed interface with one `@Serializable` class per member and an unknown member, decoded on the `type` field
- Types in `contract/types/`:
  - `Action`: union of `NavigateAction` only for now (EP-03.C adds `CallAction`)
  - `NavigateAction`: `type` (`navigate`), `screen_key`, `params` (any object), `presentation` (enum, `push` only for now; EP-03.B adds `full_screen_cover`, EP-03.D adds `sheet`), optional `role` (enum, `destructive`)
  - `GroupRow`: `group_id`, `title`, `subtitle`, optional `badge`, `action`
  - `GroupDetail`: `group_id`, `title`, `description`, `meeting`, `location`, `leaders_line`, `members_title`, `members` (list of `MemberRow`)
  - `MemberRow`: `user_id`, `title`, optional `note` (for example "You"), `is_leader`
- Document `screen_unavailable` in `contract/README.md` Errors: when it is returned and that its `details` carry the backend's localized message.
- One example mock response per type in `contract/types/examples/<TypeName>.json`, validated by `make data-check`.

## Out of scope

- Building any screen (SUP-012).
- `CallAction`, row and footer actions, edit capabilities (EP-03.C to E).
- Toolbars (EP-03.B, SUP-023).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `make models` generates Swift and Kotlin for the five types; a group row with an `action` of unknown `type` decodes, with the action as unknown | Clients ignore what they do not know (contract rules 2 and 3) |
| AC2 | A `presentation` or `role` value outside its enum fails `make data-check` when it appears in a mock response | The backend cannot send a value the clients do not know |
| AC3 | Each type's example in `contract/types/examples/` passes the check, and an example missing a required field fails it | Clients can build views before screens exist |
| AC4 | `contract/README.md` documents actions, presentation values, the shared types and `screen_unavailable` | One contract for every screen |
| AC5 | The generated Swift and Kotlin for `Action` compile in a scratch build and decode the `NavigateAction` example and an unknown-type action (as SUP-020 AC4) | The union works on both platforms before any app uses it |

## Technical notes

- Follow SUP-020 and SUP-022: refuse every keyword outside the subset; add only `enum` and the tagged `oneOf`.
- Field text is backend formatted and localized (`specs/COMMUNITY.md` 3.3); `meeting` is one line such as "Tuesdays · 7:00 PM".
- Guide sections: 4.1 (contract rules, rule 8), 2 (principles).

## Verification

```
cd backend
make models && make data-check
```

Then AC1, AC2 and AC3 failures with temporary edits to an example, reverted after each.

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include mock response and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None.
