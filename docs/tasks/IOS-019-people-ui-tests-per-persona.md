---
type: task
id: IOS-019
title: "Add iOS people and directory UI tests per persona against local Supabase (local)"
area: ios
epic: EP-04
depends_on: [IOS-016, IOS-017, IOS-018, SUP-018]
paired_with: [AND-019]
status: Draft
---

# IOS-019: Add iOS people and directory UI tests per persona against local Supabase (local)

## Intent

Prove privacy and directory rules end to end on the real backend for each persona.

## Scope

- UI smoke tests per persona in Dev against local Supabase.

## Out of scope

- Exhaustive visibility coverage (backend tests own that).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | A member exposes their phone; another listed member then sees it, and sees it disappear after hiding it again | Sharing choices take effect for others |
| AC2 | An unlisted member has no browse button; listing again restores directory access | You can only look if you can be seen |
| AC3 | Staff see unlisted members with the badge but not their hidden fields | Staff reach everyone, privacy still holds |
| AC4 | An admin makes a persona staff and that persona's experience changes after refresh | Role changes work end to end |
| AC5 | Tests reset the database to the seed before running | Deterministic results |

## Technical notes

- Persona credentials from the test config.
- Runs locally with `make test-dev`; CI runs Mock tests only (guide 6).

## Verification

```
cd ios
xcodebuild -scheme ParkHill-Dev -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally with `make test-dev`
- [ ] No environment branching; no mock code in release builds
- [ ] Contract changes include mock responses
- [ ] No work outside Scope

## Open questions

None.
