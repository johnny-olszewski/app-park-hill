---
type: task
id: IOS-028
title: "Build group detail with Apollo iOS on a spike branch"
area: ios
epic: EP-07
depends_on: [SUP-026, IOS-026]
paired_with: []
status: Draft
---

# IOS-028: Build group detail with Apollo iOS on a spike branch

## Intent

Measure what an iOS screen costs when the backend sends only its key and the screen queries its own data through GraphQL, against `community.group` as IOS-026 built it. This is a spike: its code is evidence for the findings report and never merges (guide 7.1 rule 13).

## Scope

- On `spike/EP-07.A-graphql`: add Apollo iOS with its code generation from the local `pg_graphql` schema, run by a `make` target.
- A GraphQL-backed `community.group` screen, registered under the same screen key, so navigation from Community home still comes from the backend's action. Its view model builds the meeting and leaders lines from domain data with bundled strings.
- Leave and swipe to remove through the GraphQL mutations, shown only when `viewer_can_leave` and `viewer_can_remove` say so, with the same confirmation, refresh and lost-access behavior as IOS-026 (guide 5.3 rule 9).
- Unit tests for the view model.
- On the slice branch: the iOS half of `docs/spikes/EP-07.A-graphql.md`, and its comparison and recommendation.

## Out of scope

- The Mock build: the report says how Mock would serve GraphQL responses instead.
- Android (EP-07 Out of scope).
- Other screens, and removing the screen-function path.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | In Local, opening a group from Community home shows its detail from GraphQL, matching what the current screen shows for the same persona | Like for like, so the comparison is fair |
| AC2 | Leave and remove appear only where the capability fields allow, and behave as in IOS-026 AC for confirm, refresh and lost access | Permissions stay with the backend (guide 2) |
| AC3 | No Swift code checks a role or permission name | The client renders capabilities, it does not derive them |
| AC4 | The report gives, for `community.group` in each style: files and lines touched per platform, generated versus hand-written code, setup cost of the codegen, and how Mock, the screen cache (guide 5.3 rule 10) and `make data-check` would work | The decision weighs the whole cost, not only the screen |
| AC5 | The report ends in a recommendation with what it was chosen over, written as a draft decision log row | The reviewer can record the decision directly |

## Technical notes

- Branches per guide 7.1 rule 13, as in SUP-026.
- The screen still goes through `ScreenRegistry` and the coordinators; only where its data comes from changes. Its envelope from `get_screen` may carry empty data.
- Apollo's normalized cache may stand in for the screen cache in the spike; the report says what it covers and what it does not.

## Verification

```
cd ios && make test-unit
```

Then B1 and B2 by hand in the Local build on the spike branch, recorded with `scripts/record.sh`.

## Definition of done

- [ ] All acceptance criteria pass on the spike branch
- [ ] Unit tests added and passing locally
- [ ] The report is complete on the slice branch
- [ ] No work outside Scope

## Open questions

None.
