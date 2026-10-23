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
| 11 | As a developer, I can run Community as any persona without a backend | Mock responses per persona match the real backend's output |

## Exit criteria

1. All EP-03 tasks are Done.
2. A demo script passes on both platforms for every persona, in Mock and Dev.
3. Every permission matrix row has an allowed and a refused backend test.
4. `specs/COMMUNITY.md` and `specs/ROLES.md` match what was built.

## Slices

Implemented in this order (guide 7.2). Each slice is one behavior on every platform and brings its own per-persona Mock and Dev UI tests. Seeing your own groups comes first because every later slice acts on those screens; browsing adds the toolbar and full-screen cover; leaving and removing add `call` actions and the lost-access rule, which editing and create and delete then reuse. Planned 2026-10-23, after EP-05 made screen data descriptions the source of client models.

| Slice | Behavior | Tasks, in order | Depends on | Status |
|---|---|---|---|---|
| [EP-03.A](#ep-03a-each-persons-community-tab-shows-their-own-groups) | Signed-in people see exactly their own groups on the Community tab, on iOS and Android | SUP-009, SUP-010, SUP-011, SUP-012, IOS-009, IOS-011, IOS-010, AND-009, AND-011, AND-010 | EP-05.D | Draft |
| [EP-03.B](#ep-03b-staff-browse-all-groups) | Staff open every group from a Browse button, with search | SUP-023, IOS-025, AND-026 | EP-03.A | Draft |
| [EP-03.C](#ep-03c-members-leave-and-leaders-swipe-to-remove) | Members leave a group and leaders remove members with one confirmed tap, and nobody stays on a group they lost | SUP-014, IOS-026, AND-027 | EP-03.B | Draft |
| [EP-03.D](#ep-03d-leaders-edit-their-group-in-one-pass) | Leaders edit details and members, and staff change leaders, saved all at once or not at all | SUP-013, SUP-024, IOS-012, IOS-013, AND-012, AND-013 | EP-03.C | Draft |
| [EP-03.E](#ep-03e-staff-create-and-delete-groups) | Staff create groups from Browse and delete (archive) them from edit mode | SUP-025, IOS-027, AND-028 | EP-03.D | Draft |

### EP-03.A: Each person's Community tab shows their own groups

| # | Behavior acceptance criterion |
|---|---|
| B1 | Signed in as `attendee` or `staff`, the Community tab shows the backend's empty message and no buttons |
| B2 | As `member_one`, `leader` or `admin`, the tab opens straight to their group: details, the leaders line, and members with leader icons and "You" on their own row |
| B3 | As `member_two`, the tab lists both groups; tapping one opens its detail, and back returns to the list |
| B4 | Pull to refresh updates a screen; with the backend stopped in Dev, a screen seen before shows its last copy |
| B5 | Changing a Community string in the database shows on both platforms after pull to refresh |
| B6 | All of the above on iOS and Android, in Mock and Dev |

### EP-03.B: Staff browse all groups

| # | Behavior acceptance criterion |
|---|---|
| B1 | `staff` and `admin` see a Browse button on Community home, in every state; other personas do not |
| B2 | Browse opens full screen and lists every group by name, with the person's own groups and leaderless groups badged; typing filters by name |
| B3 | Tapping a group in browse opens its detail; closing browse returns to home, and reopening it starts with an empty search |
| B4 | All of the above on iOS and Android, in Mock and Dev |

### EP-03.C: Members leave and leaders swipe to remove

| # | Behavior acceptance criterion |
|---|---|
| B1 | A member taps Leave, confirms with the backend's wording, and lands on an updated Community tab |
| B2 | A leader swipes a member's row, confirms, and the member is gone; a leader cannot swipe another leader's row |
| B3 | Someone removed from a group while viewing it is taken off it on the next refresh and sees "You're no longer in this group" |
| B4 | A remove made stale by a change on the backend is refused with the backend's message |
| B5 | All of the above on iOS and Android, in Mock and Dev |

### EP-03.D: Leaders edit their group in one pass

| # | Behavior acceptance criterion |
|---|---|
| B1 | A leader taps Edit, changes the details, adds people from the picker (current members marked "Already a member") and removes someone; Done saves all of it, and it is still there after relaunching |
| B2 | Cancel undoes every staged change |
| B3 | A save with a problem saves nothing, stays in edit mode and shows the problem at its field or row |
| B4 | Staff make and remove leaders in edit mode; leaders cannot |
| B5 | All of the above on iOS and Android, in Mock and Dev |

### EP-03.E: Staff create and delete groups

| # | Behavior acceptance criterion |
|---|---|
| B1 | Staff create a group from Browse; problems show at their fields; success opens the new group |
| B2 | Staff delete a group from its edit mode after confirming; it disappears from home and browse |
| B3 | Nobody but staff and admins sees Create or Delete |
| B4 | All of the above on iOS and Android, in Mock and Dev |

## Tasks

### Backend (SUP)

| Task | Depends on | Status |
|---|---|---|
| [SUP-009: Add data-driven roles, permissions and the permission check](../tasks/SUP-009-roles-and-permissions.md) | SUP-005 | Draft |
| [SUP-010: Add the groups schema, server-side rules and group personas](../tasks/SUP-010-groups-schema-and-seed.md) | SUP-009 | Draft |
| [SUP-011: Describe actions and the shared group types in the contract](../tasks/SUP-011-actions-and-shared-types.md) | SUP-022 | Draft |
| [SUP-012: Build Community home and group detail for each person](../tasks/SUP-012-community-screens.md) | SUP-008, SUP-010, SUP-011 | Draft |
| [SUP-023: Build Browse all groups and the screen toolbar](../tasks/SUP-023-browse-and-toolbar.md) | SUP-012 | Draft |
| [SUP-014: Add call actions, leaving a group and removing a member](../tasks/SUP-014-leave-and-remove.md) | SUP-012 | Draft |
| [SUP-013: Build the people picker screen](../tasks/SUP-013-people-picker.md) | SUP-014 | Draft |
| [SUP-024: Send group edit capabilities and save every change at once](../tasks/SUP-024-group-edit-and-batch-save.md) | SUP-013 | Draft |
| [SUP-025: Build group create and delete for staff](../tasks/SUP-025-create-and-delete-groups.md) | SUP-024 | Draft |

### iOS (IOS)

| Task | Depends on | Status |
|---|---|---|
| [IOS-009: Open backend screens by push, with refresh and a per-screen cache on iOS](../tasks/IOS-009-push-refresh-and-screen-cache.md) | IOS-024, SUP-011 | Draft |
| [IOS-011: Build the iOS group detail view and screen](../tasks/IOS-011-group-detail.md) | IOS-009, SUP-012 | Draft |
| [IOS-010: Build the iOS Community home for every state](../tasks/IOS-010-community-home.md) | IOS-011, SUP-012 | Draft |
| [IOS-025: Build the iOS toolbar, full-screen cover and Browse all groups](../tasks/IOS-025-toolbar-and-browse.md) | IOS-010, SUP-023 | Draft |
| [IOS-026: Handle call actions and lost access, and add leave and swipe to remove on iOS](../tasks/IOS-026-leave-remove-and-lost-access.md) | IOS-025, SUP-014 | Draft |
| [IOS-012: Build the iOS sheet presentation and people picker](../tasks/IOS-012-people-picker.md) | IOS-026, SUP-013 | Draft |
| [IOS-013: Build iOS group edit mode with batched changes](../tasks/IOS-013-group-edit-mode.md) | IOS-012, SUP-024 | Draft |
| [IOS-027: Build iOS group create and delete](../tasks/IOS-027-create-and-delete-groups.md) | IOS-013, SUP-025 | Draft |

### Android (AND)

| Task | Depends on | Status |
|---|---|---|
| [AND-009: Open backend screens by push, with refresh and a per-screen cache on Android](../tasks/AND-009-push-refresh-and-screen-cache.md) | AND-025, SUP-011 | Draft |
| [AND-011: Build the Android group detail view and screen](../tasks/AND-011-group-detail.md) | AND-009, SUP-012 | Draft |
| [AND-010: Build the Android Community home for every state](../tasks/AND-010-community-home.md) | AND-011, SUP-012 | Draft |
| [AND-026: Build the Android toolbar, full-screen cover and Browse all groups](../tasks/AND-026-toolbar-and-browse.md) | AND-010, SUP-023 | Draft |
| [AND-027: Handle call actions and lost access, and add leave and swipe to remove on Android](../tasks/AND-027-leave-remove-and-lost-access.md) | AND-026, SUP-014 | Draft |
| [AND-012: Build the Android sheet presentation and people picker](../tasks/AND-012-people-picker.md) | AND-027, SUP-013 | Draft |
| [AND-013: Build Android group edit mode with batched changes](../tasks/AND-013-group-edit-mode.md) | AND-012, SUP-024 | Draft |
| [AND-028: Build Android group create and delete](../tasks/AND-028-create-and-delete-groups.md) | AND-013, SUP-025 | Draft |
