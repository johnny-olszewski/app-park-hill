# SUP-001: Create the monorepo scaffold

| Field | Value |
|---|---|
| Area | docs |
| Epic | EP-01 |
| Depends on | None |
| Paired with | None |
| Status | Draft |

## Intent

Give every later task a fixed place to put things, with the guide, specs, backlog and template in the repo so agents read them before working.

## Scope

- Git repository with the top level layout from `ENGINEERING_GUIDE.md` section 3.
- `/docs` containing the guide, the template, the backlog, `/docs/epics`, `/docs/specs` and `/docs/tasks`.
- Root `README.md`, `CLAUDE.md` and `.gitignore`.

## Out of scope

- Any backend, iOS or Android project files (SUP-002, IOS-001, AND-001).
- CI workflows (SUP-004, IOS-004, AND-004).

## Acceptance criteria

| # | Criterion | Intent |
|---|---|---|
| AC1 | Repo root contains `/backend`, `/contract`, `/ios`, `/android`, `/docs`, `/.github`, each with a `README.md` stating its purpose in one or two lines | Structure is self explaining and directories exist in git |
| AC2 | `/docs` contains `ENGINEERING_GUIDE.md`, `TASK_TEMPLATE.md`, `BACKLOG.md`, `epics/`, `specs/` and `tasks/`, all committed | Planning docs are versioned with the code |
| AC3 | Root `README.md` links to the guide and backlog and states that all work starts from a task | A new contributor or agent finds the rules first |
| AC4 | `.gitignore` covers Xcode (including the generated `.xcodeproj`), Gradle/Android Studio, Supabase local artifacts, `.env*`, the per-developer config override files (IOS-001, AND-001) and OS files such as `.DS_Store` | Secrets, local overrides and build output never get committed |
| AC5 | Root `CLAUDE.md` instructs agents to read the guide, the relevant spec and the assigned task before changing anything, and to stop on ambiguity | Agent sessions start with the same rules |

## Technical notes

Default branch `main`. No code in this task.

## Verification

```
git ls-files | sort
```

## Definition of done

- [ ] All acceptance criteria pass
- [ ] No work outside Scope

## Open questions

None. Repo name `app-park-hill` on GitHub (decided 2026-10-10).
