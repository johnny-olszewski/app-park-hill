# SUP-020: Choose and prove how screen data models are defined once and generated for both clients

| Field | Value |
|---|---|
| Area | contract, backend |
| Epic | EP-05 |
| Depends on | SUP-019 |
| Paired with | None |
| Status | Done |

## Intent

Each screen's data model is written by hand on every client (for example `SignInScreenData` on iOS), and nothing checks it against what the backend returns. Every new screen adds the same model on each platform, and a mismatch shows up only at runtime. This task picks how a screen's data model is described once in `/contract`, proves it on the backend's screens (`auth.sign_in`, `home.root`, `community.home`), and checks recorded responses against it, so later screens get both client models with no hand-written model code. The approach is not decided yet; choosing it is part of this task.

## Scope

- Compare candidate approaches against the criteria in Technical notes, and record the comparison and the choice in `contract/README.md`. Candidates include at least JSON Schema with a code generator, and a small format of our own with a script in `backend/scripts/`.
- Implement the chosen approach for every backend screen key in `contract/names.json` (SUP-019): `auth.sign_in`, `home.root`, `community.home`:
  - one description per screen under `contract/screens/`
  - generated Swift and Kotlin models in `contract/generated/`, one file per screen per platform (`SignInScreenData.swift`, `SignInScreenData.kt`), in Kotlin package `app.parkhill.contract`
  - `make models` in `backend/Makefile`, run from `make data-check` with a drift check
- Validate every recorded screen envelope in `contract/fixtures/` against its screen's description from `make data-check`, including the envelopes embedded in `get_tabs`.
- Update `ENGINEERING_GUIDE.md` 4.1 and add a decision log entry in section 8.

## Out of scope

- Using the generated models in the apps. iOS and Android adoption tasks are written once the approach is chosen, because their acceptance criteria depend on it.
- Screens added after this task. Each later screen task adds its own description.
- Responses that are not screen envelopes (`whoami`, `sign_in`, the `get_tabs` wrapper). A follow-up task, written once this approach is in place.
- Mock-only screens (`.mock`), which stay in client mock sources.
- Changing the envelope (`key`, `data`, `toolbar`) or any contract rule other than adding the description requirement.
- A generic element list in place of per-screen models: considered and rejected (see Technical notes).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `contract/README.md` lists each candidate, how it scored against every criterion in Technical notes, and the choice with its reasons | The decision is reviewable and does not need to be re-made |
| AC2 | `contract/screens/` holds one description per backend screen key in `names.json`, and each is the only hand-written definition of that screen's fields under `/contract` and `/backend/scripts` | One place to define a screen's data |
| AC3 | `make models` generates one Swift and one Kotlin file per screen in `contract/generated/`, each with the same fields, names and types as that screen's current hand-written model on that platform (`SignInScreenData`, `HomeRootData`, `CommunityHomeData`); running it twice produces no diff | The generated model can replace the hand-written one without behavior change |
| AC4 | The generated Swift and Kotlin each compile in a scratch build outside the apps and decode `contract/fixtures/get_entry.json`; decoding a copy with an added unknown field also succeeds, and one with a required field removed fails | Generated models keep contract rules 2 (ignore unknown fields) and 4 (one model per key) |
| AC5 | `make data-check` fails when a recorded screen response does not match its description, and when a screen key returned by the backend has no description | The backend cannot drift from the shared definition |
| AC6 | `make data-check` fails when `contract/generated/` differs from what `make models` produces | Generated models are never edited by hand |
| AC7 | The guide's 4.1 states that every backend screen key has a data description in `contract/screens/` from which client models are generated, and section 8 records the decision | The rule outlives this task |

## Technical notes

- Criteria for choosing the approach:
  1. Generated code is plain, readable, committed to the repo, and adds no runtime dependency to either app.
  2. Swift output is `Decodable` and `Equatable`; Kotlin output works with the serialization library AND-002 uses.
  3. Expresses nested shared types defined once and reused across screens (`Action`, `ToolbarItem`, `GroupRow` from `specs/COMMUNITY.md` 3), optional fields, lists and enums.
  4. Generated decoders ignore unknown fields (guide 4.1 rule 2).
  5. Runs from `backend/Makefile` with Python or a single tool whose version is pinned, like XcodeGen in `ios/Makefile`.
  6. The same description validates live responses in `make data-check`.
  7. A new screen needs one description file and one command, with no hand edits elsewhere.
- Field names in descriptions stay snake_case (`email_label`); generated client properties use each platform's convention (`emailLabel`), as `SignInScreenData` does today.
- Follow the pattern of SUP-019 and the dataset: one hand-written source, generated files committed, `make data-check` fails on drift (guide 6).
- Already considered: a generic list of typed elements looked up by id (`[{ "type": "text", "id": "title", "value": "Sign in" }]`). Rejected because clients would still write per-screen lookup code for every field, loses compile-time typing, and expresses nested data such as a list of groups poorly.
- Guide sections: 4.1 (contract rules 1, 2 and 4; screens, not views), 6.

## Verification

```
cd backend
supabase start
make models && git status --short ../contract/generated   # no changes on a second run
make data-check                                            # passes
```

Then, one at a time, reverting after each:

1. Remove `title` from the `auth.sign_in` response in its migration's function, `supabase db reset`, `make fixtures`: `make data-check` fails (AC5).
2. Delete `contract/screens/auth.sign_in.*`: `make data-check` fails naming the undescribed key (AC5).
3. Hand-edit the generated Swift model: `make data-check` fails on drift (AC6).

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include fixture and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None. Resolved 2026-10-22:

1. Kotlin is compile-checked like Swift (AC4): the Android project exists now.
2. One generated file per screen per platform; Kotlin package `app.parkhill.contract`.
3. Non-screen responses (`whoami`, `sign_in`) are a follow-up task.
