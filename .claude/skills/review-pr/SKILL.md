---
name: review-pr
description: Review a Park Hill pull request against the engineering guide, and against its slice or plan when it has one, posting inline comments like a human reviewer. Run by the PR review workflow; also usable locally. Use when asked to review a PR or a branch.
argument-hint: <PR number>
---

# Review a pull request

Review the PR the way the reviewer (Johnny) would: against the rules this repo writes down, plus ordinary correctness. Read-only: never push, commit, approve, request changes or merge.

## 1. Gather

1. `gh pr view <PR> --json number,title,body,headRefName,baseRefName,commits,files` and `gh pr diff <PR>`.
2. Read `docs/ENGINEERING_GUIDE.md` in full. It governs every check below.
3. Add context by branch prefix (guide 7.1):

| Branch | Read | Also check |
|---|---|---|
| `slice/<ID>-…` | The slice in its epic's Slices section (behavior criteria), every task in it (Scope, Out of scope, acceptance criteria), the spec they reference | The slice checks in section 2 |
| `plan/…` | Every epic, spec and task the PR changes, and the code those tasks name | The planning checks in section 2 |
| `chore/…` | Nothing more | Only the general checks, plus guide 7.1 rule 12 |
| Anything else | Nothing more | Only the general checks |

4. **Re-review.** If this PR already has comments from this reviewer, read them and their replies first. For each, check whether the new commits address it: reply on its thread with what changed, or say why it still stands. Then review only what changed since your last review. Never repeat a comment already made.

## 2. Check

**General, every PR:**

- Correctness: bugs, missed cases, broken error handling, tests that cannot fail.
- The responsibility split (guide 2): clients never re-implement roles or permissions, never hardcode text the backend owns.
- Contract (guide 4.1): changes are additive; names come from `contract/names.json`; a contract change lands with its migration, regenerated fixtures and both client models.
- Build configurations (guide 5.2): no branching on environment in app code; mock and debug code never reachable from a release build.
- Native platform feel (guide 5.5): system components; behavior one platform gets free is built on the other.
- Testing (guide 6): new behavior has tests that run in CI; nothing generated is edited by hand.
- Working agreements (guide 7): temporary code only with `TEMPORARY(<epic>)` markers; decisions that change the guide have a decision log entry in the same PR.
- Git (guide 7.1): commit subjects and bodies follow the format, each commit is standalone, one task's commits are not interleaved with another's.

**Slice PRs:**

- Every change is within its task's Scope; nothing from Out of scope.
- Each acceptance criterion is met, and the PR body says how it was verified. A criterion claimed but not shown is a finding.
- The behavior criteria are reachable from what was built.
- Each task's last commit marks it Done; the branch's last commit marks the slice Done.

**Planning PRs:**

- Tasks match the current code: files, screens, names and tests they mention exist as described.
- Each task has one platform, acceptance criteria a person can verify, and no open questions left unmarked.
- Slice tables in the epic and `docs/BACKLOG.md` agree; dependencies exist.
- No task or slice is set to Done.

## 3. Comment

Each finding is one inline comment on the line it concerns (a file-level comment when no line fits). Start each with its severity:

- **Must-fix:** breaks a guide rule, an acceptance criterion, the task's Scope, or is a correctness bug.
- **Suggestion:** an improvement that no written rule requires.

Then one or two sentences: what is wrong, and the rule or criterion it breaks, cited as `guide 5.2 rule 3`, `IOS-020 AC2` or `EP-05.A B4`. A suggestion names no rule, so say why it is better. Propose the fix when it is short.

Do not comment on style the guide does not cover, on code the PR did not change, or to praise. No finding is better than a weak one.

Finish with one summary comment on the PR: the number of must-fix and suggestion findings, and one line on anything the review could not check (for example a behavior criterion that needs the running app). When there are no findings, the summary says so.

When run locally rather than by the workflow, print the findings in the same form instead of posting them, unless asked to post.
