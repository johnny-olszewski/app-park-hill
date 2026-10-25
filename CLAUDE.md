# Agent instructions

Park Hill is a real app and a proving ground for a transferable architecture and an agent-driven way of working (`docs/ENGINEERING_GUIDE.md`, Purpose). When two approaches both work, prefer the one that generalizes and that the next agent can follow from the repo alone.

Start a session with `/status`: where the work stands and the next step. Implement a slice with `/implement-slice <ID>`; it first checks a Draft slice against the code (`/ready-slice`), with those commits first on the slice branch. Act on a PR's review with `/address-review <PR>` once its checks have finished. The skills live in `.claude/skills/`.

Before changing anything:

1. Read `docs/ENGINEERING_GUIDE.md`. It governs every task; if a task conflicts with it, the guide wins.
2. Read your assigned slice in `docs/slices/`, and the spec in `docs/specs/` it references.
3. Read every task in the slice in `docs/tasks/`, and their `depends_on` tasks.

Rules:

- Work only within the Scope of the slice's tasks. Do not expand it.
- Write no task's code until the slice is Ready (guide 7.2 rule 7), then implement its tasks in the slice's order. Checks run in tiers (guide 7.2 rule 4): fast checks every commit; a task's unit and backend tests before the next task; UI tests, `make test-local` and the behavior criteria once, at the end of the slice. iOS and Android tasks may run in parallel worktrees once the backend tasks are committed.
- If you find ambiguity or a conflict with the guide, stop and ask. Do not guess.
- Decisions that change the guide are recorded in its decision log (section 8) in the same change.
- Temporary code only when a task says so, with every line marked `TEMPORARY(<epic>): <what removes it>`.

## Git

Follow `docs/ENGINEERING_GUIDE.md` 7.1 and 7.2. In short:

- Branch from an up-to-date `main`, named `slice/` plus the slice ID and a short name (`slice/EP-06.B-mock-sign-in`). Never commit to `main`.
- Split each task's work into standalone, logical commits ordered for review. Finish one task's commits before starting the next.
- Commit subject `[<TASK-ID>][<k>/n] <few-word summary>`, where `<k>` counts that task's commits from 1 and `n` is the literal letter `n`. Then a blank line and a short bulleted list of brief details.
- Each task's last commit sets `status: Done` in its task file's frontmatter. The branch's last commit, `[<slice ID>] Mark <slice ID> done`, sets `status: Done` in the slice file (guide 7.3).
- Open one PR per slice, titled `[<slice ID>] <slice title>`, with the body from `.github/pull_request_template.md`.
- Planning-only changes use `plan/` branches (guide 7.1 rule 9).
- Housekeeping that implements no task (renames, tooling) uses `chore/` branches (guide 7.1 rule 12).
- Never merge a PR with a failing or pending check (guide 7.1 rule 10). Enable the pre-push hook once per clone: `git config core.hooksPath .githooks`.
- Never mention Claude, AI, assistants or agents in commits, PRs or anything posted under a person's account, including replies to review comments. No `Co-Authored-By` or "Generated with" lines. Only the automated reviewer's own bot comments are exempt (guide 7.1 rule 11).
- Every PR gets one automated review when ready; fix must-fix comments, apply suggestions in separate commits for the reviewer to verify, and ask first about guide or Scope changes (guide 7.1 rule 11).
