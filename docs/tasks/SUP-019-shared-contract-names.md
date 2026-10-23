---
type: task
id: SUP-019
title: "Define backend function names and screen keys once and generate client constants from them"
area: contract, backend
epic: EP-05
depends_on: [SUP-006, SUP-008]
paired_with: []
status: Done
---

# SUP-019: Define backend function names and screen keys once and generate client constants from them

## Intent

Backend function names and screen keys are typed by hand as strings in the backend and in each client, and nothing checks that they match. A typo in a function name passes Mock and every CI test, and only fails against a real backend. This task makes `/contract` the single place these names are written, checks the backend against it, and generates constants the clients compile against, so a mismatch fails `make data-check` or the build instead of a running app.

## Scope

- Add `contract/names.json`, the one hand-written list of:
  - RPC functions clients call: `get_entry`, `get_screen`, `get_tabs`, `whoami`
  - Edge Functions clients call: `sign_in`
  - Screen keys the backend returns: `auth.sign_in`, `home.root`, `community.home`
- Add `backend/scripts/generate_names.py`, which writes:
  - `contract/generated/ContractNames.swift`
  - `contract/generated/ContractNames.kt`
- Add `backend/scripts/check_names.py`, which fails when local Supabase and `names.json` disagree in either direction (see AC3 to AC5).
- Add `make names` to `backend/Makefile`, and run the generation and the check from `make data-check`.
- Document the file and the commands in `contract/README.md` and `backend/README.md`.
- Update `ENGINEERING_GUIDE.md` 4.1 (new contract rule) and add a decision log entry in section 8.

## Out of scope

- Using the generated constants in the iOS app (IOS-020) and the Android app (AND-020).
- Mock-only screen keys (`.mock`). They exist only in client mock sources and must not appear in a file that release builds compile (guide 5.2 rule 3).
- Function parameter names (`p_locale`, `p_key`, `p_params`) and response field names. Possible follow-up task.
- Functions that do not exist yet. Each future task adds its own names here in the same PR.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `contract/names.json` lists exactly the names in Scope, and is the only hand-written source for them under `/contract` and `/backend/scripts` | One place to write a name |
| AC2 | `make names` regenerates both files in `contract/generated/`; running it twice produces no diff; each file starts with a "GENERATED, do not edit" header naming the command | Generated files are reproducible and never hand-edited |
| AC3 | `check_names.py` fails when an RPC function in `names.json` does not exist in the local database's `public` schema, or exists but is not executable by `anon` or `authenticated` | A misspelled or unreachable function is caught before any client calls it |
| AC4 | `check_names.py` fails when an Edge Function in `names.json` has no folder in `backend/supabase/functions/` | Same guarantee for Edge Functions |
| AC5 | `check_names.py` fails when a screen key is in `names.json` but not in the `screens` table, or in the `screens` table but not in `names.json` | Adding a screen without listing it, or listing one that does not exist, is caught |
| AC6 | `make data-check` runs generation and the check, and fails if `contract/generated/` differs from what is committed; backend CI runs it on every PR (SUP-007) | Drift fails the same command that already guards seed and mock responses |
| AC7 | The guide's 4.1 states that every client-called function and backend screen key is listed in `contract/names.json`, and section 8 records the decision | The rule outlives this task |

## Technical notes

- Follow the existing dataset pattern: `contract/seed/dataset.json` to `generate_seed.py` and `check_personas.py`, run from `backend/Makefile`. Python, standard library only, reusing `backend/scripts/dataset.py` and `local_supabase.py` where they fit.
- `names.json` shape:

  ```json
  {
    "rpc_functions": ["get_entry", "get_screen", "get_tabs", "whoami"],
    "edge_functions": ["sign_in"],
    "screen_keys": ["auth.sign_in", "home.root", "community.home"]
  }
  ```

- Generated Swift (`ContractNames.swift`): `enum RPCFunction: String` and `enum EdgeFunction: String` with one case per name; `enum ScreenKey` with one `static let` per key (screen keys stay `String` because the registry takes keys from backend payloads). Case names are the lower camel case form of the name: `get_entry` becomes `getEntry`, `auth.sign_in` becomes `authSignIn`.
- Generated Kotlin (`ContractNames.kt`): the same three groups as `enum class RpcFunction(val value: String)`, `enum class EdgeFunction(val value: String)` and `object ScreenKey` with `const val`. Package `app.parkhill.contract`, under the app's Kotlin namespace `app.parkhill` (not the placeholder application ID).
- Generated files live in `contract/generated/`, next to the dataset and mock responses; each client compiles its file from there (IOS-020, AND-020) and never copies it.
- AC3: read the function list and privileges from the local database (`postgresql://postgres:postgres@127.0.0.1:54322/postgres`, Supabase CLI default). Mechanism is implementer's choice.
- `data-check`'s drift check covers `contract/generated` alongside the existing generated paths.
- Guide sections: 4.1 (contract), 6 (one canonical dataset, nothing generated edited by hand).

## Verification

```
cd backend
supabase start
make names && git status --short ../contract/generated   # no changes on a second run
make data-check                                           # passes
```

Then, one at a time, reverting after each:

1. Rename `whoami` to `whoamii` in `names.json`: `make data-check` fails naming it (AC3).
2. Rename `sign_in` to `signin` in `names.json`: fails (AC4).
3. Remove `auth.sign_in` from `names.json`: fails (AC5).
4. Hand-edit `ContractNames.swift`: fails on drift (AC6).

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include mock response and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None.
