---
type: task
id: SUP-015
title: "Extend profiles with phone, photo and directory visibility"
area: backend
epic: EP-04
depends_on: [SUP-010]
paired_with: []
status: Draft
---

# SUP-015: Extend profiles with phone, photo and directory visibility

## Intent

Store what each person shares and with whom, with privacy rules the backend enforces, expressed only through permissions so future kinds of membership inherit them.

## Scope

- `profiles` gains phone (international format), photo path, `listed`, and visibility flags for photo, phone and groups.
- Defaults when eligibility begins: listed, photo, phone and groups hidden. Settings kept when eligibility ends.
- Private Supabase Storage bucket for photos with upload and read policies (own photo only for upload).
- Permissions `directory.eligible`, `directory.always_listed`, `people.view_all_eligible` seeded per `specs/ROLES.md`.
- A visibility function returning, for a viewer and a person, exactly which fields may be shown.
- Personas `member_unlisted`, `member_shared`; some seeded phones and photos.

## Out of scope

- Screens and operations (SUP-016 to SUP-018).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | A person becoming eligible gets the defaults; losing eligibility hides them from the directory without erasing their settings | Opt-in sharing with a sensible starting point |
| AC2 | For every viewer type (peer, staff, admin, self, ineligible) the visibility function returns only exposed fields, plus name and email | Everyone sees only what a person exposes |
| AC3 | A holder of `directory.always_listed` cannot set `listed` to false | Staff and admins are always listed |
| AC4 | Only the owner can upload or replace their photo; nobody can list the bucket | Photos stay private to the rules |
| AC5 | The extensibility test from `specs/ROLES.md` passes: a test group type and role granted `directory.eligible` makes its members eligible with no code change | Serving teams later are data only |
| AC6 | pgTAP tests cover AC1 to AC5 | Enforced, not documented |

## Technical notes

- `specs/PEOPLE.md` 2, 3 and 5.

## Verification

```
cd backend && supabase db reset && supabase test db
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI
- [ ] No environment branching; no mock code in release builds
- [ ] Contract changes include mock responses
- [ ] No work outside Scope

## Open questions

None.
