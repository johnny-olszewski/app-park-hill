# Spec: Authentication

Status: Approved 2026-10-08. Epic: EP-01 (`epics/EP-01-foundation-and-auth.md`). Tasks: SUP-005 to SUP-007, IOS-005 to IOS-007, AND-005 to AND-007. Governed by `ENGINEERING_GUIDE.md`.

## 1. Goal

A person with an existing account signs in with email and password, stays signed in, and signs out. The sign-in experience is backend driven. The Mock build signs in as a chosen persona with no network.

## 2. In scope

- Email and password sign-in.
- Session persistence, silent renewal, restore on launch, sign-out.
- Backend-driven entry screen and sign-in screen content.
- Backend-decided, localized sign-in error messages.
- Mock sign-in through a persona picker.
- A temporary signed-in placeholder screen.

## 3. Out of scope (later)

- Account creation in the app. Accounts are created by seed data locally and by hand on hosted projects.
- Password reset, email verification, other sign-in methods (one-time codes, Apple, Google).
- Roles and permissions. Personas exist now; roles attach to them when the roles schema lands.
- Tabs. The placeholder screen is replaced by the tab shell in IOS-008 and AND-008.

## 4. Flows

### 4.1 Launch

1. Client checks for a stored session.
2. **Session present:** renew if needed, then show the signed-in destination (the placeholder for now; tabs later).
3. **No session:** call `get_entry(p_locale)` and render the returned screen envelope through the screen registry. Today it always returns `auth.sign_in`.
4. **`get_entry` fails:** use the last good entry envelope cached for the locale. With no cache, show the retry error screen (bundled strings).

### 4.2 Sign in

1. User enters email and password and taps the submit button.
2. Client sends them to the `sign_in` Edge Function with the standard headers.
3. **Success:** function returns a session. Client hands it to the Supabase client library, which stores it securely. Client shows the signed-in destination.
4. **Failure:** function returns an error code and a localized message. Client shows the message as given.
5. **No network:** client shows `cannot_connect_message` from the sign-in screen data.

### 4.3 Staying signed in (fail safe)

1. The session is renewed silently by the Supabase client library, directly with Supabase's auth service (not through our function).
2. If renewal is refused (account disabled, session revoked), the client clears local data (4.4) and returns to sign-in showing `session_ended_message` from the sign-in screen data.
3. **Any backend request refused as unauthorized** (token expired or invalid, or `session_ended` from our functions) triggers one silent renewal and one retry. If renewal is refused or the retry is refused again, the client signs out (4.4) and returns to sign-in showing `session_ended_message`.
4. Every signed-in backend function checks that the caller's account is still active, so a disabled account is refused on its very next request, not when its token expires.
5. Network failures never sign anyone out. With no network and a stored session, the client shows the last cached content; actions needing the backend fail with a message.

### 4.4 Sign out

1. Revoke the session with Supabase.
2. Delete everything about the user on the device: stored session, cached screens, any user files.
3. Return to the entry flow (4.1 step 3).

Sign-out succeeds locally even if the revoke call fails (no network).

## 5. Contract

### 5.1 Screen keys

| Key | Where it comes from | Purpose |
|---|---|---|
| `auth.sign_in` | `get_entry`, `get_screen` | Sign-in, in every configuration including Mock |

Naming rule: lowercase, dot separated. A key ending in `.mock` is registered only in the Mock configuration and is never returned by the real backend. Sign-in has none: Mock shows the production `auth.sign_in` (5.4).

### 5.2 `get_entry(p_locale text)`

Callable by `anon`. Returns a screen envelope:

```json
{ "key": "auth.sign_in", "data": { } }
```

### 5.3 `auth.sign_in` data

```json
{
  "title": "Sign in",
  "email_label": "Email",
  "password_label": "Password",
  "submit_label": "Sign in",
  "cannot_connect_message": "Can't connect. Check your connection and try again.",
  "session_ended_message": "You've been signed out. Please sign in again.",
  "secondary_actions": []
}
```

`secondary_actions` is empty now. It is reserved for entries the backend enables, such as "Forgot password", "Create account" or a future demo entry, once clients support those actions. It is never used for mock or debug features; those live in the dev tools menu (EP-06).

### 5.4 Sign-in in the Mock configuration

Mock shows the production `auth.sign_in` from the recorded `get_entry` response. What the next sign-in does is chosen in the dev tools menu (EP-06), not by the credentials typed:

- **Sign in as:** any active persona in `/contract/seed/dataset.json`; default the first.
- **Next sign-in:** Success (signs in as the chosen persona), a refusal from 5.5 (`invalid_credentials`, `account_disabled`, `too_many_attempts`, `invalid_request`, `unknown`, shown with its recorded message), No connection, or Something went wrong. Default Success. A choice stays until changed for the rest of the launch.

Recorded refusals: `contract/fixtures/sign_in.error.json` (`invalid_credentials`) and `sign_in.error.<code>.json` for the others. `unknown` cannot be triggered on demand, so its file is built from the same message the function sends.

### 5.5 `sign_in` Edge Function

Request (POST, JSON, standard headers):

```json
{ "email": "a@b.c", "password": "...", "locale": "en" }
```

Success, HTTP 200:

```json
{ "status": "ok", "session": { "access_token": "...", "refresh_token": "...", "expires_at": 0, "user_id": "..." } }
```

Failure, HTTP 400, 401, 403 or 429, always this shape:

```json
{ "status": "error", "code": "invalid_credentials", "message": "That email and password don't match." }
```

Error codes:

| Code | When | Message rule |
|---|---|---|
| `invalid_credentials` | Wrong email or password | Must not reveal which one was wrong or whether the email has an account |
| `account_disabled` | Account banned or disabled | |
| `too_many_attempts` | Our attempt limit hit | |
| `invalid_request` | Missing or malformed fields | |
| `unknown` | Anything else | Generic |

### 5.5.1 Session errors from other functions

Every function that requires a signed-in user starts with a shared check, `require_active_user()`. If there is no valid user, or the account is disabled, it raises the documented error `session_ended`. Expired tokens are already refused by the API with HTTP 401. Clients treat both the same way (4.3 step 3).

Messages are stored as strings (`auth.error.<code>`) and resolved for the locale, falling back to `en`.

Function rules:

1. **Attempt limiting is ours.** Failed attempts are counted per email and per client address. Above the threshold (start: 5 per email per 15 minutes, 20 per address per 15 minutes) the function refuses with `too_many_attempts` without calling Supabase's auth service.
2. **No password is ever logged or stored.** Request bodies are not logged. Emails are stored only hashed in the attempts table.
3. **Only sign-in goes through the function.** Renewal and sign-out use the client library directly.

### 5.6 Standard request headers

Sent by the production service classes on every Supabase call, including the Edge Function:

| Header | Values |
|---|---|
| `X-App-Config` | `dev` (later `qa`, `prod`) |
| `X-App-Platform` | `ios`, `android` |
| `X-App-Version` | marketing version and build, e.g. `1.0.0 (12)` |
| `Accept-Language` | device preferred language |

Headers are labels for logging and diagnostics. They are never used for access decisions. The Mock build sends nothing because it makes no requests.

## 6. Clients

### 6.1 Auth service

A separate abstraction from the backend service, selected at build time the same way.

| Operation | Purpose |
|---|---|
| `restoreSession()` | Launch: is there a usable session |
| `signIn(email, password)` | Calls the `sign_in` function; returns success or the backend error |
| `signOut()` | Revoke and clear (4.4) |
| session state stream | Emits signed in / signed out, including when renewal is refused |

- **Production class:** calls the Edge Function, then gives the session to the Supabase client library. The backend service and auth service share one Supabase client, so the access token is attached to backend calls automatically.
- **Mock class:** `signIn` takes a persona id. It sets the current persona, which the mock backend service uses to choose fixtures. No network.

### 6.2 Screens

| Screen | Configs | Notes |
|---|---|---|
| Sign in (`auth.sign_in`) | Mock and Dev registries | Native layout. All text from screen data. Secure password field, platform autofill for credentials |
| Mock sign-in tools | Mock dev tools menu only | Persona and next result for `auth.sign_in` (5.4). Live in mock-only sources |
| Signed-in placeholder | All | Not backend driven. Shows signed-in email and a sign-out button, bundled text. Lives in a `Temporary` folder. Deleted by IOS-008 and AND-008 |

### 6.3 Config and credentials

- Each Supabase-backed config has a committed config file with local Supabase values (URL and the well-known local anon key).
- An optional, gitignored override file per developer replaces those values, for example to point Dev at a hosted project.
- CI writes hosted values from GitHub secrets when QA and Prod exist.
- Every non-release build shows which backend it targets (for example a small label on the sign-in screen and a log line at launch).

## 7. Personas

Defined once in `/contract/seed/dataset.json`:

| id | Email (local only) | State | Purpose |
|---|---|---|---|
| `attendee` | `attendee@parkhill.test` | Active | Default signed-in user |
| `admin` | `admin@parkhill.test` | Active | Will hold the admin role when roles land |
| `disabled` | `disabled@parkhill.test` | Banned | Tests the disabled path |

- The dataset is the single source: `make seed` generates `seed.sql` (accounts with the shared local password documented in `/backend/README.md`) and `make fixtures` generates the mock fixtures from it.
- The mock persona picker lists active personas only.
- `make data-check` in CI fails if the seed or fixtures differ from what the dataset generates.
- Seed data is test data only. App configuration (screens, strings) goes in migrations so it reaches hosted projects.

## 8. Testing

| Layer | Covers |
|---|---|
| Backend (pgTAP) | `get_entry`, strings fallback, profiles created on account creation |
| Edge Function tests | Success, wrong password, disabled account, attempt limit, unknown locale falls back to `en`, no password in logs |
| Recorded refusals | `make fixtures` records every refusal in 5.5 into `contract/fixtures/sign_in.error*.json` without locking any persona; `make data-check` guards them |
| Integration | Signed-in persona calls `whoami()` and succeeds; signed-out call is refused; after the persona is disabled, its still-unexpired token is refused with `session_ended` |
| Client unit | Auth services, session restore, renewal refused path, unauthorized response leads to one renewal then sign-out, network errors never sign out, sign-out clears data, error display |
| UI, Dev against local Supabase, both platforms | Sign in, wrong password shows the backend message, sign out, still signed in after relaunch |
| UI, Mock, both platforms | Sign in through the mock menu as a chosen persona, one refusal and No connection, with no network |

Client CI runs Mock tests only. Dev UI tests run locally with `make test-dev`.

## 9. Decisions

| Decision | Chosen over |
|---|---|
| Email and password only | One-time codes, Apple, Google |
| No account creation in the app | Open sign-up, invites |
| Stay signed in, fail safe | Strict offline lockout, sign in every launch |
| Backend picks the entry screen and supplies its content | Fixed screen with remote text, backend-defined forms |
| Mock variant as its own `.mock` screen key, mock service only | Real backend serving mock screens |
| Named personas shared by mock and seed | Bare roles, role checkboxes |
| Hardcoded signed-in placeholder | Backend-driven placeholder |
| Backend does the sign-in (Edge Function) and returns the message | Client signs in and asks for the message; messages pre-sent in screen data |
| Committed local defaults plus gitignored override | All committed, all uncommitted |
