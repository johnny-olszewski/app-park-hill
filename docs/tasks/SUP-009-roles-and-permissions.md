# SUP-009: Add data-driven roles, permissions and the permission check

| Field | Value |
|---|---|
| Area | backend |
| Epic | EP-03 |
| Depends on | SUP-005 |
| Paired with | None |
| Status | Draft |

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
- [ ] Contract changes include fixtures
- [ ] No work outside Scope

## Open questions

None.
