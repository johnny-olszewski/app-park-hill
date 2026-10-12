# SUP-013: Build the people picker and create-group screens

| Field | Value |
|---|---|
| Area | backend |
| Epic | EP-03 |
| Depends on | SUP-012 |
| Paired with | None |
| Status | Draft |

## Intent

Serve the people picker and the create-group form from the backend so who can be chosen, labels and form fields are backend owned.

## Scope

- `people.picker` with `group_id`: every signed-in user's `PersonRow`, sorted by name, current members marked not selectable with a note; Add label.
- `community.group.create` (requires `groups.create`): form fields with labels and a `save` call.
- Per-persona fixtures.

## Out of scope

- The operations themselves (SUP-014).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | The picker lists every active user by display name and marks current members not selectable with the backend note | The backend decides who can be chosen |
| AC2 | The picker is refused for users without `groups.add_member` on that group | Only people who can add members can open it |
| AC3 | The create screen is refused for users without `groups.create` | Stale buttons cannot create groups |
| AC4 | Fixtures for both screens match live output | Mocks mirror the real backend |
| AC5 | pgTAP tests cover AC1 to AC3 | Enforced, not documented |

## Technical notes

- `PersonRow` from SUP-011.

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
