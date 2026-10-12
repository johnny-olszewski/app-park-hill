# SUP-007: Extend backend CI for auth: Edge Function tests and dataset check

| Field | Value |
|---|---|
| Area | backend, ci |
| Epic | EP-01 |
| Depends on | SUP-004, SUP-006 |
| Paired with | None |
| Status | Draft |

## Intent

Make the sign-in rules and the single dataset (seed and mock fixtures) machine-enforced on every PR.

## Scope

- Serve Edge Functions in the backend job and run the `sign_in` tests.
- Run `make data-check` (seed and fixtures regenerated from the dataset).

## Out of scope

- Client UI tests (IOS-007, AND-007).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | The backend job serves Edge Functions and runs the `sign_in` tests (SUP-006) | Sign-in rules are enforced on every change |
| AC2 | `make data-check` runs on every PR touching `/contract` or `/backend` and fails on any difference | Seed and mock data cannot drift |
| AC3 | Both checks are required to merge | Auth stays green |

## Technical notes

- `specs/AUTH.md` 5.5, 7 and 8.

## Verification

Break a `sign_in` test, then a persona email, in separate commits; each fails the job. Revert; green.

## Definition of done

- [ ] All acceptance criteria pass
- [ ] No work outside Scope

## Open questions

None.
