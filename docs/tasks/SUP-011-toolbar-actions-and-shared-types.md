# SUP-011: Extend the screen contract with toolbar, actions and shared group types

| Field | Value |
|---|---|
| Area | contract |
| Epic | EP-03 |
| Depends on | SUP-003 |
| Paired with | None |
| Status | Draft |

## Intent

Give every screen a standard way to carry toolbar buttons and tappable actions, and define the shared data types that several Community screens embed, so both clients build each once.

## Scope

- Envelope gains optional `toolbar` (`id`, `label`, `icon_key`, `action`).
- Action types `navigate` and `call` with `role: destructive`, `confirm` and `on_success` per `specs/COMMUNITY.md` 3.2.
- Shared types `GroupRow`, `GroupDetail` (including member rows, edit capabilities, `edit_fields`, `save`), `PersonRow`.
- Documented error `screen_unavailable` with a localized message.
- Contract docs and one fixture per type in `/contract/types/`.

## Out of scope

- Building any Community screen (SUP-012).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `/contract/README.md` documents toolbar, both action types, presentation values and `on_success` values | One contract for every screen |
| AC2 | Fixtures exist for each shared type, including a `GroupDetail` with and without edit capabilities | Clients can build views before screens exist |
| AC3 | An envelope without `toolbar` is still valid | Backward compatible with EP-01 and EP-02 clients |
| AC4 | `screen_unavailable` is documented with when it is returned | Clients can apply the lost-access rule |
| AC5 | A JSON schema check in `scripts/` validates every fixture against the documented types and runs in CI | Fixtures cannot drift from the contract |

## Technical notes

- Contract only; no SQL beyond shared helper types if useful.

## Verification

```
scripts/check-contract
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI
- [ ] No environment branching; no mock code in release builds
- [ ] Contract changes include fixtures
- [ ] No work outside Scope

## Open questions

None.
