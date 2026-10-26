# Park Hill App: Backlog

Epics live in `epics/`, slices in `slices/`, tasks in `tasks/`, specs in `specs/`. Tasks follow `TASK_TEMPLATE.md` and are governed by `ENGINEERING_GUIDE.md`.

Each task targets one platform: `SUP` (backend), `IOS`, `AND`, numbered sequentially per platform. Platforms can proceed in parallel; follow each task's `depends_on` for cross-platform order.

**Before the first store upload:** replace the placeholder app identifier root (`app.parkhill.placeholder`) on both platforms; see the guide's decision log.

Work is implemented and reviewed by slice (guide 7.2): each slice groups the tasks that deliver one behavior. Epics planned before slices existed are divided into slices when their next work is planned.

## Status

Status, links and membership live once, in each file's frontmatter (guide 7.3): a task's `status`, `depends_on` and `paired_with`; a slice's `tasks`, `depends_on` and `status`; an epic's `status`. This file holds only the order of slices.

To see everything at once, open `docs/` as a vault in [Obsidian](https://obsidian.md) and open `backlog.base`: tables of slices, open tasks and epics, by status. On GitHub, each file shows its frontmatter as a table.

## Slice order

1. [EP-01.A](slices/EP-01.A-every-pr-is-checked-automatically.md): CI for backend and iOS
2. [EP-01.B](slices/EP-01.B-android-launches-to-the-backend-driven-entry.md): Android catch-up, launch and CI
3. [EP-01.C](slices/EP-01.C-android-sign-in-matches-ios.md): Android catch-up, sign-in
4. [EP-06.C](slices/EP-06.C-android-dev-tools-and-mock-sign-in.md): Android catch-up, dev tools and Mock sign-in
5. [EP-02.A](slices/EP-02.A-signed-in-people-see-the-backends-tabs.md): tabs after sign-in, on every platform
6. [EP-05.A](slices/EP-05.A-a-misspelled-name-fails-the-build-or-the-data-check.md): contract names on every platform
7. [EP-05.B](slices/EP-05.B-screen-data-is-described-once-and-checked.md): screen data described once and checked
8. [EP-05.C](slices/EP-05.C-the-apps-decode-screens-with-the-generated-models.md): the apps decode screens with the generated models
9. [EP-05.D](slices/EP-05.D-every-response-is-described-once-and-checked.md): every response described once and checked
10. [EP-03.A](slices/EP-03.A-each-persons-community-tab-shows-their-own-groups.md): each person's Community tab shows their own groups
11. [EP-03.B](slices/EP-03.B-staff-browse-all-groups.md): staff browse all groups
12. [EP-03.C](slices/EP-03.C-members-leave-and-leaders-swipe-to-remove.md): members leave and leaders swipe to remove
13. [EP-03.D](slices/EP-03.D-leaders-edit-their-group-in-one-pass.md): leaders edit their group in one pass
14. [EP-03.E](slices/EP-03.E-staff-create-and-delete-groups.md): staff create and delete groups
15. [EP-07.A](slices/EP-07.A-the-api-style-is-chosen-from-a-measured-comparison.md): the API style is chosen from a measured comparison (spike)

Android is level after EP-06.C; new feature slices include every platform.

## Epics

- [EP-01: Foundation and authentication](epics/EP-01-foundation-and-auth.md)
- [EP-02: Tabs](epics/EP-02-tabs.md)
- [EP-03: Community](epics/EP-03-community.md)
- [EP-04: People and roles](epics/EP-04-people-and-roles.md)
- [EP-05: Contract names](epics/EP-05-contract-names.md)
- [EP-06: Mock menu](epics/EP-06-mock-menu.md)
- [EP-07: API style spike](epics/EP-07-api-style-spike.md)
