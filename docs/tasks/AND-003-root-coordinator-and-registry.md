# AND-003: Build the Android root coordinator, screen registry and backend-driven entry

| Field | Value |
|---|---|
| Area | android |
| Epic | EP-01 |
| Depends on | AND-002 |
| Paired with | IOS-003 |
| Status | Done |

## Intent

Android twin of IOS-003. The app shows whatever entry screen the backend names, through the structure every future screen will use.

## Scope

- `AppCoordinator` with launch states: loading, entry screen, error. Signed-in state added by AND-006.
- `ScreenRegistry`: screen key to composable factory, shared registrations in `src/main`, mock-only registrations in `src/mock`.
- Registered: `auth.sign_in` as a minimal screen rendering only its `title` (completed in AND-006).
- Last good entry envelope cached on disk per locale.
- Launch error screen with retry, using bundled strings.

## Out of scope

- Sign-in behavior, session handling (AND-005, AND-006).
- Tabs (AND-008).
- Deep links.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | In `devDebug` with local Supabase running, launch shows the `auth.sign_in` screen with the title from `get_entry` | The first screen is backend driven |
| AC2 | Changing the title string in the database is reflected after relaunch or return to foreground, with no rebuild | Proves remote control of the entry screen |
| AC3 | In `mockDebug`, launch shows the screen named by the mock entry fixture, with no backend running | The app runs independently |
| AC4 | Screens are created only through `ScreenRegistry`. Composables do not call `NavController` or create other screens directly | Navigation stays in coordinators |
| AC5 | Mock-only screens are registered from `src/mock` only | `.mock` screens never compile into other variants |
| AC6 | An entry envelope with an unregistered key is treated as unusable and logged | Backend can ship ahead of the client without a blank screen |
| AC7 | If `getEntry` fails and a cached envelope exists for the locale, it renders. If none exists, an error screen with a working retry shows. Covered by tests | Usable offline after first run; never a blank screen |
| AC8 | Coordinator, registry and cache have unit tests using a test double of `BackendService` | Behavior verified without an emulator session |

## Technical notes

- Guide 5.1 and 5.3. Names and behavior match IOS-003.
- Coordinators expose `StateFlow`; composables collect it. Routes are (screen key, params) values resolved by the registry.
- Cache: one JSON file per locale in a files-dir subdirectory that sign-out can delete wholesale (AND-005).

## Verification

```
cd android
./gradlew testMockDebugUnitTest
```

Manual, `devDebug` with local Supabase: same steps as IOS-003.

## Definition of done

- [ ] All acceptance criteria pass
- [ ] No environment branching; no mock code in release
- [ ] No work outside Scope

## Open questions

None.
