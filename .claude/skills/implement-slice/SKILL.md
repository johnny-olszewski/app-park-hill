---
name: implement-slice
description: Implement one Park Hill slice end to end, from branch to pull request, following the engineering guide. Use when asked to implement, build or start a slice (for example "implement EP-05.A" or "start the next slice").
argument-hint: <slice ID, for example EP-05.A>
---

# Implement a slice

The workflow in `CLAUDE.md` and `docs/ENGINEERING_GUIDE.md` 7.1 and 7.2, as steps. The guide wins on any conflict. If the slice ID is missing, run `/status` first.

## 1. Set up

- `git fetch` and switch to an up-to-date `main`. Never commit to `main`.
- `git config core.hooksPath .githooks` (once per clone).
- Branch `slice/<ID>-<short-kebab-name>`, for example `slice/EP-06.B-mock-sign-in`.

## 2. Read, then re-check the plan against the code

Read in this order: the guide; the slice in its epic's Slices section (behavior criteria B1…); the spec it references; every task in the slice and its "Depends on" tasks.

Task drafts are often written before the code they touch exists. Before writing code, check each task against the current code and stop to ask about anything that is:

- undefined (a field or term nobody defines or reads),
- stale (it names files, screens or tests that changed or no longer exist),
- in conflict with the guide,
- missing a behavior one platform gets free from a system component (guide 5.5 rule 5).

Ask with a recommendation. Do not guess, and do not expand the Scope.

## 3. Implement each task, in the slice's order

For each task:

1. Split the work into standalone, logical commits ordered for review. Each commit builds and passes its tests on its own.
2. Commit message: subject `[<TASK-ID>][<k>/n] <few-word summary>` (`k` counts that task's commits from 1, `n` is the literal letter), a blank line, then a short bulleted list. Write it to a file and use `git commit -F <file>`. Never mention Claude, AI, assistants or agents, and add no `Co-Authored-By` or "Generated with" lines.
3. Verify every acceptance criterion and run the task's tests before its last commit.
4. The task's last commit marks it Done: `scripts/mark_done.py <TASK-ID>` updates the task file, its epic and `docs/BACKLOG.md`.
5. Finish one task's commits before starting the next. Do not interleave tasks.

Practices that kept slices clean:

- **Contract changes:** migration, `make fixtures`, then `make data-check` in `/backend`; update both clients' models in the same slice. A new fixture can break the client fixture tests, so run both clients' unit tests in the commit that adds it.
- **Removing something tests depend on:** move the tests off it in an earlier commit, so every commit stays green.
- **Before pushing:** `scripts/check_commits.sh "<build and test command>"` runs a check on every commit of the branch. History may be rewritten (fixup and autosquash) only before the first push. After review starts, changes are new commits continuing the numbering (guide 7.1 rule 7).
- **Temporary code** only when a task says so, every line marked `TEMPORARY(<epic>): <what removes it>`.

## 4. Checks by area

| Change | Run |
|---|---|
| `/backend`, `/contract` | `cd backend && supabase db reset && supabase test db && make data-check && make test-functions` |
| `/ios` | `cd ios && make project`, then the Mock scheme's `test`; `make test-dev` |
| `/android` | `cd android && ./gradlew testMockDebugUnitTest testDevDebugUnitTest connectedMockDebugAndroidTest`; `make test-dev`; `./gradlew assembleDevRelease && scripts/check_release_apk.sh <apk>` |

`make test-dev` needs Docker and local Supabase, and must pass in each app the slice touches before the PR (CI runs Mock only). After checking Dev behavior by hand against the database, restore any rows you changed.

## 5. Finish the slice

1. Verify every behavior criterion (B1…) by using the apps, in Mock and Dev.
2. Last commit on the branch: `[<ID>] Mark <ID> done`, using `scripts/mark_done.py <ID>`.
3. Push, then open one PR titled `[<ID>] <slice title>` with the body from `.github/pull_request_template.md`: each task with how each criterion was verified, then the behavior criteria as an unchecked list for the reviewer, then reviewer notes (decisions, deviations, follow-ups).
4. Tell the user the PR link, what changed, what was verified, and any decisions made. CI must be green before merging, never red or pending (guide 7.1 rule 10).
