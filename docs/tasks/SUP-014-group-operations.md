# SUP-014: Build the group operations with permission checks and all-or-nothing saves

| Field | Value |
|---|---|
| Area | backend |
| Epic | EP-03 |
| Depends on | SUP-010, SUP-011 |
| Paired with | None |
| Status | Draft |

## Intent

Make every change to groups go through backend functions that re-check permission on every call, so a stale screen can never do what the user is no longer allowed to do, and an edit-mode save is never half applied.

## Scope

- `save_group_changes(group_id, batch)`: details, adds, removals, leader additions, leader removals in one transaction.
- `remove_member`, `leave_group`, `create_group`, `delete_group` (archive).
- Localized, per-item errors for the batch; localized messages for every refusal.

## Out of scope

- Screens (SUP-012, SUP-013).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | A valid batch applies every change; any invalid item applies none and returns errors keyed to the field or row | All or nothing, with problems shown in place |
| AC2 | Every change in a batch is permission checked individually; one disallowed item fails the whole batch | Stale edit capabilities cannot slip through |
| AC3 | `leave_group` ends membership and leadership; a group may be left leaderless | Nobody is trapped in a group |
| AC4 | `remove_member` refuses a leader removing another leader | Leaders cannot bypass leader rules |
| AC5 | `delete_group` archives; the group disappears from every screen | Safe, reversible delete |
| AC6 | Each function refuses a disabled account with `session_ended` and a user without permission with a documented error | Server-side enforcement on every call |
| AC7 | pgTAP tests cover AC1 to AC6 | Enforced, not documented |

## Technical notes

- Functions are `security definer` with fixed `search_path`; each starts with `require_active_user()` then `has_permission` per change.

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
