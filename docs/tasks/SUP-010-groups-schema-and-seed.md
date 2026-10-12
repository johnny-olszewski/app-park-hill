# SUP-010: Add the groups schema, server-side rules and group personas

| Field | Value |
|---|---|
| Area | backend |
| Epic | EP-03 |
| Depends on | SUP-009 |
| Paired with | None |
| Status | Draft |

## Intent

Store community groups, membership and leadership with rules the database itself enforces, and give tests and the mock the same set of people and groups.

## Scope

- `group_types` (key, membership role, leadership role), seeded with `community` (member, leader).
- Tables `groups` (type, name, description, meeting day, meeting time, location, archived date), `group_members`, `group_leaders`.
- Leadership rules: a leader must be a member; removing membership removes leadership; making a leader adds membership if needed.
- Church time zone setting (America/Los_Angeles) used for formatting meeting times.
- Effective roles extended with roles derived from `group_types` (member and leader per community group).
- Seed: four groups (one leaderless) and personas per `specs/COMMUNITY.md` section 8; `dataset.json` updated; `make data-check` passes.

## Out of scope

- Screens and operations (SUP-012 to SUP-014).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Making a non-member a leader also makes them a member; removing a member also removes their leadership | Leadership always sits on top of membership |
| AC2 | Archived groups are excluded everywhere a group is listed or opened | Soft delete hides without erasing |
| AC3 | For each group-scoped row of the permission matrix in `specs/ROLES.md`, one allowed and one refused pgTAP test pass | Every permission is enforced, including the refusals |
| AC4 | A leader of one group has no leader permissions in another group | Derived permissions are scoped to the group |
| AC5 | A leader cannot remove another leader (refused) | Leaders cannot bypass assign-leader rules |
| AC6 | Seed creates the personas and groups listed in the spec; `make data-check` passes | Mock, tests and humans share the same people and groups |
| AC7 | Clients cannot read or write these tables directly (RLS) | All access goes through functions |
| AC8 | Adding a test group type with its own derived role, granted a test permission, makes `has_permission` return that permission for its members with no code change | Future kinds of membership, such as serving teams, are data only |

## Technical notes

- Group data is config-free: seed only for test groups; tables and settings in migrations.

## Verification

```
cd backend && supabase db reset && supabase test db && make data-check
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI
- [ ] No environment branching; no mock code in release builds
- [ ] Contract changes include fixtures
- [ ] No work outside Scope

## Open questions

None.
