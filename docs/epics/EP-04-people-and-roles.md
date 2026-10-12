# EP-04: People and roles

| Field | Value |
|---|---|
| Status | Planning |
| Specs | [specs/PEOPLE.md](../specs/PEOPLE.md), [specs/ROLES.md](../specs/ROLES.md) |
| Depends on | [EP-03: Community](EP-03-community.md) (browse, group detail, edit-mode pattern) |

## Goal

Every person has one detail screen that is their profile and how others see them. People eligible for the directory find each other while choosing what they share, and admins manage staff and admin roles in the app. Access is expressed only through permissions, so future kinds of membership (such as serving teams) slot in as data.

## Out of scope

- Serving teams, affiliate groups.
- Creating roles or editing a role's permissions in the app.
- Account creation, password reset, email changes, tap to call or text.

## User stories

| # | Story | Epic-level acceptance criteria |
|---|---|---|
| 1 | As a signed-in person, I can reach my profile and sign out from any tab | An Account button on every tab root opens my person detail, which has sign-out |
| 2 | As a person, I keep my details current | In edit mode I change my name, phone and photo; Done saves everything or nothing |
| 3 | As a member, I choose what I share | Eye icons on photo, phone and groups control what others see; name and email are always visible; I start listed with those fields hidden |
| 4 | As a member, I can find other people in the directory | While listed, I see listed people in Browse; if I unlist, I lose directory access |
| 5 | As staff, I can see every member and staff person | I see everyone eligible, including unlisted people (badged), but only the fields they expose; I am always listed |
| 6 | As anyone, I can see who is in a group | Member rows in group detail open each person's detail |
| 7 | As an admin, I can make someone staff or admin | Edit roles on their detail opens toggles; Save applies them together; the last admin cannot be removed |
| 8 | As an attendee with no group, I am not exposed | I have no directory, no listing and no eye icons, and I do not appear in the directory |
| 9 | As the church, new kinds of membership need no rework | A test proves a new group type and role inherit directory rules with no code change |

## Exit criteria

1. All EP-04 tasks are Done.
2. A demo script passes on both platforms for every persona, in Mock and Dev.
3. Visibility is tested for every field and viewer type.
4. The temporary sign-out location from EP-02 is gone.

## Tasks

### Backend (SUP)

| Task | Depends on | Status |
|---|---|---|
| [SUP-015: Extend profiles with phone, photo and directory visibility](../tasks/SUP-015-people-profiles-and-visibility.md) | SUP-010 | Draft |
| [SUP-016: Build the person detail screen and the account toolbar item](../tasks/SUP-016-person-screen-and-account-item.md) | SUP-012, SUP-015 | Draft |
| [SUP-017: Add the directory part to Browse and the browse button rule](../tasks/SUP-017-directory-in-browse.md) | SUP-015, SUP-016 | Draft |
| [SUP-018: Build profile and role saving with all-or-nothing batches](../tasks/SUP-018-profile-and-role-operations.md) | SUP-015 | Draft |

### iOS (IOS)

| Task | Depends on | Status |
|---|---|---|
| [IOS-015: Build the iOS person detail screen and account entry](../tasks/IOS-015-person-detail.md) | IOS-011, SUP-016 | Draft |
| [IOS-016: Build iOS profile edit mode with photo upload](../tasks/IOS-016-profile-edit-mode.md) | IOS-015, SUP-018 | Draft |
| [IOS-017: Add the iOS directory and segmented control to Browse](../tasks/IOS-017-browse-segments-and-directory.md) | IOS-010, SUP-017 | Draft |
| [IOS-018: Build the iOS Edit roles half sheet](../tasks/IOS-018-edit-roles-sheet.md) | IOS-015, SUP-018 | Draft |
| [IOS-019: Add iOS people and directory UI tests per persona against local Supabase (local)](../tasks/IOS-019-people-ui-tests-per-persona.md) | IOS-016, IOS-017, IOS-018, SUP-018 | Draft |

### Android (AND)

| Task | Depends on | Status |
|---|---|---|
| [AND-015: Build the Android person detail screen and account entry](../tasks/AND-015-person-detail.md) | AND-011, SUP-016 | Draft |
| [AND-016: Build Android profile edit mode with photo upload](../tasks/AND-016-profile-edit-mode.md) | AND-015, SUP-018 | Draft |
| [AND-017: Add the Android directory and segmented control to Browse](../tasks/AND-017-browse-segments-and-directory.md) | AND-010, SUP-017 | Draft |
| [AND-018: Build the Android Edit roles half sheet](../tasks/AND-018-edit-roles-sheet.md) | AND-015, SUP-018 | Draft |
| [AND-019: Add Android people and directory UI tests per persona against local Supabase (local)](../tasks/AND-019-people-ui-tests-per-persona.md) | AND-016, AND-017, AND-018, SUP-018 | Draft |
