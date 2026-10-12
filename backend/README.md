# Backend

Local Supabase project: migrations, seed, Edge Functions and pgTAP tests. Local Supabase is the only instance for now, the default Dev target for both apps, and the permanent test environment for CI.

## Environment

This instance is **disposable**. It is safe to reset at any time, and it never holds real user data. Anything that must survive a reset belongs in a migration.

## Requirements

- Docker, running
- Supabase CLI **2.120.0**, the version CI uses. Check with `supabase --version`.

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

## Rules

- **App configuration goes in migrations.** Screens, strings and tabs are migration data, so they reach hosted projects.
- **`seed.sql` is test data only**: test accounts and test content. It never reaches a hosted project.
- **All schema changes are migrations.** Nothing is configured by hand in Studio or a dashboard.
- **No hosted secrets in the repo.** Never commit a hosted project ref, access token or service role key. The keys `supabase status` prints are the CLI's fixed local defaults and only work against this local stack.
