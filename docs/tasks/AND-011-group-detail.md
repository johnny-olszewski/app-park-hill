# AND-011: Build the Android group detail view and screen

| Field | Value |
|---|---|
| Area | android |
| Epic | EP-03 |
| Depends on | AND-009, SUP-012 |
| Paired with | IOS-011 |
| Status | Draft |

## Intent

A group's detail is what members see first: its details, who leads it and who is in it. This task builds that view once, read-only, and registers `community.group` with it, so Community home's single-group state (IOS-010 and AND-010) can reuse it.

## Scope

- Group detail view from `GroupDetail`: a details section (`description`, `meeting`, `location`, `leaders_line`) and a members section (`members_title`, then one row per `MemberRow`: `title`, `note` such as "You", and a leader icon when `is_leader`).
- `community.group` registered with the generated `GroupDetail` type; the screen's title is the group's `title`.

## Out of scope

- Swipe to remove and Leave (EP-03.C); edit mode (EP-03.D); delete (EP-03.E).
- Community home (from AND-010).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Every field of `GroupDetail` is shown exactly as sent; an empty `description` or `location` hides its line | One view, one contract |
| AC2 | The leader icon appears only on rows with `is_leader`, with an accessibility label; the `note` shows on its row | Leaders and the person's own row are recognisable |
| AC3 | A pushed `community.group` shows the view with the group's title in the navigation bar | Group detail reachable from any group row |
| AC4 | Mock UI tests open a group's detail as `member_two` and as `admin`, and check the details, leaders line and member rows | Verified per persona in CI |
| AC5 | Decoding tests decode every recorded `community.group` fixture | The view's data matches the backend |

## Technical notes

- The view is a client component shared by the screen and Community home; the backend knows only screens.
- Material top app bar; a `LazyColumn` with section headers.
- Behavior must match IOS-011.

## Verification

```
cd android
./gradlew testMockDebugUnitTest testDevDebugUnitTest connectedMockDebugAndroidTest
make test-dev
./gradlew assembleDevRelease && scripts/check_release_apk.sh app/build/outputs/apk/dev/release/app-dev-release-unsigned.apk
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include fixture and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

None.
