---
type: task
id: IOS-024
title: "Decode every backend response with the generated types in the iOS app"
area: ios
epic: EP-05
depends_on: [SUP-022, IOS-023]
paired_with: [AND-025]
status: Done
---

# IOS-024: Decode every backend response with the generated types in the iOS app

## Intent

After SUP-022, the screen envelope, `get_tabs`, `whoami` and the `sign_in` responses have generated Swift types. This task makes the app use them and deletes its hand-written copies, so no response shape is written by hand in the app.

## Scope

- Use the generated `ScreenEnvelope`, `TabsResponse`, `TabItem`, `Profile`, `SignInSuccess`, `SignInSession` and `SignInFailure` from `contract/generated/` (already compiled since IOS-023).
- Delete the hand-written ones in `ios/ParkHill/Services/Backend/ScreenEnvelope.swift`, `Tabs.swift`, `Profile.swift` and `ios/ParkHill/Services/Auth/SignInResponse.swift`; `SignInRequest` stays (request bodies are not described).
- Code that used `SignInSuccess.Session` uses `SignInSession`.
- Remove SUP-022's `TEMPORARY(EP-05)` excludes from `ios/project.yml` in the same commit that deletes the hand-written types.

## Out of scope

- Request bodies and PostgREST error bodies.
- Any behavior or appearance change.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | A search of `ios/` finds no definition of the seven types in Scope; each is defined only in `contract/generated/` | One definition per response shape |
| AC2 | Cached envelopes and tabs written by the previous build still load after updating (same encoding), or are discarded and refetched without an error screen | Updating the app never shows an error for an old cache |
| AC3 | Decoding tests decode every file in `contract/mock_responses` with its type from `contract/responses.json` | The app decodes exactly what the backend records |
| AC4 | In Mock and Dev, sign-in (success and each refusal), tabs, return to foreground and sign-out work as before | No behavior change |
| AC5 | A search outside `docs/` for `TEMPORARY(EP-05)` finds nothing | SUP-022's temporary excludes are gone |

## Technical notes

- The generated types are `Codable, Equatable, Sendable`, as the hand-written ones are.
- Behavior must match AND-025.

## Verification

```
cd ios
make project
xcodebuild -scheme ParkHill-Mock -destination "id=$(scripts/simulator.sh)" test
make test-dev
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
