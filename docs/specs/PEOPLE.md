# Spec: People and roles

Status: Approved 2026-10-10. Epic: EP-04 (`epics/EP-04-people-and-roles.md`). Roles and permissions: `specs/ROLES.md`. Builds on `specs/COMMUNITY.md`. Governed by `ENGINEERING_GUIDE.md`.

## 1. Goal

Every signed-in person has a person detail screen that is both their own profile and how others see them. People eligible for the directory can find each other, choosing what they share. Admins manage staff and admin roles in the app.

## 2. Access rules (all expressed as permissions; see `specs/ROLES.md`)

| Rule | Permission |
|---|---|
| Eligible for the directory: listed by default, may view the directory only while listed | `directory.eligible` (member, staff, admin; later server) |
| Cannot unlist; always listed | `directory.always_listed` (staff, admin) |
| Sees every eligible person, listed or not | `people.view_all_eligible` (staff, admin) |
| Edits someone's staff and admin roles | `roles.assign_staff`, `roles.assign_admin` (admin) |

- Attendees with no group (no `directory.eligible`) have no directory, no "show in directory" setting and no eye icons.
- **Everyone, staff and admins included, sees only the fields a person exposes.** Name and email are always visible to anyone who can see the person.
- Losing eligibility (for example leaving the last community group) removes the person from the directory and their directory access. Their settings are kept for when they regain it.

## 3. Fields and visibility

| Field | Visibility control |
|---|---|
| Name | Always visible |
| Email | Always visible, no eye icon. Not editable in the app |
| Photo | Eye icon |
| Phone | Eye icon |
| Community groups | Eye icon |

- Defaults when someone first becomes eligible: **listed in the directory**, photo, phone and groups **hidden**.
- Eye icons are shown on your own detail whenever you are eligible (not only when listed), because staff can always see you.

## 4. Screens

### 4.1 Account toolbar item

One backend helper adds an "Account" toolbar item (`navigate` to `people.person` for the current user, presentation `sheet`) to every tab root, in `get_tabs` and `get_screen`. A backend test checks every root has it. It replaces the temporary sign-out location from EP-02.

### 4.2 `people.person` (params: `user_id`)

- **Header:** photo (if visible), name. **Fields:** email, phone (if visible), community groups as `GroupRow`s (if visible; a row is tappable only if the viewer may open that group).
- **Own detail:** every field with its eye icon state, the "Show in directory" switch (only without `directory.always_listed`), an Edit button, and a destructive "Sign out" at the bottom with a backend confirmation. Sign-out runs the client's auth service.
- **Someone else's detail:** only the fields they expose.
- **Edit roles:** a toolbar button for viewers with `roles.assign_staff` or `roles.assign_admin`, on anyone's detail including their own.
- Member rows in group detail navigate here.

### 4.3 Profile edit mode (own detail only)

- Same pattern as group detail: everything batched until Done, all or nothing; Cancel discards everything.
- Editable: display name (required, length limit), phone (validated, stored in international format, displayed formatted by the backend), photo (choose from camera or library, square crop, max 1024 px, JPEG; remove), each eye toggle, and "Show in directory".

### 4.4 Edit roles half sheet

- Toggles for assignable roles only (today: staff, admin), with backend names and one-line descriptions. Attendee, member and leader are not shown.
- Save applies all changes together, all or nothing; Cancel discards.
- Removing the last admin is refused with the backend message. Changes take effect on the person's next request or refresh.

### 4.5 Browse (`community.browse`), extended

- Data holds optional `groups` (from `groups.view_all`) and `directory` (from `directory.view`) parts, each with its segment title, search placeholder and rows.
- The client shows a segmented control only when both parts are present; otherwise only the present part.
- The browse toolbar button appears only when at least one part exists; its label comes from the backend (for example "Directory" when that is all).
- Directory rows: `PersonRow` with photo when visible, sorted by name, on-device search, navigating to `people.person`. Viewers with `people.view_all_eligible` see everyone eligible, with a "Not in directory" badge on unlisted people.

## 5. Backend

- `profiles` gains phone, photo path, `listed`, and per-field visibility flags, with the defaults above applied when eligibility begins.
- Photos in a private Supabase Storage bucket; screens receive short-lived signed links (user content, not image keys).
- Functions: `get_screen` for `people.person`; directory part of `community.browse`; `save_profile_changes(batch)` (all or nothing); `save_roles(user_id, roles)` (all or nothing, last-admin rule). Each starts with `require_active_user()` and checks permissions.

## 6. Personas (additions)

| Persona | Situation |
|---|---|
| `member_unlisted` | Member of one group, switched "show in directory" off |
| `member_shared` | Member who exposes photo, phone and groups |

The dataset gives some personas phones and photos; seed and fixtures are generated from it.

## 7. Tests

- Backend: visibility of each field for each viewer type; eligibility and listing rules; `always_listed` cannot unlist; last-admin rule; batch all-or-nothing; the extensibility test from `specs/ROLES.md`.
- Clients: decoding, edit-mode staging, segmented control appearing only with both parts; UI smoke tests per persona.

## 8. Decisions

| Decision | Chosen over |
|---|---|
| Person detail as own profile and others' view | Separate account screen |
| Account toolbar item added to every tab root by one backend helper | Shell toolbar in `get_tabs`; client-owned button |
| Directory only for eligible people; members view only while listed | Directory for everyone |
| Staff and admin always listed via `directory.always_listed` | Removing attendee from staff; general deny rules |
| Everyone sees only exposed fields; staff see every eligible person | Staff see private fields; group co-members see more |
| Email always visible; eye icons always shown when eligible | Eye only when listed |
| Listed by default, fields opt in | Fully opt in; everything visible |
| Profile edit mode with photo upload, batched | No photos; immediate toggles |
| Edit roles half sheet: assignable roles only, saved together | Immediate toggles; show derived roles |
| One browse screen with optional groups and directory parts | Two screens; directory tab |
| Typed groups with data-driven derived roles; rules checked by permission | Separate tables per kind; community-only |
