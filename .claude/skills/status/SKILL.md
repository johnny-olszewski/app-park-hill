---
name: status
description: Report where Park Hill work stands and what to do next. Use at the start of a session, or when asked for status, progress, "what's next" or "where are we".
---

# Status

Read-only. Report where the work stands and name the one next step. Change nothing.

## Gather

Run these together:

1. `git fetch -q`, then `git status --short --branch` and `git log --oneline -1 origin/main`. Note the current branch, uncommitted work, and whether local `main` is behind.
2. `gh pr list --json number,title,headRefName,isDraft,statusCheckRollup`: open PRs and their checks.
3. `docs/BACKLOG.md`: the **Slice order** list and every epic's **Slices** table (status per slice).
4. For the candidate next slice only: its epic's Slices section (title, behavior criteria, tasks in order, depends on) and each task's Status.

## Decide what is next

Apply the first rule that matches. Do not use judgment beyond these.

1. **Open slice PR** (`slice/...` branch): it is in review. Next step: wait for its checks and the review. Never merge a red or pending check (guide 7.1 rule 10).
2. **Slice in progress**: a local or remote `slice/...` branch with commits beyond `origin/main` and no open PR. Next step: finish it with `/implement-slice <ID>`.
3. **Open planning PR** (`plan/...`): it must merge before the slices it plans start.
4. Otherwise, the **first slice in the backlog's Slice order** that is not Done and whose "Depends on" slices are all Done. Next step: `/implement-slice <ID>`.
5. If that next piece of work is an epic with no Slices section yet, the next step is planning its slices on a `plan/` branch (guide 7.2), not implementing.

Blockers to report with the next step: a dependency not Done, failing checks on an open PR, uncommitted changes, local `main` behind `origin/main`.

## Report

Keep it short. One line each, then the next step:

```
Done:         EP-01.A–C, EP-06.A–C, EP-02.A
In review:    none
In progress:  none
Next:         EP-07.B <title> (SUP-030, IOS-031, AND-031)
Blockers:     none
Next step:    /implement-slice EP-07.B
```

When rule 5 applies, say so instead: `Next: EP-05 has no slices yet. Next step: plan its slices (plan/ branch).`

Then stop and wait. Do not start the next step unless the user asks.
