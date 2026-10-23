# Park Hill App

Backend-driven, natively rendered app for iOS (SwiftUI) and Android (Kotlin, Compose) on a Supabase backend.

**All work starts from a task.** Read these before changing anything:

- [Engineering Guide](docs/ENGINEERING_GUIDE.md): the rules every task follows
- [Backlog](docs/BACKLOG.md): slice order and epics; open `docs/` in Obsidian for status (`backlog.base`)
- [Task template](docs/TASK_TEMPLATE.md)

## Layout

| Path | Contents |
|---|---|
| `/backend` | Supabase project: migrations, seed, Edge Functions, tests |
| `/contract` | API contract docs, JSON mock responses and personas |
| `/ios` | SwiftUI app |
| `/android` | Kotlin + Compose app |
| `/docs` | Guide, template, backlog, epics, slices, specs, tasks |
| `/.github` | GitHub Actions workflows |

## Checks

CI runs on every ready pull request; never merge a PR with a failing or pending check (guide 7.1 rule 10). Enable the pre-push hook once per clone, so the fast checks run before each push:

```
git config core.hooksPath .githooks
```
