# SUP-018: Build profile and role saving with all-or-nothing batches

| Field | Value |
|---|---|
| Area | backend |
| Epic | EP-04 |
| Depends on | SUP-015 |
| Paired with | None |
| Status | Draft |

## Intent

Make changes to your own profile and to someone's roles go through backend functions that validate, check permission on every call, and never half apply.

## Scope

- `save_profile_changes(batch)`: name, phone, photo path, photo removal, eye flags, listing; all or nothing with localized per-field errors.
- Signed upload flow for photos (client uploads to the bucket, the batch references the new path).
- `save_roles(user_id, roles)`: staff and admin; all or nothing; last-admin rule.

## Out of scope

- Screens (SUP-016, SUP-017).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | A valid profile batch applies fully; any invalid field applies nothing and returns errors keyed to fields | Same commit model as group edit mode |
| AC2 | Changing listing is refused for holders of `directory.always_listed` | Staff stay listed even through direct calls |
| AC3 | A photo path not owned by the caller is refused | No one can attach someone else's upload |
| AC4 | `save_roles` applies only for holders of the matching assign permission and refuses removing the last admin | Role changes are safe |
| AC5 | Every function refuses disabled accounts with `session_ended` | Server-side enforcement on every call |
| AC6 | pgTAP tests cover AC1 to AC5 | Enforced, not documented |

## Technical notes

- Phone validation and formatting server side.

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
