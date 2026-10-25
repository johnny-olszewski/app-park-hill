# Backend

Local Supabase project: migrations, seed, Edge Functions and pgTAP tests. Local Supabase is the only instance for now, the default Local target for both apps, and the permanent test environment for CI.

## Environment

This instance is **disposable**. It is safe to reset at any time, and it never holds real user data. Anything that must survive a reset belongs in a migration.

## Requirements

- Docker, running
- Supabase CLI **2.120.0**, the version CI uses. Check with `supabase --version`.
- Python 3.10 or later (standard library only), for the data generators
- `psql`, for the name check in `make data-check`

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
| Reset, then regenerate mock responses from the live backend | `make mock-responses` |
| Regenerate the client name constants from `contract/names.json` | `make names` |
| Regenerate the client models from `contract/screens` and `contract/types` | `make models` |
| Regenerate everything and fail on any difference from git | `make data-check` |
| Run the Edge Function tests (stack running) | `make test-functions` |
| Run the unit tests for the data scripts (no stack needed) | `make test-scripts` |

Only one local Supabase project can use these ports at a time. If `supabase start` reports a port already allocated, stop the other project with `supabase stop --project-id <id>`.

## Ports

Pinned in `supabase/config.toml`. Client Local configs default to the API URL.

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
| `tests/functions/` | Edge Function tests |
| `scripts/` | Data generators and checks used by the Makefile |

## Edge Functions

`supabase start` serves every function in `supabase/functions/` at `http://127.0.0.1:54321/functions/v1/<name>`. After adding a function or changing `config.toml`, restart the stack (`supabase stop && supabase start`). If an edit to a function's code does not take effect, restart the runtime: `docker restart supabase_edge_runtime_app-park-hill`.

| Function | Purpose |
|---|---|
| `sign_in` | Email and password sign-in with backend-decided, localized errors and attempt limiting (`specs/AUTH.md` 5.5). Thresholds are the `LIMITS` block in `supabase/functions/sign_in/index.ts` |

Function tests are black-box HTTP tests in `tests/functions/` (Python, standard library). They reset sign-in attempts and restore any strings they change.

`sign_in` never logs or stores the request body. Attempts are stored in `auth_attempts` with the email as a keyed hash; only the service role can read them.

## Personas

Local accounts for development and tests. They exist **only in local Supabase**, created by `seed.sql`, and are never real people.

| Persona | Email | State |
|---|---|---|
| `attendee` | `attendee@parkhill.test` | Active |
| `admin` | `admin@parkhill.test` | Active |
| `disabled` | `disabled@parkhill.test` | Banned |

Shared local password: `parkhill-local`.

## Generated data

`/contract/seed/dataset.json` is the single source of personas and seed data. Each persona has an `id`, `email`, `display_name`, `description`, `state` (`active` or `banned`) and optional `roles`: assigned role keys beyond attendee, which every account gets. Each group has an `id`, `type` (a group type key), `name`, `description`, `meeting_day` (ISO, 1 Monday to 7 Sunday), `meeting_time` (`HH:MM`, local to the church time zone), `location`, and the persona ids of its `members` and `leaders` (every leader is also a member). Never edit `supabase/seed.sql` or anything in `/contract/mock_responses` by hand:

1. Change `dataset.json` (or a migration, for screens and strings).
2. Run `make mock-responses`: regenerates `seed.sql`, resets local Supabase, signs in as each active persona and anonymously, calls every registered screen and rewrites `/contract/mock_responses`.
3. Commit the dataset and the generated files together.

Mock response layout: `get_entry.json` and `get_screen.<key>.json` at the root are the signed-out responses; `<persona>/get_screen.<key>.json` and `<persona>/whoami.json` are an active persona's; `<persona>/get_screen.<key>@<param>=<value>.json` is a screen with params that a `navigate` action in that persona's responses opens. `make data-check` regenerates both, checks persona consistency (dataset, accounts, profiles, mock response folders) and fails if anything differs from what is committed.

### Contract names

`/contract/names.json` is the one place backend function names and screen keys clients use are written. `make names` generates `ContractNames.swift` and `ContractNames.kt` in `/contract/generated`, which both apps compile. Adding a client-called function or a backend screen: add its name to `names.json`, run `make names`, and commit both with the migration.

`make data-check` also runs `scripts/check_names.py` against the reset database. It fails when a listed RPC function is not in `public` or not executable by `anon` or `authenticated`, when a listed Edge Function has no folder in `supabase/functions/`, or when the screen keys in `names.json` and the `screens` table differ in either direction.

### Contract descriptions

`/contract/screens/<key>.schema.json` describes each backend screen's data once, and `/contract/types/<TypeName>.schema.json` each shared type: the screen envelope, the other responses and their parts (`contract/README.md`, Contract descriptions). `/contract/responses.json` maps each mock response to its type. `make models` generates the Swift and Kotlin model for each screen and type into `/contract/generated`. Adding or changing a response: change its migration and its description together, map any new mock response in `responses.json`, run `make mock-responses` and `make models`, and commit everything.

`make data-check` also runs `scripts/check_models.py` after regenerating the mock responses. It fails when a screen key in `names.json` has no description (or a description has no key); when a mock response has no type in `responses.json`, a mapping names no mock response or no type, or a type is used by nothing; and when any mock response does not match its type, or any recorded screen envelope's data, including each tab's `screen` in `get_tabs`, does not match its screen's description: a missing required field, a field its description lacks, a value of the wrong type or outside its `enum`, or a union value whose `type` is none of its members'. Examples in `/contract/types/examples` are checked against their types the same way. It names the mock response, the field and the problem.

## Rules

- **App configuration goes in migrations.** Screens, strings and tabs are migration data, so they reach hosted projects.
- **`seed.sql` is test data only**: test accounts and test content. It never reaches a hosted project.
- **Every signed-in function calls `internal.require_active_user()` first.** It returns the caller's id, or raises `session_ended` when there is no valid user or the account is banned or deleted, so a disabled account is refused on its next request.
- **All schema changes are migrations.** Nothing is configured by hand in Studio or a dashboard.
- **No hosted secrets in the repo.** Never commit a hosted project ref, access token or service role key. The keys `supabase status` prints are the CLI's fixed local defaults and only work against this local stack.
