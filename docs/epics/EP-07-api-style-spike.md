---
type: epic
id: EP-07
title: "API style spike"
status: Draft
specs: []
depends_on: [EP-03]  # the spike rebuilds community.group as EP-03.C left it
---

# EP-07: API style spike

## Goal

Decide, from a measured comparison rather than opinion, whether Park Hill keeps backend-built screen data or moves to backend-driven navigation with screens that query domain data through GraphQL. Today every new screen needs a SQL screen function, a schema file, a `names.json` entry, recorded mock responses, generated models and a registry entry on each platform (guide 4.1). The alternative keeps screen keys, tabs and navigation targets on the backend, so a screen can still ship before it is switched on, and lets each screen fetch typed data from `pg_graphql` with Apollo-generated models.

## Out of scope

- Adopting either style. The spike ends in a findings report and a recommendation; adopting GraphQL, if chosen, is planned afterwards on a `plan/` branch with its own decision log row.
- Android. Apollo Kotlin is assumed to cost about what Apollo iOS does; the report says so.
- Any screen other than `community.group`.

## User stories (draft)

| # | Story | Epic-level acceptance criteria |
|---|---|---|
| 1 | As the reviewer, I can compare the two styles for one real screen | `community.group`, with leave, remove and lost access, works on iOS against local Supabase through GraphQL, on an unmerged `spike/` branch |
| 2 | As the reviewer, I can decide from numbers | The findings report gives files and lines per style, the RLS policies and capability fields GraphQL needs, and how mocks, caching and lost access would work |

## Exit criteria

1. EP-07.A is Done, with its findings report merged to `main`.
2. The reviewer has recorded the decision: a decision log row on the spike's slice branch, keeping the current style or naming the follow-up `plan/` branch.

## Slices

- [EP-07.A: The API style is chosen from a measured comparison](../slices/EP-07.A-the-api-style-is-chosen-from-a-measured-comparison.md)

## Tasks

Every file in `docs/tasks/` with `epic: EP-07`. `docs/backlog.base` lists them with their status.
