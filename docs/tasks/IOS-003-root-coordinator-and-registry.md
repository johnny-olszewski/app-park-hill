# IOS-003: Build the iOS root coordinator, screen registry and backend-driven entry

| Field | Value |
|---|---|
| Area | ios |
| Epic | EP-01 |
| Depends on | IOS-002 |
| Paired with | AND-003 |
| Status | Done |

## Intent

Make the app show whatever entry screen the backend names, through the coordinator and registry structure every future screen will use. After this task the app launches to a backend-driven screen; auth fills that screen in later.

## Scope

- `AppCoordinator` with launch states: loading, entry screen, error. A signed-in state is added by IOS-006.
- `ScreenRegistry`: screen key to screen factory, with one registration file per configuration's screen set (shared plus mock-only).
- Registered: `auth.sign_in` as a minimal screen that renders only its `title` (completed in IOS-006).
- Last good entry envelope cached on disk per locale.
- Launch error screen with retry, using bundled strings.

## Out of scope

- Sign-in behavior, session handling (IOS-005, IOS-006).
- Tabs and tab coordinators (IOS-008).
- Deep links.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | In the Dev configuration with local Supabase running, launch shows the `auth.sign_in` screen with the title from `get_entry` | The first screen is backend driven |
| AC2 | Changing the title string in the database is reflected after relaunch or return to foreground, with no rebuild | Proves remote control of the entry screen |
| AC3 | In the Mock configuration, launch shows the screen named by the mock entry mock response, with no backend running | The app runs independently |
| AC4 | Screens are created only through `ScreenRegistry`. Views do not instantiate other screens or mutate navigation state directly | Navigation stays in coordinators so targets can be backend driven |
| AC5 | Mock-only screens are registered from a file that exists only in mock sources | `.mock` screens never compile into other configs |
| AC6 | An entry envelope with an unregistered key is treated as unusable and logged | Backend can ship ahead of the client without a blank screen |
| AC7 | If `getEntry` fails and a cached envelope exists for the locale, it renders. If none exists, an error screen with a working retry shows. Covered by tests | Usable offline after first run; never a blank screen |
| AC8 | Coordinator, registry and cache have unit tests using a test double of `BackendService` | Behavior verified without a simulator session |

## Technical notes

- Guide 5.1 and 5.3.
- Coordinators are `@Observable` objects; views bind to them. Destinations are (screen key, params) values resolved by the registry.
- Cache: one JSON file per locale in Application Support, in a directory that sign-out can delete wholesale (IOS-005).

## Verification

```
cd ios
xcodebuild -scheme ParkHill-Mock -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Manual, Dev with local Supabase: launch and see the title; change the string in the database, foreground the app, see the change; `supabase stop`, relaunch, see the cached screen; delete the app, relaunch with Supabase stopped, see the error screen; start Supabase, tap retry.

## Definition of done

- [ ] All acceptance criteria pass
- [ ] No environment branching; no mock code in Release
- [ ] No work outside Scope

## Open questions

None.
