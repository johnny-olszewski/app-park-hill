# SUP-023: Build Browse all groups and the screen toolbar

| Field | Value |
|---|---|
| Area | contract, backend |
| Epic | EP-03 |
| Depends on | SUP-012 |
| Paired with | None |
| Status | Draft |

## Intent

Staff need to see every group, not just their own. This task adds the envelope's optional `toolbar` (the first toolbar item is "Browse all groups" on Community home, sent only to people with `groups.view_all`) and builds `community.browse`, presented as a full-screen cover.

## Scope

- Contract: `ToolbarItem` (`id`, `label`, `icon_key`, `action`) in `contract/types/`; `ScreenEnvelope` gains optional `toolbar` (list of `ToolbarItem`); `NavigateAction.presentation` gains `full_screen_cover`. Documented in `contract/README.md` (`specs/COMMUNITY.md` 3.1).
- `community.home` envelope: a "Browse all groups" toolbar item (`icon_key` `toolbar.browse`, `navigate` to `community.browse`, `full_screen_cover`) for `groups.view_all`, on every home state.
- `community.browse`: `{ title, search_placeholder, rows: [GroupRow] }`, every community group by name, the caller's own groups badged ("Leader" or "Member"), leaderless groups badged "No leader"; refused with `screen_unavailable` without `groups.view_all`.
- Add `community.browse` to `contract/names.json`; describe it in `contract/screens/`; strings in migrations; per-persona mock responses.

## Out of scope

- The "Create group" toolbar item (EP-03.E).
- The directory part of browse (EP-04).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | An envelope without `toolbar` is still valid, and every existing mock response passes the check unchanged | Backward compatible with earlier clients |
| AC2 | `staff` and `admin` get the browse item on `community.home`; `attendee`, `member_one`, `member_two` and `leader` do not | The UI follows what each person can do |
| AC3 | Browse lists every non-archived community group by name, with the caller's own groups badged and leaderless groups badged "No leader"; when a group is both, "No leader" wins | Staff see the whole picture and what needs attention |
| AC4 | Browse is refused with `screen_unavailable` for users without `groups.view_all` | Stale buttons cannot reveal all groups |
| AC5 | `make data-check` passes with the new descriptions and per-persona mock responses | Mocks mirror the real backend per persona |
| AC6 | pgTAP tests cover AC2 to AC4 | Enforced, not documented |

## Technical notes

- One assembly function per screen key, reused by `get_screen`; toolbar items are built with `has_permission`, never a role name.
- Toolbar items are part of the envelope, not of a screen's `data` (guide 4.1).

## Verification

```
cd backend
supabase db reset && supabase test db && make data-check
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include mock response and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None.
