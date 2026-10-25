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

## 2. Make the slice Ready

If the slice file says Draft, run `/ready-slice <ID>` now, on this branch: it checks every task against the code, asks you about every finding at once, and commits the answers and `Mark <ID> ready` before any task's code (guide 7.2 rule 7). Continue only once it has.

If it is already Ready (the check ran earlier on this branch), read in this order: the guide; the slice file in `docs/slices/` (behavior criteria B1…); the spec it references; every task in the slice and its `depends_on` tasks.

Either way, if you find something the check missed (undefined, stale, in conflict with the guide, or missing a behavior one platform gets free from a system component, guide 5.5 rule 5), stop and ask with a recommendation. Do not guess, and do not expand the Scope.

## 3. Implement each task, in the slice's order

For each task:

1. Split the work into standalone, logical commits ordered for review, and commit each piece as it is written rather than splitting finished work afterwards. Each commit builds on its own (section 4); it does not have to pass every test.
2. Commit message: subject `[<TASK-ID>][<k>/n] <few-word summary>` (`k` counts that task's commits from 1, `n` is the literal letter), a blank line, then a short bulleted list. Write it to a file and use `git commit -F <file>`. Never mention Claude, AI, assistants or agents, and add no `Co-Authored-By` or "Generated with" lines.
3. Before its last commit, run the task-tier checks for the platforms it touched (section 4) and verify the acceptance criteria they cover. A criterion only a UI test or the running app shows is verified at the merge gate, after the last task; say so in the PR. Run a single UI test while you build it if that is faster than guessing, but not a whole suite.
4. The task's last commit marks it Done: set `status: Done` in the task file's frontmatter.
5. Finish one task's commits before starting the next. Do not interleave tasks.

Practices that kept slices clean:

- **Contract changes:** migration, `make mock-responses`, then `make data-check` in `/backend`; update both clients' models in the same slice. A new mock response can break the client mock response tests, so run both clients' unit tests in the commit that adds it.
- **Platforms in parallel** (guide 7.2 rule 4): once the backend and contract tasks are committed, the iOS and Android tasks may run at the same time.
  1. From the slice branch's tip, `git worktree add ../<repo>-<platform> -b slice/<ID>-<platform>` for the platform the slice lists second, and start a second session there for its tasks. This session does the first platform's tasks on the slice branch. Each follows this section and runs its own platform's checks. Nothing needs pushing: worktrees share the repository.
  2. Neither changes the contract, the mock responses or the other platform's files. If one must, stop both and finish that change on the slice branch first.
  3. Run `make test-local-smoke` in one worktree at a time: both use local Supabase and reset it.
  4. When both are done, `git worktree remove ../<repo>-<platform>` (a branch checked out in another worktree cannot be rebased). Then `git rebase slice/<ID> slice/<ID>-<platform>` puts the second platform's commits after the first's, in the slice's order; `git switch slice/<ID> && git merge --ff-only slice/<ID>-<platform>` joins them, and `git branch -d slice/<ID>-<platform>` cleans up. The merge gate runs on the joined branch.
- **Removing something tests depend on:** move the tests off it in an earlier commit, so every commit stays green.
- **History** may be rewritten (fixup and autosquash) only before the first push. After review starts, changes are new commits continuing the numbering (guide 7.1 rule 7).
- **Temporary code** only when a task says so, every line marked `TEMPORARY(<epic>): <what removes it>`.

## 4. Checks by tier

Each check runs at the cheapest point that still catches what it is for (guide 7.2 rule 4).

| Tier | `/backend`, `/contract` | `/ios` | `/android` |
|---|---|---|---|
| Every commit | Migrations apply | Mock app and tests compile | Mock app and tests compile |
| Every task | `cd backend && supabase db reset && supabase test db && make data-check`; `make test-functions` when functions change; `make test-scripts` when scripts change | `make test-unit` | `make test-unit` |
| Merge gate, once per slice | As every task | `make test-smoke`; `make test-local-smoke` | `make test-unit`; `make test-smoke`; `make test-local-smoke`; `./gradlew assembleLocalRelease && scripts/check_release_apk.sh <apk>` |
| Nightly, in CI | | `make test-full` | `make test-full`; `make test-local` |

- **Every commit:** before the first push, `scripts/check_commits.sh` builds what each commit changed (no tests). Run it in the background while recording.
- **Smoke tests** are listed in each app's `smoke-mock.txt` and `smoke-local.txt`. A slice that adds a screen adds its one main-path UI test to them; its other UI tests run nightly.
- **Merge-gate runs** go in the background as soon as the last task is committed; record and write the PR while they run, one `make test-local-smoke` at a time.
- `make test-local-smoke` needs Docker and local Supabase, and must pass in each app the slice touches before the PR (CI runs Mock only). After checking Local behavior by hand against the database, restore any rows you changed.

## 5. Finish the slice

1. Start the merge-gate checks and `scripts/check_commits.sh` in the background (section 4). A failure is fixed in the commit that caused it, with a fixup before the first push.
2. Verify every behavior criterion (B1…) by using the apps, in Mock and Local, and record each one while verifying it (guide 7.2 rule 4):
   - In the apps: boot the simulator and the emulator, then `scripts/record.sh start <ID> <B#-build-what> ios` and `... android`, show the behavior on both, then `scripts/record.sh stop`. Prefer recording a UI test run that shows the criterion (one test, `-only-testing` or the runner's `class` argument) over driving the app by hand; drive by hand only what no test shows. One recording per criterion and build, short and showing only that criterion.
   - For developers: `scripts/record.sh terminal <ID> <B#-what> "<commands>"`, showing the failure and the passing run where the criterion is about a check failing.
   - Check every criterion has its recordings in `recordings/<ID>/`. Do not link them in the PR; tell the user the folder.
3. Last commit on the branch: `[<ID>] Mark <ID> done`, setting `status: Done` in the slice file.
4. Push, then open one PR titled `[<ID>] <slice title>` with the body from `.github/pull_request_template.md`: each task with how each criterion was verified, then the behavior criteria as an unchecked list for the reviewer, then reviewer notes: the readiness check's findings and how each was settled, then decisions, deviations and follow-ups.
5. Tell the user the PR link, what changed, what was verified, where the recordings are, and any decisions made. CI must be green before merging, never red or pending (guide 7.1 rule 10).
6. Watch the PR: if this session can be notified of its checks and review comments (for example the desktop app's PR monitor, with addressing comments and fixing checks turned on), turn that on. When every check has finished, including the automated review, run `/address-review <PR>` (guide 7.1 rule 11).
