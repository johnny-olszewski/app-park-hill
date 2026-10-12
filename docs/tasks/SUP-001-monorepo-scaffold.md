# SUP-001: Create the monorepo scaffold

| Field | Value |
|---|---|
| Area | docs |
| Epic | EP-01 |
| Depends on | None |
| Paired with | None |
| Status | Done |

## Intent

Give every later task a fixed place to put things, with the guide, specs, backlog and template in the repo so agents read them before working. Put the repo on GitHub and set the git workflow every later task follows, so each task arrives as one reviewable PR.

## Scope

- Git repository with the top level layout from `ENGINEERING_GUIDE.md` section 3.
- `/docs` containing the guide, the template, the backlog, `/docs/epics`, `/docs/specs` and `/docs/tasks`.
- Root `README.md`, `CLAUDE.md` and `.gitignore`.
- Private GitHub repository `app-park-hill`, created with the `gh` CLI, with `origin` set and `main` pushed.
- Repository merge settings: merge commits only, head branches deleted on merge.
- Git workflow (branches, commit messages, pull requests, merging) in `ENGINEERING_GUIDE.md` 7.1 and `CLAUDE.md`.
- Pull request template at `.github/pull_request_template.md`.

## Out of scope

- Any backend, iOS or Android project files (SUP-002, IOS-001, AND-001).
- CI workflows, branch protection and required checks (SUP-004, IOS-004, AND-004).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Repo root contains `/backend`, `/contract`, `/ios`, `/android`, `/docs`, `/.github`, each with a `README.md` stating its purpose in one or two lines | Structure is self explaining and directories exist in git |
| AC2 | `/docs` contains `ENGINEERING_GUIDE.md`, `TASK_TEMPLATE.md`, `BACKLOG.md`, `epics/`, `specs/` and `tasks/`, all committed | Planning docs are versioned with the code |
| AC3 | Root `README.md` links to the guide and backlog and states that all work starts from a task | A new contributor or agent finds the rules first |
| AC4 | `.gitignore` covers Xcode (including the generated `.xcodeproj`), Gradle/Android Studio, Supabase local artifacts, `.env*`, the per-developer config override files (IOS-001, AND-001) and OS files such as `.DS_Store` | Secrets, local overrides and build output never get committed |
| AC5 | Root `CLAUDE.md` instructs agents to read the guide, the relevant spec and the assigned task before changing anything, to stop on ambiguity, and to follow the git workflow in guide 7.1 | Agent sessions start with the same rules |
| AC6 | `gh repo view app-park-hill` reports visibility `PRIVATE`, default branch `main`, merge commits allowed, squash and rebase merging disabled, and delete branch on merge enabled; `git remote get-url origin` points to it | Code is backed up, reviewed through PRs, and per-commit history survives merging |
| AC7 | `ENGINEERING_GUIDE.md` 7.1 defines branch naming, the `[<TASK-ID>][<k>/n]` commit message format, PR title and body, merge method and task status updates; `CLAUDE.md` points to it | Every contributor and agent produces the same history |
| AC8 | `.github/pull_request_template.md` exists with sections for the task link, summary, acceptance criteria, verification and reviewer notes | Every PR is reviewed against its task the same way |
| AC9 | SUP-001 lands through a PR from branch `task/SUP-001-monorepo-scaffold` whose commits follow 7.1. The only commit made directly on `main` is `[SUP-001][1/n] Add planning docs`, which created it | The workflow is proven on the first task |

## Technical notes

- Default branch `main`. No code in this task.
- Bootstrap: a PR needs a base branch, so `main` starts with one commit holding `/docs` as planned, pushed directly when the repo is created. Everything else in this task goes through the branch and PR.
- Create the repo with `gh repo create app-park-hill --private --source . --remote origin --push`; set merge settings with `gh repo edit`.

## Verification

```
git ls-files | sort
gh repo view app-park-hill --json visibility,defaultBranchRef,mergeCommitAllowed,squashMergeAllowed,rebaseMergeAllowed,deleteBranchOnMerge
git remote get-url origin
git log --oneline main
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] No work outside Scope

## Open questions

None. Repo `app-park-hill` on GitHub, private (decided 2026-10-10, visibility decided 2026-10-12).
