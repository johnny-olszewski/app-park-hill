# Backend

Local Supabase project: migrations, seed, Edge Functions and pgTAP tests. Local Supabase is the only instance for now, the default Dev target for both apps, and the permanent test environment for CI.

## Environment

This instance is **disposable**. It is safe to reset at any time, and it never holds real user data. Anything that must survive a reset belongs in a migration.

## Requirements

- Docker, running
- Supabase CLI **2.120.0**, the version CI uses. Check with `supabase --version`.
- Python 3.10 or later (standard library only), for the data generators

## Commands

Run from `/backend`.

| Task | Command |
|---|---|
| Start the stack, including the Edge Functions runtime | `supabase start` |
| Show URLs and local keys | `supabase status` |
| Rebuild the database from migrations plus `seed.sql` | `supabase db reset` |
| Run pgTAP tests in `supabase/tests` | `supabase test db` |
| Serve Edge Functions with logs in the foreground | `supabase functions serve` |
| Stop the stack (keeps data) | `supabase stop` |
| Stop and delete local data | `supabase stop --no-backup` |
| Regenerate `seed.sql` from the dataset | `make seed` |
| Reset, then regenerate contract fixtures from the live backend | `make fixtures` |
| Regenerate everything and fail on any difference from git | `make data-check` |

Only one local Supabase project can use these ports at a time. If `supabase start` reports a port already allocated, stop the other project with `supabase stop --project-id <id>`.

## Ports

Pinned in `supabase/config.toml`. Client Dev configs default to the API URL.

| Service | Port |
|---|---|
| API (REST, Auth, Storage, Edge Functions) | 54321 |
| Database | 54322 |
| Studio | 54323 |
| Mailpit (local email) | 54324 |
| Analytics | 54327 |
| Shadow database | 54320 |
| Connection pooler (disabled) | 54329 |
| Edge Functions inspector | 8083 |

## Layout

| Path | Contents |
|---|---|
| `supabase/config.toml` | Local stack configuration |
| `supabase/migrations/` | Schema and app configuration, as `<timestamp>_name.sql` |
| `supabase/seed.sql` | Test data, loaded after migrations on reset |
| `supabase/functions/` | Edge Functions |
| `supabase/tests/` | pgTAP tests, as `*.test.sql` |

## Personas

Local accounts for development and tests. They exist **only in local Supabase**, created by `seed.sql`, and are never real people.

| Persona | Email | State |
|---|---|---|
| `attendee` | `attendee@parkhill.test` | Active |
| `admin` | `admin@parkhill.test` | Active |
| `disabled` | `disabled@parkhill.test` | Banned |

Shared local password: `parkhill-local`.

## Generated data

`/contract/seed/dataset.json` is the single source of personas and seed data. Never edit `supabase/seed.sql` or anything in `/contract/fixtures` by hand:

1. Change `dataset.json` (or a migration, for screens and strings).
2. Run `make fixtures`: regenerates `seed.sql`, resets local Supabase, signs in as each active persona and anonymously, calls every registered screen and rewrites `/contract/fixtures`.
3. Commit the dataset and the generated files together.

Fixture layout: `get_entry.json` and `get_screen.<key>.json` at the root are the signed-out responses; `<persona>/get_screen.<key>.json` are an active persona's. `make data-check` regenerates both, checks persona consistency (dataset, accounts, profiles, fixture folders) and fails if anything differs from what is committed.

## Rules

- **App configuration goes in migrations.** Screens, strings and tabs are migration data, so they reach hosted projects.
- **`seed.sql` is test data only**: test accounts and test content. It never reaches a hosted project.
- **Every signed-in function calls `internal.require_active_user()` first.** It returns the caller's id, or raises `session_ended` when there is no valid user or the account is banned or deleted, so a disabled account is refused on its next request.
- **All schema changes are migrations.** Nothing is configured by hand in Studio or a dashboard.
- **No hosted secrets in the repo.** Never commit a hosted project ref, access token or service role key. The keys `supabase status` prints are the CLI's fixed local defaults and only work against this local stack.
