---
name: ready-slice
description: Check a Park Hill slice against the current code before it is implemented, settle every gap with the user, and mark it Ready on a plan branch. Use when /status names a Draft slice, or when asked to ready, check or prepare a slice (for example "ready EP-03.B").
argument-hint: <slice ID, for example EP-03.B>
---

# Ready a slice

Guide 7.2 rule 7, as steps. Tasks are often drafted before the code they touch exists; this check finds what they no longer fit while fixing it is still a planning edit, not mid-implementation rework. The guide wins on any conflict.

Start only when every slice in the slice's `depends_on` is Done, so the check reads the code the slice will build on.

## 1. Set up

- `git fetch` and switch to an up-to-date `main`.
- Branch `plan/ready-<ID>`, for example `plan/ready-EP-03.B`.

## 2. Read

The guide; the slice file in `docs/slices/`; the spec it references; every task in the slice and its `depends_on` tasks; then the code each task's Scope names or touches.

## 3. Check each task against the code

List every finding, per task, under these headings:

- **Undefined:** a field, term, file or name nobody defines or reads.
- **Stale:** names files, screens, tests, commands or types that changed or no longer exist.
- **Conflict:** with the guide, with the spec, or with another task in the slice.
- **Platform gap:** a behavior one platform gets free from a system component that the other platform's task does not state (guide 5.5 rule 5).
- **Missing tooling:** the Scope needs a generator, script, contract keyword, mock response layout or test helper that does not exist and no task builds.
- **Test data:** the personas, seed rows or mock responses the acceptance and behavior criteria assume are missing or arranged differently.
- **Order:** a task that needs something a later task builds, or a commit that would break another platform's tests until a later task lands (for example a recorded screen the apps do not register yet).
- **Too big:** a slice whose state halfway through is worth having on its own (guide 7.2 rule 2), such as tooling every later slice uses.

## 4. Settle the findings

- Ask the user about every finding that needs a decision, all at once, each with a recommendation. Do not guess.
- Apply the answers to the task, slice, spec or guide files. A decision that changes the guide gets a decision log row (guide 8).
- A slice that is too big is split into slices, with the backlog order and `depends_on` updated.
- Do not write code. Do not widen a Scope beyond what the answers settle.

## 5. Mark it Ready

- Set `status: Ready` on each task in the slice and on the slice.
- Commits `[PLAN][<k>/n] <summary>`; the last one is `[PLAN][<k>/n] Mark <ID> ready`.
- Push and open a PR titled `[PLAN] Ready <ID>`, with the findings and how each was settled. It merges before `/implement-slice <ID>`.

A slice with no findings still gets the PR: its body says what was checked.
