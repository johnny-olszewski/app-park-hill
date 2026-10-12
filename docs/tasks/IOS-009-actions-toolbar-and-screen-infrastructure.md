# IOS-009: Build iOS toolbar, action handling and shared screen behavior

| Field | Value |
|---|---|
| Area | ios |
| Epic | EP-03 |
| Depends on | IOS-008, SUP-011 |
| Paired with | AND-009 |
| Status | Draft |

## Intent

Give every screen the same toolbar, action handling, caching, refresh and lost-access behavior, so Community screens (and every later screen) only render their own content.

## Scope

- Toolbar rendering from the envelope, with overflow menu in backend order.
- Action handler: `navigate` with `push`, `sheet` (`.sheet`) and `full_screen_cover` (`fullScreenCover`); `call` with backend confirmation, `role: destructive`, and `on_success` `refresh`, `dismiss`, `none`.
- Client-drawn close button on full-screen covers (platform icon and accessibility label).
- Screen cache per screen key and params; pull to refresh; wiped at sign-out.
- Lost-access rule: `dismiss` closes and refreshes the screen below (refresh in place on a root); a `screen_unavailable` refresh closes the screen, refreshes below and shows the backend message in a system alert with one button (guide 5.5; no custom notice view).

## Out of scope

- Community screens (from IOS-010).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Toolbar items from any envelope render with the backend label and icon; extras go to an overflow menu in order | One toolbar pattern for every screen |
| AC2 | Each presentation value opens the target screen the platform-native way | Navigation targets come from the backend |
| AC3 | A `call` with `confirm` shows the backend text first; on success applies `on_success`; errors show the backend message | Generic one-tap operations |
| AC4 | `dismiss` on a pushed screen closes it and refreshes the screen below; on a root it refreshes in place | One rule for leaving or deleting |
| AC5 | A `screen_unavailable` refresh closes the screen, refreshes below and shows the message | People never stay on something they lost access to |
| AC6 | Fetch failure shows the cached screen for that key and params, else the error screen with retry; sign-out wipes the cache | Usable offline, private after sign-out |
| AC7 | Unit tests cover AC1 to AC6 using fixtures | Verified without a backend |

## Technical notes

- Decode with Swift enums and `Codable` models; unknown fields ignored.
- Behavior must match AND-009.

## Verification

```
cd ios
xcodebuild -scheme ParkHill-Mock -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI
- [ ] No environment branching; no mock code in release builds
- [ ] Contract changes include fixtures
- [ ] No work outside Scope

## Open questions

None.
