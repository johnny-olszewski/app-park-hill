---
name: address-review
description: Act on a Park Hill PR's review comments and failing checks once the checks have finished: fix must-fix findings, apply suggestions for the reviewer to verify, and reply on every thread. Use when the review is in, when the PR monitor reports comments or failing checks, or when asked to address a review.
argument-hint: <PR number>
---

# Address a review

Follows guide 7.1 rules 7 and 11. Work on the PR's own branch, checked out and up to date with the remote.

## 1. Wait, then gather

1. Start only when every check on the PR has finished (none pending) and the automated review has posted its summary comment. If not, say what is still running and stop.
2. Read the failing checks' logs (`gh pr checks <PR>`, `gh run view <run> --log-failed`) and every unresolved review comment with its thread (`gh api repos/{owner}/{repo}/pulls/<PR>/comments`).
3. Sort each comment as **Must-fix** or **Suggestion**, by the label it starts with. Comments from a person count as must-fix unless they say otherwise.

## 2. Stop and ask first

Change nothing for a comment, of either severity, that asks to:

- change `docs/ENGINEERING_GUIDE.md` or add a decision log entry, or
- do work outside the Scope of the PR's tasks.

List these for the user with a recommendation, and reply on the thread that it is waiting for the reviewer's decision. A comment you believe is wrong is also listed, with your reasoning, rather than fixed.

## 3. Fix

1. **Failing checks and must-fix comments first.** Fix them, run the checks for the areas changed (`/implement-slice` section 4), and commit.
2. **Then suggestions**, in separate commits after every must-fix commit, so each can be reverted alone.
3. Commits continue the numbering of the task whose code they change: after `[IOS-020][3/n]` comes `[IOS-020][4/n]` (guide 7.1 rule 7). On a planning branch they continue `[PLAN][<k>/n]`. Never rewrite reviewed commits. Never mention tools, assistants or agents.
4. Run `scripts/check_commits.sh` with the relevant build command, then push.

## 4. Reply

1. On each thread: the commit that addresses it, in a short sentence. For a suggestion: "Applied as a suggestion in <commit>; to verify."
2. One PR comment headed **Suggestions to verify**, listing each applied suggestion with its commit and one line on what changed. The reviewer reverts any they reject, with a new commit.
3. Do not resolve threads; the reviewer resolves them.

Replies and the summary are posted under the user's account, so they follow the same rule as commits: no mention of tools, assistants or agents.

## 5. Report

Tell the user what was fixed, what was applied as a suggestion, what waits for their decision, and the state of the checks after the push. Do not request a re-review; the user does that by commenting `@claude review`.
