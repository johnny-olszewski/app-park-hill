# AND-028: Build Android group create and delete

| Field | Value |
|---|---|
| Area | android |
| Epic | EP-03 |
| Depends on | AND-013, SUP-025 |
| Paired with | IOS-027 |
| Status | Draft |

## Intent

Staff start a group from Browse and retire one from its edit mode. This task builds the create form sheet and the delete button, reusing the edit fields, call handling and lost-access rule from earlier slices.

## Scope

- `community.group.create` as a sheet from the browse toolbar: the `fields` as inline fields by `kind` (shared with edit mode), Save (`save_label`) sending the `save` call with the field values, Cancel (`cancel_label`) closing it.
- Field errors from a failed save under their fields, the sheet staying open; on success the sheet closes, then the result's `then` action is performed (here, pushing the new group's detail in the browse cover). `then` is handled for every `call`, not only create.
- Delete group: a destructive footer button in edit mode when `delete` is sent; its `call` confirms, archives and applies `dismiss` (the lost-access rule).
- Mock UI tests for `staff`; Dev UI tests in `make test-dev`: `staff` creates a group and deletes it.

## Out of scope

- Restoring archived groups.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Only `staff` and `admin` see Create on browse and Delete in edit mode | The UI follows what each person can do |
| AC2 | Create shows the backend field errors in place and keeps the sheet open; success closes it and shows the new group's detail | Staff can start a group in one flow |
| AC3 | Delete confirms with the backend text, archives, closes the group and refreshes browse without it | Safe delete for staff |
| AC4 | Mock UI tests cover AC1 to AC3 for `staff`; Dev UI tests create and delete a group against local Supabase | Verified per persona and end to end |

## Technical notes

- The inline field views are the ones edit mode uses (AND-013).
- Behavior must match IOS-027.

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
