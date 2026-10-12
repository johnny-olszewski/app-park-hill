# SUP-002: Set up the local Supabase backend project

| Field | Value |
|---|---|
| Area | backend |
| Epic | EP-01 |
| Depends on | SUP-001 |
| Paired with | None |
| Status | Draft |

## Intent

Stand up the backend as a local Supabase project that anyone, including CI, can start from a clean checkout with one command and get an identical database. This is the default Dev target and the permanent test environment.

## Scope

- Supabase CLI project in `/backend`, including the Edge Functions directory.
- Migration, seed and test structure with one trivial passing pgTAP test.
- Documented start, reset, serve-functions and test commands.

## Out of scope

- Any application tables or functions (SUP-003, SUP-005, SUP-006).
- Hosted Supabase projects, QA, Prod.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | From a clean checkout, `supabase start` in `/backend` brings up the stack, including the Edge Functions runtime, with no manual steps | The environment is reproducible, on a laptop or in GitHub Actions |
| AC2 | `supabase db reset` rebuilds the database from migrations plus `seed.sql` only | The database is fully described by the repo. No dashboard configuration |
| AC3 | `supabase test db` runs pgTAP tests in `/backend/supabase/tests` and a placeholder test passes | The test harness is proven before real logic depends on it |
| AC4 | Ports are pinned in `config.toml` (API on 54321) and listed in `/backend/README.md` | Client config defaults work on every machine |
| AC5 | `/backend/README.md` states: app configuration (screens, strings, tabs) goes in migrations; `seed.sql` is test data only and never reaches a hosted project | Hosted environments get real configuration and no test accounts |
| AC6 | `/backend/README.md` states the environment's intent: disposable, safe to reset, no real user data ever | Nobody treats the local instance as durable |
| AC7 | No hosted project ref, access token or service role key is committed | The repo stays free of secrets and uses no hosted project allowance |

## Technical notes

Guide section 4. Pin the Supabase CLI version in the README so local and CI match.

## Verification

```
cd backend && supabase start && supabase db reset && supabase test db
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally
- [ ] No work outside Scope

## Open questions

None.
