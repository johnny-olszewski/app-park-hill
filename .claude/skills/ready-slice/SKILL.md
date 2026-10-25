---
name: ready-slice
description: Check a Park Hill slice against the current code before its tasks are implemented, settle every gap with the user, and mark it Ready, as the first commits on its slice branch. Run by /implement-slice for a Draft slice; also usable alone when asked to ready, check or prepare a slice (for example "ready EP-03.B").
argument-hint: <slice ID, for example EP-03.B>
---

# Ready a slice

Guide 7.2 rule 7, as steps. Tasks are often drafted before the code they touch exists; this check finds what they no longer fit while fixing it is still a planning edit, not mid-implementation rework. Its commits come first on the slice branch; there is no separate planning PR. The guide wins on any conflict.

Start only when every slice in the slice's `depends_on` is Done, so the check reads the code the slice will build on.

## 1. Set up

On the slice branch. `/implement-slice` has already created it; run alone, create it the same way: from an up-to-date `main`, `slice/<ID>-<short-kebab-name>`, with `git config core.hooksPath .githooks` once per clone.

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
- Write no task's code yet. Do not widen a Scope beyond what the answers settle.

## 5. Mark it Ready

- Set `status: Ready` on each task in the slice and on the slice.
- Commit the planning changes first on the slice branch, before any task's commits: subjects `[<ID>][<k>/n] <summary>`, the last one `[<ID>][<k>/n] Mark <ID> ready`.
- Keep the findings and how each was settled for the slice PR's Reviewer notes.

Run alone, stop here: implementation continues with `/implement-slice <ID>` on the same branch. A slice with no findings still gets the `Mark <ID> ready` commit, and its PR says what was checked.
