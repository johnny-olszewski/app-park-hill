---
type: epic
id: EP-03
title: "Community"
status: Planning
specs: [specs/COMMUNITY.md, specs/ROLES.md]
depends_on: [EP-02]
---

# EP-03: Community

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

- [EP-03.A: Each person's Community tab shows their own groups](../slices/EP-03.A-each-persons-community-tab-shows-their-own-groups.md)
- [EP-03.B: Staff browse all groups](../slices/EP-03.B-staff-browse-all-groups.md)
- [EP-03.C: Members leave and leaders swipe to remove](../slices/EP-03.C-members-leave-and-leaders-swipe-to-remove.md)
- [EP-03.D: Leaders edit their group in one pass](../slices/EP-03.D-leaders-edit-their-group-in-one-pass.md)
- [EP-03.E: Staff create and delete groups](../slices/EP-03.E-staff-create-and-delete-groups.md)

## Tasks

Every file in `docs/tasks/` with `epic: EP-03`. `docs/backlog.base` lists them with their status.
