# Power Architect

A skill pipeline (grill → design-interface → to-spec → plan → build → review → verify → finish) that turns an idea into shipped code. These terms cover how that pipeline tracks work, optionally in Jira under Scrum.

## Tracking work

**Tracker**:
Where the pipeline keeps work items. It is either local files (the default) or one external tracker named in the repo's config.
_Avoid_: backend, integration

**Tracker Adapter**:
The single reference file that teaches the pipeline one external Tracker. A repo uses exactly one Tracker Adapter, or none.
_Avoid_: plugin, connector

**Work Ref**:
An opaque name for one work item, such as a Jira key or a local file anchor. Phases pass it along and never interpret it.
_Avoid_: ticket ID, key

**Work Outline**:
The tree of one spec's work: its Spec Page, Epics, Stories and Sub-tasks, plus its Scope Tier. It is what the pipeline publishes to the Tracker, and how it reads the spec back.
_Avoid_: backlog dump, ticket tree

**Local Files mode**:
The repo state with no Tracker configured: specs, plans and progress are Markdown files in the repo.

**Ledger root**:
The main checkout of the repo, where every spec's progress ledger and offline queue live, whichever worktree the agent works in.

**Tracker queue**:
The list of events the pipeline could not send while the Tracker was unreachable. They are sent on the next successful read.

**Plan section**:
The part of a Spec Page that holds the plan-level content of a spec's plan, kept apart from the spec's shared context.

**Jira Mode**:
The repo state in which the configured Tracker is Jira.
_Avoid_: Jira sync, Jira integration

**Knowledge Docs**:
Documents that agents read alongside the code and that always stay in the repo, in every mode: the glossary, ADRs, DESIGN.md, AGENTS.md.
_Avoid_: project docs, agent docs

**Spec Page**:
The page in the Tracker's document space that holds a spec's shared context (overall problem, global decisions, cross-Epic test seams) and that every Epic from that spec links to.
_Avoid_: master spec, design doc

**Backlog**:
The set of Stories not yet finished, from which Sprints are filled.

**Epic**:
A cluster of a spec's user stories, grouped by functional area, user persona, or system boundary. One spec yields one or more Epics.
_Avoid_: feature, initiative

**Story**:
One numbered user story from a spec, held as a Backlog item under exactly one Epic. A Small-tier spec is filed as a single Story.
_Avoid_: ticket, requirement

**Sub-task**:
One implementation task from a plan, under exactly one Story.
_Avoid_: task, step

**Acceptance Criteria**:
The testable checks written on a Story that `/verify` proves before the Story is Done.

**Bug**:
A defect found outside the Stories currently being built, held in the Backlog for the Product Owner to schedule. A defect inside current work is fixed in its Sub-task and is not a Bug.
Its event name in the pipeline is `defect`.
_Avoid_: issue

## Iterating

**Sprint**:
A time-boxed iteration that the Product Owner creates and fills in the Tracker. The build → review → verify → finish loop runs once per Sprint, and the thinking phases run once per spec.

**Product Owner**:
The user, who decides what goes into each Sprint. The agent only proposes a grouping.
