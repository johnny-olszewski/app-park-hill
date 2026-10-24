---
type: task
id: IOS-023
title: "Decode screens with the generated models in the iOS app"
area: ios
epic: EP-05
depends_on: [SUP-020]
paired_with: [AND-024]
status: Draft
---

# IOS-023: Decode screens with the generated models in the iOS app

## Intent

SUP-020 generates each screen's Swift model from its description in `contract/screens/`, but the app still decodes with its own hand-written copies. This task makes the app compile and use the generated models and deletes the hand-written ones, so a screen's fields are written once and every later screen (from EP-03) needs no model code in the app.

## Scope

- Compile the generated screen models in `contract/generated/` (every `.swift` file except `ContractNames.swift`, which is already compiled) in every configuration, through `ios/project.yml`, without copying them.
- Delete the hand-written `SignInScreenData`, `HomeRootData` and `CommunityHomeData` from `ios/ParkHill/Screens/`; the screen registry and screens use the generated types.
- Keep `JSONValue` (`ios/ParkHill/Services/Backend/JSONValue.swift`) as the app type the generated models use for any JSON.
- Decoding tests read `contract/mock_responses` and decode with the generated types.

## Out of scope

- Responses that are not screen data (`whoami`, `sign_in`, `get_tabs`, the envelope): EP-05.D (IOS-024).
- Any change to screen behavior or appearance.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | `SignInScreenData`, `HomeRootData` and `CommunityHomeData` are each defined only in `contract/generated/`; a search of `ios/` finds no definition of them | One definition per screen model |
| AC2 | Every configuration (Mock, Dev, Dev-Release) builds with the generated models, and a new `.swift` file that `make models` adds to `contract/generated/` is compiled after `make project` with no edit to `project.yml` | A new screen's model needs no client project change |
| AC3 | Removing `title` from `contract/screens/auth.sign_in.schema.json` and running `make models` breaks the iOS build at the screen that reads it (then reverted) | The app follows the description, so drift fails the build |
| AC4 | Decoding tests decode every recorded screen in `contract/mock_responses` with its generated type | Generated models match the backend's recorded output |
| AC5 | In Mock and Dev, sign-in (success and each refusal), tabs and sign-out work as before | No behavior change |

## Technical notes

- `ios/project.yml` lists `../contract/generated/ContractNames.swift` today. Include the folder's Swift files and exclude `*.kt` (implementer's choice of XcodeGen `sources` form), keeping the existing comment style.
- The generated types are internal and live in the app module, like `ContractNames.swift`.
- `HomeRootData` and `CommunityHomeData` gain `Equatable`; nothing depends on its absence.
- Behavior must match AND-024.

## Verification

```
cd ios
make project
xcodebuild -scheme ParkHill-Mock -destination "id=$(scripts/simulator.sh)" test
make test-dev
grep -rn "struct SignInScreenData\|struct HomeRootData\|struct CommunityHomeData" ParkHill ParkHillTests   # no output
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
