---
type: task
id: SUP-017
title: "Add the directory part to Browse and the browse button rule"
area: backend
epic: EP-04
depends_on: [SUP-015, SUP-016, SUP-023]
paired_with: []
status: Draft
---

# SUP-017: Add the directory part to Browse and the browse button rule

## Intent

Let eligible, listed people find each other and let staff see every eligible person, inside the existing browse screen.

## Scope

- `community.browse` gains an optional `directory` part (segment title, search placeholder, `PersonRow`s) for `directory.view`.
- `groups` part keeps requiring `groups.view_all`; each part has a segment title.
- Browse toolbar button on Community roots appears only when at least one part exists; label from the backend.
- "Not in directory" badge for unlisted people, shown to `people.view_all_eligible` holders.

## Out of scope

- Changing listing or fields (SUP-018).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | A listed member gets only the directory part; an unlisted member gets neither and no browse button | You can only look if you can be seen |
| AC2 | Staff get both parts; the directory includes unlisted eligible people with the badge | Staff can reach every group member |
| AC3 | Directory rows show the photo only when exposed and navigate to `people.person` | Privacy holds in lists too |
| AC4 | An attendee with no group gets no browse button and is refused the directory | Directory is only for eligible people |
| AC5 | pgTAP tests and mock responses cover AC1 to AC4 | Enforced and mirrored in mocks |

## Technical notes

- `specs/PEOPLE.md` 4.5.

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
