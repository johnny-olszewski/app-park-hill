# EP-03: Community

| Field | Value |
|---|---|
| Status | Planning |
| Specs | [specs/COMMUNITY.md](../specs/COMMUNITY.md), [specs/ROLES.md](../specs/ROLES.md) |
| Depends on | [EP-02: Tabs](EP-02-tabs.md) |
| Followed by | [EP-04: People and roles](EP-04-people-and-roles.md) |

## Goal

The Community tab gives each person exactly their own community groups, lets leaders and staff manage groups in the app, and proves that roles and permissions drive what each person sees and can do, enforced by the backend.

## Out of scope

- Affiliate groups, the people directory screen, profiles.
- Role management UI (EP-04). Roles come from seed data until then.
- Join requests, notifications, messaging.

## User stories

| # | Story | Epic-level acceptance criteria |
|---|---|---|
| 1 | As someone in no group, I understand why my Community tab is empty | The tab shows the backend's empty message and no actions I cannot use |
| 2 | As a member of one group, my Community tab opens straight to my group | I see its details, leaders and members without an extra tap |
| 3 | As a member of several groups, I see a list of my groups | Groups I lead come first; tapping one opens its detail |
| 4 | As a member, I can leave a group | After confirming, I land on an updated Community tab |
| 5 | As a leader, I can update my group in one pass | In edit mode I change details, add and remove members; Done saves everything or nothing; Cancel undoes everything |
| 6 | As a leader, I can quickly remove someone | Swiping a member row removes them after a confirmation |
| 7 | As staff, I can browse and manage every group | A toolbar button opens all groups with search; I can assign leaders, create groups and delete (archive) them; leaderless groups are flagged |
| 8 | As anyone, I never stay on something I lost access to | If I am removed or leave, the screen closes, the one below refreshes and I see why |
| 9 | As the church, permissions are enforced no matter what the app shows | A stale button or direct request for something I may not do is refused by the backend |
| 10 | As the product owner, I can change Community wording and navigation without a release | String and navigation target changes in the backend show on both platforms after refresh |
| 11 | As a developer, I can run Community as any persona without a backend | Mock fixtures per persona match the real backend's output |

## Exit criteria

1. All EP-03 tasks are Done.
2. A demo script passes on both platforms for every persona, in Mock and Dev.
3. Every permission matrix row has an allowed and a refused backend test.
4. `specs/COMMUNITY.md` and `specs/ROLES.md` match what was built.

## Tasks

### Backend (SUP)

| Task | Depends on | Status |
|---|---|---|
| [SUP-009: Add data-driven roles, permissions and the permission check](../tasks/SUP-009-roles-and-permissions.md) | SUP-005 | Draft |
| [SUP-010: Add the groups schema, server-side rules and group personas](../tasks/SUP-010-groups-schema-and-seed.md) | SUP-009 | Draft |
| [SUP-011: Extend the screen contract with toolbar, actions and shared group types](../tasks/SUP-011-toolbar-actions-and-shared-types.md) | SUP-003 | Draft |
| [SUP-012: Build the Community screens: home, browse and group detail](../tasks/SUP-012-community-screens.md) | SUP-008, SUP-010, SUP-011 | Draft |
| [SUP-013: Build the people picker and create-group screens](../tasks/SUP-013-picker-and-create-screens.md) | SUP-012 | Draft |
| [SUP-014: Build the group operations with permission checks and all-or-nothing saves](../tasks/SUP-014-group-operations.md) | SUP-010, SUP-011 | Draft |

### iOS (IOS)

| Task | Depends on | Status |
|---|---|---|
| [IOS-009: Build iOS toolbar, action handling and shared screen behavior](../tasks/IOS-009-actions-toolbar-and-screen-infrastructure.md) | IOS-008, SUP-011 | Draft |
| [IOS-010: Build the iOS Community home and Browse all groups screens](../tasks/IOS-010-community-home-and-browse.md) | IOS-009, SUP-012 | Draft |
| [IOS-011: Build the iOS group detail view and screen](../tasks/IOS-011-group-detail.md) | IOS-010, SUP-012, SUP-014 | Draft |
| [IOS-012: Build the iOS people picker and create-group form](../tasks/IOS-012-people-picker-and-create-group.md) | IOS-009, SUP-013 | Draft |
| [IOS-013: Build iOS group edit mode with batched changes](../tasks/IOS-013-group-edit-mode.md) | IOS-011, IOS-012, SUP-014 | Draft |
| [IOS-014: Add iOS Community UI tests per persona against local Supabase (local)](../tasks/IOS-014-community-ui-tests-per-persona.md) | IOS-013, SUP-014 | Draft |

### Android (AND)

| Task | Depends on | Status |
|---|---|---|
| [AND-009: Build Android toolbar, action handling and shared screen behavior](../tasks/AND-009-actions-toolbar-and-screen-infrastructure.md) | AND-008, SUP-011 | Draft |
| [AND-010: Build the Android Community home and Browse all groups screens](../tasks/AND-010-community-home-and-browse.md) | AND-009, SUP-012 | Draft |
| [AND-011: Build the Android group detail view and screen](../tasks/AND-011-group-detail.md) | AND-010, SUP-012, SUP-014 | Draft |
| [AND-012: Build the Android people picker and create-group form](../tasks/AND-012-people-picker-and-create-group.md) | AND-009, SUP-013 | Draft |
| [AND-013: Build Android group edit mode with batched changes](../tasks/AND-013-group-edit-mode.md) | AND-011, AND-012, SUP-014 | Draft |
| [AND-014: Add Android Community UI tests per persona against local Supabase (local)](../tasks/AND-014-community-ui-tests-per-persona.md) | AND-013, SUP-014 | Draft |
