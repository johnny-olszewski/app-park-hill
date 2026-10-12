# Spec: Roles and permissions

Status: Approved 2026-10-10. Epics: EP-03 (data and checks), EP-04 (people, directory and role management). Governed by `ENGINEERING_GUIDE.md`.

## 1. Roles

| Role | Kind | How someone gets it |
|---|---|---|
| attendee | Assigned | Automatically, when the account is created |
| staff | Assigned | Granted by an admin |
| admin | Assigned | Granted by an admin. Includes everything staff can do |
| member | Derived | Belongs to at least one community group. Never assigned |
| leader | Derived, per group | Leads that community group. Never assigned as a role |
| server (later) | Derived | Will come from serving teams. Not built yet |

- A person can hold any number of roles. Permissions are the union of all of them. No deny rules, no priority.
- **Typed groups.** One `groups` table with a group type. `group_types` maps each type to the role its membership grants and the role its leadership grants (community: member, leader; later serving team: server, team lead).
- **Effective roles** = assigned roles plus roles derived from memberships. Group-scoped permissions apply only to that group.
- **Every rule checks a permission, never a role name.** Adding a new kind of membership is data (a group type, a role, permission grants) plus its own screens.
- Roles map to permissions in data (`roles`, `permissions`, `role_permissions`, `user_roles`), so a role's permissions can change without a release. Creating roles and editing permissions in the app is later.

## 2. Permission matrix

"Own" means groups the person leads.

| Permission | Attendee | Member | Leader | Staff | Admin |
|---|---|---|---|---|---|
| See own groups and their members | | Yes | Yes | Yes | Yes |
| Leave a group they are in | | Yes | Yes | Yes | Yes |
| `groups.view_all` (browse and open any group) | | | | Yes | Yes |
| `groups.edit_details` | | | Own | Yes | Yes |
| `groups.add_member` | | | Own | Yes | Yes |
| `groups.remove_member` | | | Own, non-leaders only | Yes | Yes |
| `groups.assign_leader` (make or remove leader) | | | | Yes | Yes |
| `groups.create`, `groups.delete` | | | | Yes | Yes |
| `roles.assign_staff`, `roles.assign_admin` | | | | | Yes |
| `directory.eligible` (listed by default; may view directory only while listed) | | Yes | Yes | Yes | Yes |
| `directory.always_listed` (cannot unlist) | | | | Yes | Yes |
| `people.view_all_eligible` | | | | Yes | Yes |

Rules:

1. Leaders cannot remove other leaders.
2. The last admin cannot lose the admin role.
3. Any signed-in user can see every user's display name (for example in group member lists and the people picker). Other fields follow `specs/PEOPLE.md`.
4. **Directory access (`directory.view`)** is computed, not granted: a person holding `directory.eligible` who is listed, or anyone holding `directory.always_listed`.
5. **One narrow exception to additive-only:** a person may change their directory listing only if they do not hold `directory.always_listed`. This is checked as the absence of a permission and is tested both ways.

## 3. Enforcement

- `has_permission(user, permission, group)` combines assigned roles with membership and leadership. Every backend function calls `require_active_user()`, then checks permission for each change.
- Screens are built with the same check, so a button or row only appears for people who may use it. Stale screens are still refused server side.
- Every row of the matrix has one allowed and one refused backend test.
- **Extensibility test:** a test adds a temporary group type and derived role granted `directory.eligible`, and proves directory eligibility follows with no code change.
