# Contract

API contract docs, JSON fixtures and personas. The single source of truth both clients build and test against. Governed by `docs/ENGINEERING_GUIDE.md` 4.1.

## Screen envelope

The one shape for any screen's content, wherever it comes from:

```json
{ "key": "auth.sign_in", "data": { } }
```

- `key`: the screen key. Clients map it to a native screen through their screen registry.
- `data`: everything that screen needs, with all text already resolved for the requested locale. One screen key maps to exactly one data model.

Text resolves per string: a string missing in the requested locale uses its `en` value.

## Screen keys

Lowercase and dot separated. A key ending in `.mock` is registered only in the Mock configuration and is never returned by the real backend.

| Key | Returned by | Data | Fixture |
|---|---|---|---|
| `auth.sign_in` | `get_entry`, `get_screen` | `specs/AUTH.md` 5.3 | `fixtures/get_screen.auth.sign_in.json` |

## Entry points

Postgres functions called through PostgREST: `POST /rest/v1/rpc/<function>` with a JSON body of named arguments.

| Function | Caller | Returns |
|---|---|---|
| `get_entry(p_locale)` | Signed out (`anon`) | The signed-out entry screen envelope. Today always `auth.sign_in` |
| `get_screen(p_key, p_locale, p_params)` | Depends on the screen | One screen envelope. Used for refresh and for screens reached by navigation |
| `get_tabs(p_locale)` | Signed in only | Tabs in order, each with its root screen envelope embedded (SUP-008) |

Arguments: `p_locale` is a locale code such as `en`; `p_params` is a JSON object, `{}` when the screen takes no parameters.

## Errors

Errors use PostgREST's error body. The `message` field is a stable code clients branch on.

| `message` | HTTP | `code` | When | `details` |
|---|---|---|---|---|
| `unknown_screen` | 400 | `P0001` | `get_screen` called with a key the backend does not register | The requested key |

Example:

```json
{ "code": "P0001", "message": "unknown_screen", "details": "does.not_exist", "hint": "The screen key is not registered on this backend." }
```

A network failure produces no body; clients tell the two apart by whether a response arrived.

## Contract rules

1. Changes are additive. Fields are never removed or repurposed. A breaking change is a new function or a new screen key.
2. Clients ignore unknown fields.
3. Clients drop anything with an unknown screen key and log it. The backend may ship ahead of clients.
4. One screen key maps to exactly one data model. Every variant of a screen is expressible in that one model, except mock variants, which have their own key.
5. Unknown locale falls back to `en`.
6. `/contract/fixtures` holds a JSON example of every response. Client mocks and client decoding tests read these files. Backend tests assert the live functions match their shape.

## Fixtures

| File | Response |
|---|---|
| `fixtures/get_entry.json` | `get_entry('en')` |
| `fixtures/get_screen.auth.sign_in.json` | `get_screen('auth.sign_in', 'en', '{}')` |

Fixtures are copies of live responses from local Supabase. A contract change updates the migration, the fixture and both client models in one PR.
