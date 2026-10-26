---
type: task
id: SUP-026
title: "Serve group detail through pg_graphql on a spike branch"
area: backend
epic: EP-07
depends_on: [SUP-014]
paired_with: []
status: Draft
---

# SUP-026: Serve group detail through pg_graphql on a spike branch

## Intent

Measure what the backend needs to serve `community.group` as domain data through `pg_graphql` instead of a screen function, while keeping every permission decision on the backend (guide 2). This is a spike: its code is evidence for the findings report and never merges (guide 7.1 rule 13).

## Scope

- On `spike/EP-07.A-graphql`: enable `pg_graphql` in a migration if local Supabase does not already, and expose the tables `community.group` reads (`groups`, `group_members`, `group_leaders`, `profiles` as needed) to `authenticated` through select policies that let a person read exactly what `internal.group_detail` shows them today.
- Capability fields as `pg_graphql` computed fields (SQL functions taking the row): `viewer_can_leave` on a group and `viewer_can_remove` on a membership, built from the same permission checks `leave_group` and `remove_member` use (specs/ROLES.md). Clients read these instead of re-implementing roles.
- `leave_group` and `remove_member` reachable as GraphQL mutations, unchanged in what they check and refuse.
- pgTAP tests for the policies and capability fields, querying as the seed personas.
- On the slice branch: the backend half of `docs/spikes/EP-07.A-graphql.md` (Technical notes, Measurements).

## Out of scope

- Display formatting (meeting line, leaders line): the client builds it in IOS-028.
- Strings: GraphQL screens use bundled client strings in the spike.
- Mock responses, `names.json`, `contract/` and `make data-check`: the report says how each would change instead.
- Removing or changing `get_screen` or any existing function.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `select * from graphql.resolve(...)` for a group's detail returns the group, its members and leaders for a member persona, and nothing for a persona outside the group | The data is readable only where today's screen shows it |
| AC2 | `viewer_can_leave` and `viewer_can_remove` match what `leave_group` and `remove_member` would allow, for every seed persona, in pgTAP | Permissions stay with the backend (guide 2); the client never decides |
| AC3 | The `leaveGroup` and `removeMember` mutations refuse exactly what the RPC functions refuse, with the same messages | The spike measures the API style, not new rules |
| AC4 | `supabase test db` passes on the spike branch, including every existing test | The new policies do not weaken or break the current API |
| AC5 | The report lists, for the backend: files and lines added, RLS policies and computed fields needed, and every rule the screen function enforced that now needs a policy | The decision weighs the real backend cost |

## Technical notes

- Branches per guide 7.1 rule 13: code commits on `spike/EP-07.A-graphql`, branched from the slice branch after its readiness commits; the report and the Done commit on `slice/EP-07.A-graphql-spike`.
- `config.toml` already exposes `graphql_public`; the endpoint is `/graphql/v1` on the local API port.
- Current tables have RLS enabled with no read policies, because screens read them through `security definer` functions. The policies this task adds are the main measurement; write each one so the report can count them.
- Computed fields: `pg_graphql` exposes a function whose only argument is a table row type as a field on that type.

## Verification

```
cd backend && supabase db reset && supabase test db
curl -s localhost:54321/graphql/v1 -H "apikey: <local anon key>" -H "Authorization: Bearer <persona token>" -d '{"query":"..."}'
```

## Definition of done

- [ ] All acceptance criteria pass on the spike branch
- [ ] pgTAP tests added and passing locally
- [ ] The backend half of the report is committed on the slice branch
- [ ] No work outside Scope

## Open questions

None.
