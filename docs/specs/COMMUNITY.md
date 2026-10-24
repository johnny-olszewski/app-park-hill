# Spec: Community tab

Status: Approved 2026-10-10. Epic: EP-03 (`epics/EP-03-community.md`). Roles and permissions: `specs/ROLES.md`. Governed by `ENGINEERING_GUIDE.md`.

## 1. Principles

1. **Navigation targets come from the backend** in each tappable item's action, so they can change without a release, provided the target screen already exists in the app.
2. **The UI is driven by the user's actions.** The backend includes a button or row only when the user may use it; the client renders what it receives. Server-side checks still apply to every request.
3. **The backend knows screens, not views.** Each screen's data model carries everything that screen needs. Views (group list, group detail, empty) are client components shared for consistency and reuse, invisible to the backend.
4. **Shared data types** (`GroupRow`, `GroupDetail`) are defined once in the contract and embedded in several screen models.

## 2. Roles and permissions

See `specs/ROLES.md` for roles (member and leader are derived from membership), the permission matrix and enforcement.

## 3. Contract additions

### 3.1 Toolbar (all screens)

The screen envelope gains an optional `toolbar` list. Absent or empty means no buttons. Backward compatible.

```json
{ "key": "...", "data": { }, "toolbar": [
  { "id": "browse_all_groups", "label": "Browse all groups", "icon_key": "toolbar.browse",
    "action": { "type": "navigate", "screen_key": "community.browse", "params": {}, "presentation": "full_screen_cover" } }
] }
```

- The backend includes an item only for users allowed to use it.
- The client styles items and moves extras into an overflow menu, in the order sent.

### 3.2 Action

Two types. Every action may carry `role: "destructive"`, a meaning each platform styles its own way.

| Type | Fields | Use |
|---|---|---|
| `navigate` | `screen_key`, `params`, `presentation` (`push`, `sheet`, `full_screen_cover`) | Move to a screen. Presentation is a hint mapped to platform equivalents |
| `call` | `function`, `params`, optional `confirm` (`title`, `message`, `confirm_label`, `cancel_label`), `on_success` (`refresh`, `dismiss`, `none`) | One-tap backend operation. The backend re-checks permission on every call |

Forms submit through a `call` in their data, with field values added.

A `call`'s result may carry `then`, an action the client performs after `on_success`. It is how a call opens something whose id exists only after the call, such as a newly created group (5.7).

### 3.3 Shared types

`GroupRow`:

```json
{ "group_id": "uuid", "title": "Tuesday Night Men's Group", "subtitle": "Tuesdays · 7:00 PM · Smith home",
  "badge": "Leader",
  "action": { "type": "navigate", "screen_key": "community.group", "params": { "group_id": "uuid" }, "presentation": "push" } }
```

`badge` is optional. All text is backend formatted and localized.

`GroupDetail`: defined in section 5.

## 4. Screens

### 4.1 `community.home` (Community tab root, always)

Data contains exactly one of `group`, `my_groups`, `empty`. The client checks them in that order and shows the first present:

| Present | User situation | View |
|---|---|---|
| `group` (`GroupDetail`) | In exactly one group | Group detail view |
| `my_groups` (`{ title, rows: [GroupRow] }`) | In two or more groups | Group list view |
| `empty` (`{ title, message }`) | In no group | Empty view, no buttons |

None present: treat as unusable (cached copy, else error screen).

- Toolbar: "Browse all groups" for users with `groups.view_all`, on every state.
- "My groups" order: groups the user leads first, then the rest, each sorted by name.
- Tab title is always "Community", from the backend.
- Pull to refresh refetches via `get_screen`.

### 4.2 `community.browse`

EP-04 extends browse with a directory part and a segmented control (`specs/PEOPLE.md` 4.5). EP-03 builds the groups part.

Presented as a full-screen cover from the toolbar. Requires `groups.view_all`; `get_screen` refuses anyone else.

- Data: `{ title, search_placeholder, rows: [GroupRow] }`, every group sorted by name, the user's own groups included with their badge.
- Rendered with the same group list view as `community.home`, plus a search field filtering the loaded rows by title on the device. No paging.
- Fetched fresh each time it opens (loading state). Search resets on close. Pull to refresh.
- Client-drawn close button with the platform's standard icon and accessibility label.

### 4.3 `community.group`

Pushed from any `GroupRow`. Uses `GroupDetail`. Section 5.

## 5. Group detail

Who can open it (as `community.group`, or as the `group` part of `community.home`): members of the group, its leaders, and anyone with `groups.view_all`. `get_screen` refuses anyone else.

### 5.1 Layout (client views; listed for clarity)

1. **Details section:** name, description, meeting day and time, location, and a "Leaders" line (for example "Leaders: Jordan Lee"). All backend-formatted.
2. **Member list:** one list of members. Leaders carry a leader icon. The current user's row is marked "You". Rows navigate to `people.person` (EP-04); until then they carry no action.
3. **Footer:** "Leave group", a large destructive button, for members.

### 5.2 Outside edit mode

- **Swipe to remove** a member row (iOS swipe action; Android swipe-to-dismiss), when the row has a `remove` action. Shows the backend confirmation, then calls immediately.
- **Leave group:** `call` with confirmation. On success the user is no longer allowed on the screen; see 5.5.

### 5.3 Edit mode

- The client shows the platform-standard Edit button when the data contains at least one edit capability. Labels for Edit, Done and Cancel come from the data.
- In edit mode:
  - **Minus button** on rows with `remove`: stages the removal. No confirmation.
  - **Leader icon** on every row with `toggle_leader`: filled for leaders, greyed out for others. Tapping stages the change. No confirmation.
  - **Add member** button when `add_member` is present: opens the people picker sheet; chosen people appear as pending rows.
  - **Details become inline fields** when `edit_fields` is present: text (name, location), multiline (description), day picker, time picker.
- **Done** sends one save with every staged change. **Cancel** discards all of them.

### 5.4 Saving

- One backend function applies the whole batch (details, adds, removals, leader additions, leader removals) in a single transaction, checking permission for every change.
- **All or nothing.** If anything fails, nothing is saved; edit mode stays open with each problem shown in place (field errors under fields, row notes such as "Already removed"), all localized by the backend.
- Done is the only commit point; nothing inside edit mode asks for confirmation.

### 5.5 Losing access while viewing

- **Leave** uses `on_success: dismiss`.
- **Dismiss on a pushed screen** closes it and refreshes the screen underneath. **Dismiss on a tab root** refreshes it in place (for example, home moves from the `group` part to `empty`).
- **Refused refresh:** when `get_screen` for a pushed screen returns `screen_unavailable`, the client closes it, refreshes the screen underneath and shows the backend's message (for example "You're no longer in this group") the platform-native way: an alert with one button on iOS, a `Snackbar` on Android (guide 5.5). No custom notice component.
- This applies to every screen, not only group detail.

### 5.6 Leaders

- A group may have zero leaders. Leaders can leave like anyone else (membership and leadership both end).
- Leaderless groups show a "No leader" badge on their browse row; the details line reads "Leaders: none yet".

### 5.7 Create and delete

- **Create:** "Create group" toolbar button on `community.browse` for staff and admins. Opens a create form sheet (`community.group.create`) with the detail fields. Saving opens the new group's detail.
- **Delete:** in edit mode, staff and admins see a destructive "Delete group" footer button: `call` with confirmation, applied immediately (outside the batch). Deleted groups are archived, not erased.

### 5.8 People picker (`people.picker`)

- Opened as a sheet from "Add member" with `group_id`.
- Lists every signed-in user's display name, sorted by name, with on-device search. No paging.
- The backend marks people who cannot be chosen (already members) with a note such as "Already a member".
- Multi-select; the Add button (backend label) returns the chosen user ids to group detail, where they appear as pending rows.
- Shared `PersonRow` type: `user_id`, `title`, optional `subtitle`, optional `note`, `selectable`. The future directory reuses it with `navigate` actions.

## 6. Client rules

- Screen cache: last good copy per screen key and params; shown on fetch failure, else error with retry. Wiped at sign-out.
- Refresh on launch, return to the app, and pull to refresh.

## 7. Backend

- Groups are typed (`group_types`; see `specs/ROLES.md`). All Community screens filter to community groups.
- Tables: `groups` (type, name, description, meeting day, meeting time, location, archived date), `group_members`, `group_leaders`. A leader must be a member; removing membership removes leadership; making a leader adds membership if needed.
- Meeting times are local times in one church time zone setting (America/Los_Angeles).
- Screens built by `get_screen`: `community.home`, `community.browse`, `community.group`, `community.group.create`, `people.picker`; the Community entry in `get_tabs` embeds `community.home` for the caller.
- Operations: `save_group_changes(group_id, batch)` (all or nothing), `remove_member`, `leave_group`, `create_group`, `delete_group` (archive). Each starts with `require_active_user()` and checks permission per change.

## 8. Personas and tests

| Persona | Situation |
|---|---|
| `attendee` | No group |
| `member_one` | Member of one group |
| `member_two` | Member of two groups |
| `leader` | Leads one group |
| `staff` | Staff, no group |
| `admin` | Staff and admin, leads one group |
| `disabled` | Disabled account (from EP-01) |

- The dataset adds four groups, one leaderless. Seed and per-persona mock responses are generated from it (`make seed`, `make mock-responses`).
- Backend: one allowed and one refused test per permission matrix row; all-or-nothing tests for the batch save.
- Clients: decoding tests for every mock response; unit tests for state inference, edit-mode staging and the lost-access rule; UI smoke tests per persona in Mock (CI) and against local Supabase (local, `make test-dev`).

## 9. Decisions

| Decision | Chosen over |
|---|---|
| Member derived from membership | Assigned role, synced or manual |
| Community tab root is always `community.home`; its data decides the view | Different root screen keys per situation |
| Browse all groups via a toolbar button opening a full-screen cover | Inset row, search entry, FAB |
| Toolbar items in the standard envelope | Per-screen fields |
| `navigate` only for now | Defining `call` now; open-ended actions |
| Backend-formatted row text | Raw fields formatted by clients |
| Browse lists all groups with own groups badged, local search | Excluding own groups; server search and paging |
| Views are client-only; screens carry full data models | Views as contract types |
| Client infers the home state from which part is present | Explicit state field |
| Group detail: details (with Leaders line), one member list with leader icons, Leave button for members; same for everyone allowed in | Separate Leaders section; member list hidden from members |
| Add `call` action for one-tap operations | Navigate-only operation screens; client-held confirmations |
| Edit capabilities in the data; client draws the Edit button | `edit_mode` toolbar action; separate edit screen |
| Inline detail editing in edit mode | Form sheet; separate toolbar button |
| Edit mode batches everything until Done; no confirmations inside it; swipe-to-remove with confirmation outside it | Immediate member changes; autosave |
| Batch save is all or nothing | Partial apply; summary confirmation |
| Lost access: close and refresh the screen below, with a backend message shown as an iOS alert or Android `Snackbar` | Dead screen; pop to root; a custom notice view on both platforms |
| Groups may be leaderless, flagged for staff | Always one leader; last leader cannot leave |
| Create from browse; delete in edit mode; archive, not erase | Create on home; no create or delete in app |
| After a call, the result's `then` says what to open next (for example the new group) | An `on_success` value that opens what was created; not opening the new group |
| People picker: multi-select, all people, local search, backend marks unselectable | Single select; server search |
| Role management in its own epic (EP-04) with an account screen | In EP-03; admin-only tab |
