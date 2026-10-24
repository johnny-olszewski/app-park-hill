# Task Template

Copy this file to `/docs/tasks/<ID>-short-name.md`, where `<ID>` is the next number for the task's platform: `SUP-###` (backend), `IOS-###` or `AND-###`. Set its `epic`, and add its ID to one slice's `tasks` in `/docs/slices/` (guide 7.2 and 7.3). Fill every section. Write "None" instead of deleting a section.

Writing rules:

- A task fits one agent session and one PR. If it needs more than about 8 acceptance criteria, split it.
- Every acceptance criterion is checkable by a command, a test, or a specific observation. Each one states its intent, so the implementer knows what must stay true if the approach changes.
- A task targets exactly one platform, so a developer with that platform's skills can own it end to end. Work spanning platforms is split into one task per platform.
- When iOS and Android implement the same behavior, their tasks are counterparts: acceptance criteria match; only the technical notes differ. Link them with `paired_with`. Include behavior a system component gives one platform for free, such as transitions and gestures (guide 5.5 rule 5).
- Name exact paths and commands. Do not leave choices to the implementer unless the task says "implementer's choice".

---

---
type: task
id: <ID>
title: "Title (verb first)"
area: backend  # backend / contract / ios / android / ci / docs (all within one platform)
epic: EP-##
depends_on: []  # task IDs from any platform
paired_with: []  # counterpart task on the other client platform
status: Draft  # Draft / Ready / In progress / In review / Done
---

# <ID>: Title (verb first)

## Intent

Two or three sentences. Why this exists and what it unlocks. No implementation detail.

## Scope

- What this task delivers.

## Out of scope

- What it deliberately does not do, and which task does it if known.

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Given / when / then, or a plainly checkable statement | Why this matters |

## Technical notes

Paths, names, patterns to follow, references to sections of `ENGINEERING_GUIDE.md`. Constraints only, not a tutorial.

## Verification

Exact commands or steps that prove the acceptance criteria.

```
command here
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] Tests added and passing locally and in CI (once the platform's CI task is done)
- [ ] No environment branching in app code; no mock or debug code reachable from release configurations
- [ ] Contract changes include mock response and both client models
- [ ] Docs updated if behavior or structure changed
- [ ] No work outside Scope

## Open questions

Anything unresolved. A task with open questions is not Ready. An implementer who hits ambiguity stops and asks.
