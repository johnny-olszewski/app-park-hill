---
type: task
id: SUP-022
title: "Describe the non-screen responses and the screen envelope once"
area: contract, backend
epic: EP-05
depends_on: [SUP-020]
paired_with: []
status: Draft
---

# SUP-022: Describe the non-screen responses and the screen envelope once

## Intent

SUP-020 describes each screen's `data`, but the shapes around it (the screen envelope, `get_tabs`, `whoami`, the `sign_in` responses) are still written by hand in each client and checked by nothing. This task describes them once in `/contract`, with the same subset, generator and check as screen data, so every response a client decodes has one definition and `make data-check` guards all of them. It adds the shared types (`$ref`) the subset lacks, which EP-03's `GroupRow` and `Action` also need.

## Scope

- Extend the description subset, generator and check (`backend/scripts/screens.py`, `generate_models.py`, `check_models.py`) with:
  - `$ref` to a shared type in `contract/types/<TypeName>.schema.json` (relative path `../types/<TypeName>.schema.json` from a screen, `<TypeName>.schema.json` between types)
  - `"type": "object"` with no `properties`: any JSON object (Swift `JSONValue`, Kotlin `JsonObject`)
- Describe as types in `contract/types/`: `ScreenEnvelope` (`key`, `data`: any object), `TabsResponse`, `TabItem`, `Profile`, `SignInSuccess`, `SignInSession`, `SignInFailure`. Field names and types as the clients have them today.
- `contract/responses.json`: maps each recorded response, by mock response file name without its persona folder (`get_entry`, `get_screen.<key>`, `get_tabs`, `whoami`, `sign_in.ok`, `sign_in.error`, `sign_in.error.<code>`), to its type. `make data-check` validates every mock response against its type and fails on a mock response with no mapping. Screen `data` inside an envelope is still validated against its screen's description.
- All generated Swift types conform to `Codable, Equatable, Sendable` (the clients cache envelopes and tabs); Kotlin types stay `@Serializable`.
- Update `contract/README.md` (Screen data becomes Contract descriptions: subset, `$ref`, `responses.json`) and `backend/README.md`.
- Update guide 4.1 rule 8 to cover every response a client decodes, with a decision log entry.

## Out of scope

- Using the generated types in the apps (IOS-024, AND-025).
- Request bodies (`SignInRequest`) and PostgREST error bodies.
- The envelope's `toolbar` (EP-03.B adds it to `ScreenEnvelope`).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `contract/types/` holds the seven types in Scope; `make models` generates one Swift and one Kotlin file for each, with the same fields, names and types as the clients' current hand-written ones | Generated types can replace the hand-written ones without behavior change |
| AC2 | A screen or type can reference a shared type with `$ref`; the generator emits the referenced type's name, and the check validates the value against it | Shared types are defined once (needed by EP-03) |
| AC3 | `make data-check` validates every file in `contract/mock_responses` against its type from `responses.json`, and fails when a mock response has no mapping or does not match | Every recorded response is guarded, not only screen data |
| AC4 | Removing `display_name` from `whoami` in its migration, `supabase db reset`, `make mock-responses`: `make data-check` fails naming `whoami` and the field | The backend cannot drift from a non-screen description |
| AC5 | A `$ref` to a missing type, or a type no description or mapping uses, makes `make data-check` fail naming it | No dangling or dead definitions |
| AC6 | Running `make models` twice produces no diff; hand-editing a generated type makes `make data-check` fail on drift | Generated files are never edited by hand |
| AC7 | Guide 4.1 rule 8 states that every response a client decodes is described in `/contract` and its client types generated, and section 8 records the decision | The rule outlives this task |

## Technical notes

- Keep refusing every keyword outside the subset; add only `$ref` and the property-less object.
- Swift `TabItem.screen` and Kotlin `TabItem.screen` are the generated `ScreenEnvelope`; Kotlin `ScreenEnvelope.data` is `JsonObject`, as today.
- `SignInSession` replaces the nested `SignInSuccess.Session` type: the subset has no inline object types, so nested objects are shared types.
- Guide sections: 4.1 (rules 6 and 8), 6.

## Verification

```
cd backend
supabase start
make models && git status --short ../contract/generated   # no changes on a second run
make data-check                                            # passes
```

Then the failures in AC4 to AC6, one at a time, reverting after each.

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include mock response and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None.
