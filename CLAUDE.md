# Agent instructions

Before changing anything:

1. Read `docs/ENGINEERING_GUIDE.md`. It governs every task; if a task conflicts with it, the guide wins.
2. Read the spec in `docs/specs/` that your task references.
3. Read your assigned task in `docs/tasks/` and its "Depends on" tasks.

Rules:

- Work only within the task's Scope. Do not expand it.
- If you find ambiguity or a conflict with the guide, stop and ask. Do not guess.
- Decisions that change the guide are recorded in its decision log (section 8) in the same change.
- Temporary code only when a task says so, with every line marked `TEMPORARY(<epic>): <what removes it>`.

## Git

Follow `docs/ENGINEERING_GUIDE.md` 7.1. In short:

- Branch from an up-to-date `main`, named `task/` plus the task file name without `.md` (`task/SUP-002-local-supabase`). Never commit to `main`.
- Split the work into standalone, logical commits ordered for review.
- Commit subject `[<TASK-ID>][<k>/n] <few-word summary>`, where `<k>` counts the task's commits from 1 and `n` is the literal letter `n`. Then a blank line and a short bulleted list of brief details.
- The last commit sets the task's status to Done in the task file, its epic and `docs/BACKLOG.md`.
- Open one PR per task, titled `[<TASK-ID>] <task title>`, with the body from `.github/pull_request_template.md`.
- Never mention Claude, AI, assistants or agents in commits, PRs or review comments. No `Co-Authored-By` or "Generated with" lines.
