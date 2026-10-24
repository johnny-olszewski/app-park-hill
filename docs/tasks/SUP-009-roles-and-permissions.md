---
type: task
id: SUP-009
title: "Add data-driven roles, permissions and the permission check"
area: backend
epic: EP-03
depends_on: [SUP-005]
paired_with: []
status: Done
---

# SUP-009: Add data-driven roles, permissions and the permission check

## Intent

Make roles and permissions data, not code, so a role's permissions can change without a release, and give every backend function one way to ask "may this user do this". Derived roles (member, leader) are computed, never stored.

## Scope

- Tables `roles`, `permissions`, `role_permissions`, `user_roles` in migrations, seeded with attendee, staff, admin and the permissions in `specs/ROLES.md`.
- Every new account gets the attendee role automatically.
- Effective roles: assigned roles plus roles derived from memberships via `group_types` (added in SUP-010; until then assigned roles only).
- `has_permission(user, permission, group)` over effective roles; group-scoped permissions apply only to that group.
- Every rule checks a permission, never a role name.
- Rule: the last admin cannot lose the admin role.
- Personas updated: `admin` holds staff and admin roles.
- Each table in Scope has a nullable `org_id uuid` column, null in every row (guide 4, organization scoping).

## Out of scope

- Groups tables (SUP-010).
- Role management UI (EP-04).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | The roles and permissions in `specs/ROLES.md` exist after `supabase db reset` with an empty seed | Configuration reaches hosted projects |
| AC2 | Creating an account gives it the attendee role in the same transaction | Every user has a baseline role |
| AC3 | `has_permission` returns true for a permission granted by any of the user's roles and false otherwise | Permissions are the union of roles |
| AC4 | Changing a `role_permissions` row changes `has_permission` results with no code change | Roles are data driven |
| AC5 | Removing the admin role from the last admin is refused with a documented error | The church cannot lock itself out |
| AC6 | Clients cannot read or write these tables directly | All access goes through functions |
| AC7 | pgTAP tests cover AC1 to AC6 | Enforced, not documented |
| AC8 | No function or policy compares a role name; a code search for role keys outside seed and migrations data finds none | Roles stay data, so new roles need no code |
| AC9 | `roles`, `permissions`, `role_permissions` and `user_roles` each have a nullable `org_id uuid` column with no default, null in every row after `supabase db reset`; no function or policy reads it | Ready for more than one organization without a migration of existing tables |

## Technical notes

- `specs/ROLES.md` is the source for role and permission keys.
- `has_permission` is `security definer`, stable, with a fixed `search_path`.

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

None. Resolved 2026-10-23: every table holding church data gets a nullable `org_id`, null for now (guide 4).
