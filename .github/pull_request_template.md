<!-- Title: [<slice ID>] <slice title> (planning PRs: [PLAN] <summary>; chore PRs: [CHORE] <summary>) -->

## Slice

[<slice ID>: <slice title>](docs/epics/<EP-##-name>.md#slices)

## Summary

<!-- One or two sentences: what behavior this delivers and why. -->

## Tasks

<!-- One entry per task, in the slice's order: its acceptance criteria and how each was verified. -->

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
- [ ] Each task was verified before the next started
- [ ] Every CI check is green; never merge red (guide 7.1 rule 10)
- [ ] `make test-dev` passed locally in each app the slice touches, when it changes an app, `/backend` or `/contract` (CI runs Mock only)
- [ ] Every behavior criterion recorded in `recordings/<slice ID>/` (not linked here)
- [ ] Each task, and then the slice, set to Done in its files, the epic and `docs/BACKLOG.md`
- [ ] No work outside the Scope of the slice's tasks
