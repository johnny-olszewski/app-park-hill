<!-- Title: [<slice ID>] <slice title> (planning PRs: [PLAN] <summary>; chore PRs: [CHORE] <summary>) -->

## Slice

[<slice ID>: <slice title>](docs/slices/<slice file>.md)

## Summary

<!-- One or two sentences: what behavior this delivers and why. -->

## Tasks

<!-- One entry per task, in the slice's order: its acceptance criteria and how each was verified, saying which were verified at the end of the slice. -->

### [<TASK-ID>: <task title>](docs/tasks/<TASK-ID>-short-name.md)

- [ ] AC1:

```
```

## Behavior acceptance criteria

<!-- Copy the slice's behavior criteria from the epic. The reviewer checks these by using the result. -->

- [ ] 

## Reviewer notes

<!-- Decisions made, deviations, follow-ups or open questions. "None" if nothing. -->

None.

## Checklist

- [ ] Branch is named `slice/<slice ID>-<short name>`
- [ ] Each task's commits follow `[<TASK-ID>][<k>/n]`, are standalone and logical, and are not interleaved with another task's
- [ ] The slice was Ready before implementation started (guide 7.2 rule 7)
- [ ] Each task's unit and backend tests ran before the next task; UI tests, `make test-local` and the release check ran once at the end (guide 7.2 rule 4)
- [ ] Every CI check is green; never merge red (guide 7.1 rule 10)
- [ ] `make test-local` passed locally in each app the slice touches, when it changes an app, `/backend` or `/contract` (CI runs Mock only)
- [ ] Every behavior criterion recorded in `recordings/<slice ID>/` (not linked here)
- [ ] Each task, and then the slice, set to `status: Done` in its own file
- [ ] No work outside the Scope of the slice's tasks
