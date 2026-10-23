---
type: task
id: SUP-016
title: "Build the person detail screen and the account toolbar item"
area: backend
epic: EP-04
depends_on: [SUP-012, SUP-015]
paired_with: []
status: Draft
---

# SUP-016: Build the person detail screen and the account toolbar item

## Intent

Serve one person detail screen that is both your own profile and how others see you, and put the account entry on every tab root from one place.

## Scope

- `people.person(user_id)`: header, fields per the visibility function, groups as `GroupRow` (tappable only if the viewer may open the group), eye states and directory switch on own detail, edit capabilities and `save`, sign-out label and confirmation on own detail.
- Edit roles toolbar button for `roles.assign_staff` or `roles.assign_admin`.
- Shared helper adding the Account toolbar item to every tab root in `get_tabs` and `get_screen`.
- Member rows in `community.group` gain `navigate` actions to `people.person`.
- Per-persona mock responses.

## Out of scope

- Directory part of browse (SUP-017).
- Saving changes (SUP-018).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Own detail shows every field with eye states, the directory switch only without `directory.always_listed`, Edit and sign-out | Your profile is where you manage what you share |
| AC2 | Someone else's detail shows only fields they expose, for every viewer persona | Privacy holds on every path |
| AC3 | Group rows on a person's detail are tappable only when the viewer may open that group | No dead ends or leaks through group links |
| AC4 | Edit roles appears only for viewers with a role assignment permission | Only admins manage roles |
| AC5 | Every tab root returned by `get_tabs` and `get_screen` includes the Account item (test iterates all roots) | No tab can forget the account entry |
| AC6 | Group member rows navigate to `people.person` | People are reachable from groups |
| AC7 | pgTAP tests and per-persona mock responses cover AC1 to AC6 | Enforced and mirrored in mocks |

## Technical notes

- Photo links are short-lived signed links generated per response.

## Verification

```
cd backend && supabase db reset && supabase test db && make data-check
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI
- [ ] No environment branching; no mock code in release builds
- [ ] Contract changes include mock responses
- [ ] No work outside Scope

## Open questions

None.
