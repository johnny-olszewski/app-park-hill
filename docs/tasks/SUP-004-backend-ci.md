# SUP-004: Add backend CI on GitHub Actions against local Supabase

| Field | Value |
|---|---|
| Area | backend, ci |
| Epic | EP-01 |
| Depends on | SUP-003 |
| Paired with | None |
| Status | Done |

## Intent

Make the backend contract machine-enforced on every PR, using local Supabase so no hosted project is needed. Also sets the repo-wide rules every platform's CI plugs into.

## Scope

- Backend workflow triggered on pull requests touching `/backend` or `/contract`.
- Local Supabase started inside the job.
- Repo-wide: the never-merge-red rule (guide 7.1 rule 10), a pre-push hook for fast local checks, pinned Supabase CLI version.

## Out of scope

- iOS and Android jobs (IOS-004, AND-004).
- Edge Function tests and persona check (SUP-007).
- Deployment, hosted Supabase migrations.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Backend job runs `supabase start`, `supabase db reset`, `supabase test db`, and passes | The contract is verified on every change |
| AC2 | The job runs on any change under `/backend` or `/contract` | Contract changes are always tested |
| AC3 | A change under `/backend` or `/contract` also triggers the iOS and Android jobs once they exist (IOS-004, AND-004) | Clients are validated against contract changes |
| AC4 | The Supabase CLI version in CI matches the version pinned in `/backend/README.md` | Local and CI behave the same |
| AC5 | Every CI job reports its result on the PR, and the guide forbids merging a PR with a failing or pending check (7.1 rule 10) | Tasks cannot be marked done with failing checks, without paid branch protection |
| AC6 | `.githooks/pre-push`, enabled with `git config core.hooksPath .githooks`, runs `supabase test db` before a push that changes `/backend` or `/contract` when local Supabase is running, and says it skipped them when it is not | Cheap failures are caught before CI |

## Technical notes

- Ubuntu runner; Docker is available there.

## Verification

Open a PR that breaks a pgTAP test; the backend job fails. Revert; green.

## Definition of done

- [ ] All acceptance criteria pass
- [ ] No work outside Scope

## Open questions

None.
