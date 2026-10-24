---
type: epic
id: EP-04
title: "People and roles"
status: Planning
specs: [specs/PEOPLE.md, specs/ROLES.md]
depends_on: [EP-03]  # browse, group detail, edit-mode pattern
---

# EP-04: People and roles

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
2. A demo script passes on both platforms for every persona, in Mock and Local.
3. Visibility is tested for every field and viewer type.
4. The temporary sign-out location from EP-02 is gone.

## Tasks

Every file in `docs/tasks/` with `epic: EP-04`. `docs/backlog.base` lists them with their status.
