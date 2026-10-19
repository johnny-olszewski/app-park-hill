# Agent instructions

Park Hill is a real app and a proving ground for a transferable architecture and an agent-driven way of working (`docs/ENGINEERING_GUIDE.md`, Purpose). When two approaches both work, prefer the one that generalizes and that the next agent can follow from the repo alone.

Before changing anything:

1. Read `docs/ENGINEERING_GUIDE.md`. It governs every task; if a task conflicts with it, the guide wins.
2. Read your assigned slice in its epic's Slices section (`docs/epics/`), and the spec in `docs/specs/` it references.
3. Read every task in the slice in `docs/tasks/`, and their "Depends on" tasks.

Rules:

- Work only within the Scope of the slice's tasks. Do not expand it.
- Implement the tasks in the slice's order. Verify each task's acceptance criteria and run its tests before starting the next; verify the slice's behavior criteria at the end.
- If you find ambiguity or a conflict with the guide, stop and ask. Do not guess.
- Decisions that change the guide are recorded in its decision log (section 8) in the same change.
- Temporary code only when a task says so, with every line marked `TEMPORARY(<epic>): <what removes it>`.

## Git

Follow `docs/ENGINEERING_GUIDE.md` 7.1 and 7.2. In short:

- Branch from an up-to-date `main`, named `slice/` plus the slice ID and a short name (`slice/EP-06.B-mock-sign-in`). Never commit to `main`.
- Split each task's work into standalone, logical commits ordered for review. Finish one task's commits before starting the next.
- Commit subject `[<TASK-ID>][<k>/n] <few-word summary>`, where `<k>` counts that task's commits from 1 and `n` is the literal letter `n`. Then a blank line and a short bulleted list of brief details.
- Each task's last commit sets it to Done in the task file, its epic and `docs/BACKLOG.md`. The branch's last commit, `[<slice ID>] Mark <slice ID> done`, sets the slice to Done in its epic and `docs/BACKLOG.md`.
- Open one PR per slice, titled `[<slice ID>] <slice title>`, with the body from `.github/pull_request_template.md`.
- Planning-only changes use `plan/` branches (guide 7.1 rule 9).
- Never merge a PR with a failing or pending check (guide 7.1 rule 10). Enable the pre-push hook once per clone: `git config core.hooksPath .githooks`.
- Never mention Claude, AI, assistants or agents in commits, PRs or review comments. No `Co-Authored-By` or "Generated with" lines.
