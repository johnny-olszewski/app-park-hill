# Contract

API contract docs, JSON mock responses and personas. The single source of truth both clients build and test against. Governed by `docs/ENGINEERING_GUIDE.md` 4.1.

## Screen envelope

The one shape for any screen's content, wherever it comes from:

```json
{ "key": "auth.sign_in", "data": { }, "toolbar": [ ] }
```

- `key`: the screen key. Clients map it to a native screen through their screen registry.
- `data`: everything that screen needs, with all text already resolved for the requested locale. One screen key maps to exactly one data model.
- `toolbar` (optional): the buttons for the screen's bar, in order, each a `ToolbarItem` (`id`, `label`, `icon_key`, `action`). The backend sends only the items the caller may use, and leaves the field out when there are none. A screen gets a toolbar by naming a `toolbar_function` in `public.screens`.

Text resolves per string: a string missing in the requested locale uses its `en` value.

## Names

`names.json` is the only hand-written list of the backend function names (RPC and Edge Functions) clients call and the screen keys the backend returns. `make names` in `/backend` generates the client constants in `generated/` (`ContractNames.swift`, `ContractNames.kt`); never edit them by hand. `make data-check` fails when the list and the backend disagree, or when `generated/` differs from what `make names` produces. Mock-only keys (`.mock`) are not listed; they stay in client mock sources.

## Contract descriptions

Every response a client decodes is described once in `/contract`, for both clients (guide 4.1 rule 8):

- `screens/<key>.schema.json` describes one backend screen's `data`.
- `types/<TypeName>.schema.json` describes a shared type: a whole response (`ScreenEnvelope`, `TabsResponse`, `Profile`, `SignInSuccess`, `SignInFailure`) or a part used inside one (`TabItem`, `SignInSession`, `Action`, `GroupRow`). The file name is the type's `title`.
- `types/examples/<TypeName>.json` is an example value of a shared type, for types no recorded response contains yet, so clients can build views before screens exist.
- `responses.json` maps each recorded response in `mock_responses/`, by file name without its persona folder, `@` params or `.json` (`get_entry`, `get_screen.<key>`, `get_tabs`, `whoami`, `sign_in.ok`, `sign_in.error`, `sign_in.error.<code>`, `save_group_changes.ok`, `save_group_changes.failed`), to the type that describes it.

`make models` in `/backend` generates a Swift and a Kotlin model from each screen and type into `generated/`, named by its `title` (`SignInScreenData.swift`, `SignInScreenData.kt`, package `app.parkhill.contract`); never edit them by hand. Swift models are `Codable, Equatable, Sendable`; Kotlin models are `@Serializable`.

`make data-check` fails when:

- a recorded response does not match its type, or a recorded screen's `data` (including each tab's screen in `get_tabs`) does not match its screen's description;
- a recorded response has no mapping in `responses.json`, a mapping names no recorded response or no type, or a type is used by no description and no mapping;
- a screen key in `names.json` has no description, or a description has no key;
- a `$ref` names a type with no file;
- an example in `types/examples/` names no type or does not match it (a type with an example counts as used);
- `generated/` differs from what `make models` produces.

Descriptions use this subset of JSON Schema (2020-12). Anything else is refused, so a description never means something the generator or the check ignores:

| Where | Keywords |
|---|---|
| Screen or type | `$schema`, `title` (the model's type name), `description`, `"type": "object"`, `properties`, `required`, `"additionalProperties": false` (all but `description` are required, even when empty) |
| Field | `description`, and one of: `type` (`string`, `integer`, `number`, `boolean`, `object` alone, or `array` with `items`); `$ref` to a type; or neither, meaning any JSON. A `string` may add `enum`: distinct snake_case values, and no other value is valid |
| Array items | As a field, without `description` |
| Alias screen (screens only) | `$schema`, `title`, `description`, and `$ref` to a type: the screen's data is that type, for a screen another screen embeds whole (`community.group` is `GroupDetail`) |
| Union type (types only) | `$schema`, `title`, `description`, and `oneOf`: a list of `{"$ref": "<TypeName>.schema.json"}`. Each member is an object type whose required `type` field is a `string` with a one-value `enum`, each value used once. A value of the union is the member its `type` names; any other `type` fails the check |

A `$ref` names a file in `types/`: `"../types/GroupRow.schema.json"` from a screen, `"GroupRow.schema.json"` from another type. Objects inside a description are always shared types; the subset has no inline object types.

| Description | Swift | Kotlin |
|---|---|---|
| `string`, `integer`, `number`, `boolean` | `String`, `Int`, `Double`, `Bool` | `String`, `Int`, `Double`, `Boolean` |
| `array` | `[T]` | `List<T>` |
| `$ref` | The type's name | The type's name |
| `"type": "object"` alone (any JSON object) | `JSONValue` (the app's) | `JsonObject` |
| No `type` (any JSON) | `JSONValue` (the app's) | `JsonElement` |
| Field not in `required` | `T?`, defaulting to `nil` in the generated initializer | `T? = null` |
| `enum` | `enum <Type><Field>: String` (`NavigateActionPresentation`), a case per value | `enum class <Type><Field>`, an entry per value with `@SerialName` |
| Alias screen | `typealias <Title> = <Type>` | `typealias <Title> = <Type>` |
| Union type | `enum` with a case per member (named by its `type` value) and `unknown(type:)`, decoding on `type` | `sealed interface` its members implement, with `Unknown(type)`, decoded on `type` by `<Union>Serializer` |

Field names are snake_case in the description and lower camel case in the models, mapped back to the JSON name. Recorded responses must match exactly, with no undescribed fields, so descriptions stay complete; the generated decoders still ignore unknown fields (contract rule 2): Swift's `Decodable` does, and Android decodes with `ContractJson`.

An unknown `type` in a union decodes as unknown instead of failing, so the backend can add an action type before clients know it (contract rule 3): clients make such an item not tappable. An `enum` has no unknown value: a new value is added to its description, both apps and the backend together.

Adding a screen: write its description, add its key to `names.json`, run `make models`, and commit both with the migration and the mock responses. Adding a response: describe its type in `types/`, map its mock response in `responses.json`, and run `make models`. When a description first needs a keyword the subset lacks (for example `enum`), the same change adds it to `backend/scripts/screens.py`, the generator and the check.

### How the approach was chosen

SUP-020 compared ways to describe each screen's data once in `/contract` and generate both client models from it. Criteria (SUP-020 Technical notes):

1. Generated code is plain, readable, committed, and adds no runtime dependency to either app.
2. Swift output is `Decodable` and `Equatable`; Kotlin output uses kotlinx.serialization, as the Android app does.
3. Expresses shared types defined once and reused across screens (`Action`, `ToolbarItem`, `GroupRow`), optional fields, lists and enums.
4. Generated decoders ignore unknown fields (contract rule 2).
5. Runs from `backend/Makefile` with Python, or a single tool whose version is pinned.
6. The same description validates live responses in `make data-check`.
7. A new screen needs one description file and one command, with no hand edits elsewhere.

| Candidate | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|
| A. JSON Schema, generated by quicktype | Partly: output carries quicktype's helpers and converters | Yes, with its kotlinx option | Yes | Yes | Partly: Node and an npm package, fetched on every machine and CI run | No: needs a separate validator | Yes |
| B. JSON Schema, validated by the `jsonschema` package, generated by our script | Yes | Yes | Yes | Yes | Partly: the first pip dependency; scripts are standard library only today | Yes, the full standard | Yes |
| C. Our own small format, generated and validated by our script | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| D. A documented subset of JSON Schema, generated and validated by our script | Yes | Yes | Yes | Yes | Yes | Yes | Yes |

**Chosen: D.** It meets every criterion, like C, but the files are standard JSON Schema: editors validate and complete them, other tools and teams can read them, and the format needs no explaining when this architecture is reused elsewhere. The script supports only the keywords screens use and rejects any other, so a description never means something the generator or the check silently ignores; a keyword is added to the script when a screen first needs it. Because the files are valid JSON Schema, moving to B later (full validator, same files) stays open. A and B were set aside for adding Node or pip to every machine and CI run for what a short standard-library Python script does. C was set aside only because a format of our own is one more thing to learn and document, with no tooling.

Also considered and rejected before SUP-020: a generic list of typed elements looked up by id (`[{ "type": "text", "id": "title", "value": "Sign in" }]`). Clients would still write per-screen lookup code for every field, lose compile-time typing, and express nested data such as a list of groups poorly.

## Actions and shared types

Anything tappable carries an `Action` (`types/Action.schema.json`, specs/COMMUNITY.md 3.2), a union told apart by `type`:

| `type` | Type | Fields |
|---|---|---|
| `navigate` | `NavigateAction` | `screen_key`, `params` (any object, passed to `get_screen` as `p_params`), `presentation`, optional `role` |
| `call` | `CallAction` | `function` (a name from `names.json`), `params` (the function's named arguments; the client adds `p_locale`), optional `confirm` (`CallConfirmation`: `title`, `message`, `confirm_label`, `cancel_label`), `on_success`, optional `role` |

| Field | Values |
|---|---|
| `presentation` | `push`: the current tab's stack. `sheet`: a sheet over the screen, fetched with a loading state, opened from a tab or a cover. `full_screen_cover`: over everything, with its own stack and a close button, fetched fresh each time. |
| `on_success` | `refresh`: refetch the screen. `dismiss`: close a pushed screen and refresh the one below, or refresh a tab root in place (guide 5.3 rule 9). `none`: nothing |
| `role` | `destructive`: a meaning each platform styles its own way |

A `call` with `confirm` shows the backend's wording first; cancelling calls nothing. A successful call returns a body: `{}` for most, which clients ignore (EP-03.E adds `then`), and a `SaveResult` for `save_group_changes`, which edit mode decodes. A refused call is an error (Errors below).

Shared types for Community screens, all text backend formatted and localized:

| Type | Fields |
|---|---|
| `GroupRow` | `group_id`, `title`, `subtitle` (for example "Tuesdays · 7:00 PM · Lee home"), optional `badge` (for example "Leader"), optional `badge_tone` (`attention`, for example on "No leader"), `action` |
| `ToolbarItem` | `id`, `label` (also the accessibility label of an icon button), `icon_key` (a bundled icon), `action` |
| `GroupDetail` | `group_id`, `title`, `description` and `location` (empty when unset), `meeting` (one line, for example "Tuesdays · 7:00 PM"), `leaders_line` ("Leaders: Jordan Lee", or "Leaders: none yet"), `members_title`, `members`, optional `leave` (`ActionButton`, for the group's members); for edit mode, optional `edit` (`GroupEditLabels`), `add_member` (`ActionButton` opening `people.picker` as a sheet), `edit_fields` (`EditField`s) and `save` (`CallAction` to `save_group_changes`) |
| `MemberRow` | `user_id`, `title` (display name), optional `note` (for example "You"), `is_leader`, optional `remove` (`ActionButton`, on rows the caller may remove), optional `toggle_leader` (true when the caller may change this member's leadership) |
| `ActionButton` | `label`, `action`; sent only to people who may use it |
| `GroupEditLabels` | `edit_label`, `done_label`, `cancel_label` |
| `EditField` | `id` (the key in the save batch and in `field_errors`), `label`, `kind` (`text`, `multiline`, `day`, `time`), `value` (a string), optional `options` (`EditFieldOption`s: `value`, `label`, for a `day`) |
| `SaveResult` | `ok`, optional `field_errors` (field id to message), optional `row_errors` (user id to message) |
| `GroupList` | `title`, `rows` (`GroupRow`s) |
| `PersonRow` | `user_id`, `title` (display name), optional `subtitle`, optional `note` (why they cannot be chosen, for example "Already a member"), `selectable` |
| `EmptyState` | `title`, `message`; shown with no buttons |

## Screen keys

Lowercase and dot separated. A key ending in `.mock` is registered only in the Mock configuration and is never returned by the real backend.

| Key | Returned by | Data | Mock response |
|---|---|---|---|
| `auth.sign_in` | `get_entry`, `get_screen` | `screens/auth.sign_in.schema.json` (`specs/AUTH.md` 5.3) | `mock responses/get_screen.auth.sign_in.json` |
| `home.root` | `get_tabs`, `get_screen`; signed in only | `screens/home.root.schema.json`: `{}` until Home has content | `mock responses/<persona>/get_screen.home.root.json` |
| `community.home` | `get_tabs`, `get_screen`; signed in only | `screens/community.home.schema.json`: one of `group` (`GroupDetail`), `my_groups` (`GroupList`) or `empty` (`EmptyState`) | `mock responses/<persona>/get_screen.community.home.json` |
| `community.browse` | `get_screen`; holders of `groups.view_all`, else `screen_unavailable` | `screens/community.browse.schema.json`: `title`, `search_placeholder`, `rows` (every group by name, `GroupRow`s badged for the caller) | `mock responses/<persona>/get_screen.community.browse.json` |
| `community.group` | `get_screen` with `{"group_id"}`; members, leaders and holders of `groups.view_all`, else `screen_unavailable` | `screens/community.group.schema.json`: `GroupDetail` | `mock responses/<persona>/get_screen.community.group@group_id=<id>.json`, for each group a persona's responses open |
| `people.picker` | `get_screen` with `{"group_id"}`; holders of `groups.add_member` on that group, else `screen_unavailable` | `screens/people.picker.schema.json`: `title`, `search_placeholder`, `add_label`, `cancel_label`, `rows` (every active person by name, `PersonRow`s; current members not `selectable`, with a `note`) | `mock responses/<persona>/get_screen.people.picker@group_id=<id>.json`, for each group a persona's `add_member` opens |

A screen registered with `signed_in` in `public.screens` is refused to signed-out callers with `session_ended`, like every signed-in function.

## Entry points

Postgres functions called through PostgREST: `POST /rest/v1/rpc/<function>` with a JSON body of named arguments.

| Function | Caller | Returns |
|---|---|---|
| `get_entry(p_locale)` | Signed out (`anon`) | The signed-out entry screen envelope. Today always `auth.sign_in` |
| `get_screen(p_key, p_locale, p_params)` | Depends on the screen | One screen envelope. Used for refresh and for screens reached by navigation |
| `get_tabs(p_locale)` | Signed in only | The enabled tabs in order, at most five: `{ "tabs": [ { "id", "title", "icon_key", "screen": <envelope> } ] }`. `title` is resolved for the locale; `icon_key` names a bundled client asset |
| `leave_group(p_group_id, p_locale)` | Signed in, in the group | `{}`. Ends the caller's membership and leadership; the last leader may leave. Else `action_refused` |
| `remove_member(p_group_id, p_user_id, p_locale)` | Signed in, with `groups.remove_member` for the group; leaders cannot remove leaders | `{}`. Ends that member's membership and leadership. Else `action_refused` |
| `save_group_changes(p_group_id, p_batch, p_locale)` | Signed in, with the permission for each change | `SaveResult`: `{ "ok": true }` with every change applied, or `ok: false` with `field_errors` (field id to message) and `row_errors` (user id to message) and nothing applied. `p_batch` is `{ fields: { <id>: value }, add, remove, make_leader, remove_leader: [user_id] }`; field ids `name`, `description`, `day` (`"1"` to `"7"`), `time` (`"19:00"`), `location`; name, day and time are required |
| `whoami()` | Signed in only | The caller's profile: `{ "id": "<uuid>", "display_name": "Attendee" }` |

### `sign_in` Edge Function

`POST /functions/v1/sign_in` with the anon key and the standard headers. Spec: `specs/AUTH.md` 5.5.

```json
{ "email": "attendee@parkhill.test", "password": "...", "locale": "en" }
```

| HTTP | Body |
|---|---|
| 200 | `{ "status": "ok", "session": { "access_token", "refresh_token", "expires_at", "user_id" } }` |
| 400, 401, 403, 429 | `{ "status": "error", "code": "<code>", "message": "<localized text>" }` |

| `code` | HTTP | When |
|---|---|---|
| `invalid_credentials` | 401 | Wrong email or password. Identical for unknown emails |
| `account_disabled` | 403 | The account is banned |
| `too_many_attempts` | 429 | 5 failures per email or 20 per client address within 15 minutes |
| `invalid_request` | 400 | Missing or malformed fields |
| `unknown` | 400 | Anything else; generic message |

Clients show `message` as given. Messages are the `auth.error.<code>` strings for the request locale, falling back to `en`.

Arguments: `p_locale` is a locale code such as `en`; `p_params` is a JSON object, `{}` when the screen takes no parameters.

## Errors

Errors use PostgREST's error body. The `message` field is a stable code clients branch on.

| `message` | HTTP | `code` | When | `details` |
|---|---|---|---|---|
| `unknown_screen` | 400 | `P0001` | `get_screen` called with a key the backend does not register | The requested key |
| `session_ended` | 400 | `P0001` | A signed-in function was called with no valid user, or the account is banned or deleted | None |
| `screen_unavailable` | 400 | `P0001` | `get_screen` for a screen the caller may not see, such as a group they are not in, for example after losing access | The backend's localized message for the caller's locale, shown as given (specs/COMMUNITY.md 5.5) |
| `action_refused` | 400 | `P0001` | A `call` the caller may not make (any more), such as removing a member who already left | The backend's localized message for the caller's locale, shown as given; the client then refreshes the screen |

Clients treat `session_ended` like an HTTP 401 (expired or invalid token): one silent session renewal and retry, then sign out (`specs/AUTH.md` 4.3).

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
6. `/contract/mock_responses` holds a JSON example of every response. Client mocks and client decoding tests read these files. Backend tests assert the live functions match their shape.

## Mock responses

Generated from the real backend by `make mock-responses` in `/backend`, from the personas in `seed/dataset.json`. Never edit them by hand; `make data-check` fails on any drift.

| Path | Response |
|---|---|
| `mock responses/get_entry.json` | `get_entry('en')`, signed out |
| `mock responses/get_screen.<key>.json` | `get_screen(<key>, 'en', '{}')`, signed out |
| `mock responses/<persona>/get_screen.<key>.json` | The same call signed in as an active persona |
| `mock responses/<persona>/get_screen.<key>@<param>=<value>[&...].json` | `get_screen` with those params, params sorted by name, for every `navigate` action with params in the persona's recorded responses (and in the screens those open) |
| `mock responses/<persona>/whoami.json` | `whoami()` signed in as an active persona |
| `mock responses/<persona>/get_tabs.json` | `get_tabs('en')` signed in as an active persona |
| `mock responses/sign_in.ok.json` | `sign_in` success for `attendee`; tokens and `expires_at` are placeholders |
| `mock responses/sign_in.error.json` | `sign_in` with a wrong password |

A screen a caller may not see has no file for that caller. Client mocks look a call up by its name with params first, then by its name alone, and prefer the current persona's file to the signed-out one.

## Personas

`seed/dataset.json` defines the personas once (`specs/AUTH.md` 7). It generates the local accounts in `backend/supabase/seed.sql` and the persona mock response folders above. A contract change updates the migration or dataset and the screen's description, regenerates the mock responses and models, and updates both clients in one PR.
