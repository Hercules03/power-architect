# Spec: Tracker with a Jira Adapter

- **Date**: 2026-11-24
- **Status**: Approved by the user on 2026-11-24 (spec gate passed)
- **Scope Tier**: Large. It changes the shared rules, seven phase references and the command set, and adds two new modules: the Tracker contract and the Jira Tracker Adapter. That is cross-cutting work spanning more than one session.

## Problem Statement

Every pipeline output (spec, plan, tickets, progress) lives as Markdown inside the codebase. A user who wants to know what's left to do, what's being built now, and what's finished has to open files and read a ledger. A stakeholder who never opens the repo can't see the project at all. Work is not organised the way Scrum teams run delivery: no Backlog, no Epics by product domain, no Sprints, and no board.

## Solution

A repo can opt into a **Tracker**. When the Tracker is Jira (**Jira Mode**):

- `/power-architect:to-spec` writes the spec's shared context to a Confluence **Spec Page**. It groups the spec's user stories into **Epics** by domain, and the user approves the spec and the grouping together. It then creates the Epics and their **Stories**, each Story with **Acceptance Criteria**.
- `/power-architect:plan` adds **Sub-tasks** under those Stories, joined by "blocks" links.
- `/power-architect:build` works through the active **Sprint** that the user (the **Product Owner**) created. It moves each Sub-task to In Progress when work starts and to Done only after its review passes, with a comment carrying the evidence: the task review for a Small-tier subagent-driven task or a single Large ticket, the spec's final review for an inline task, a whole-graph build or a Bug.
- `verify` closes Stories. `finish` links the delivery. `debug` and `review` file **Bugs**.

The user follows the project on the Jira board and reads work-item descriptions and comments for detail. **Knowledge Docs** stay in the repo: the glossary, ADRs, DESIGN.md and AGENTS.md. Repos without a Tracker behave exactly as they do today.

## Goals / Non-goals / Anti-goals

**Goals**
- Jira becomes where a Jira Mode user looks for the Backlog, Sprint progress and the details of each work item.
- Phases talk to any Tracker through one small interface. Adding GitHub Issues or Linear later means adding one Tracker Adapter, with no edits to any phase.
- Users without a Tracker notice no change, and read nothing new.

**Non-goals**
- Creating, starting, closing or editing Sprints (ADR-0002).
- Story points or any other estimates.
- Adapters other than Jira in this release.
- Mixing trackers, or partial modes (for example, Bugs in Jira but specs local).
- Moving Knowledge Docs out of the repo (ADR-0001).

**Anti-goals** (failure even if it technically works)
- A re-run of to-spec or plan duplicates work items, or overwrites work that has already started.
- A phase file grows "if Jira…" branches, or names Rovo tools.
- Build stalls because Jira is briefly unreachable.
- Jira status says Done for work whose review or verification never passed (the review that covers it: the task review for S1 and L1, the spec's final review for S2, L2 and Bug builds).

## Approaches Considered

Design It Twice produced four designs: minimal (three operations), maximum flexibility (capabilities and overrides), built around the build phase, and ports and adapters with a dry-run adapter.

**Picked: a hybrid.**
- The **three-operation interface**: `publish`, `pull`, `record`.
- **Local Files stays inline** as one line beside each call in the phase files.
- **Tracker Adapter files are pluggable**, chosen by config, with **no capability flags and no partial modes**.

**Rejected**
- The capability and override system: phases would branch on it, and it creates configurations no one can test.
- A separate dry-run adapter: a stubbed Rovo table in test scenarios gives the same coverage without a third adapter to keep in step.

At the integration level, the official **Atlassian Rovo MCP server** was picked over shipped REST scripts or `acli`, so the skill stays code-free (ADR-0002).

## User Stories

**Setup**
1. As a user, I want to run one setup command naming a tracker, so that my repo enters Jira Mode without hand-editing config.
2. As a user, I want setup to check the Rovo MCP server is connected and signed in, and tell me how to connect it if not, so that I don't fail later mid-phase.
3. As a user, I want setup to let me pick the Jira site, project and board from lists, so that I don't look up IDs.
4. As a user, I want setup to find my project's issue-type names for Epic, Story, Sub-task and Bug, so that team-managed and company-managed projects both work.
5. As a user, I want setup to read my project's workflow and propose a To Do / In Progress / Done status mapping for me to confirm, so that custom workflows work.
6. As a user, I want setup to ask for the Confluence space for Spec Pages, so that shared spec context has a home.
7. As a user, I want the result written as a `## Tracker` section in AGENTS.md or CLAUDE.md, so that it is committed and every agent reads it.
8. As a user without a `## Tracker` section, I want every phase to behave exactly as it does today, so that the feature costs me nothing.

**to-spec**

9. As a Product Owner, I want to-spec to propose a grouping of the spec's user stories into Epics (by functional area, persona or system boundary), shown as a table, so that the board reflects product domains.
10. As a Product Owner, I want to approve the spec and the Epic grouping together at the spec gate, so that nothing reaches Jira before I agree.
11. As a user, I want the spec's shared context (the overall problem, global decisions, cross-Epic test seams) on one Confluence Spec Page that every Epic links to, so that it isn't copied into every Epic.
12. As a user, I want each Epic's description to hold only its own slice of goals and decisions, plus links to the Spec Page and the relevant ADRs, so that each Epic reads on its own.
13. As a user, I want each user story created as a Story under exactly one Epic, carrying its user-story sentence and testable Acceptance Criteria, so that the Backlog is ready for Sprint Planning.
14. As a user, I want a Small-tier spec to create one Story (under an Epic I name, or a new one) with no grouping step, so that small changes stay light.
15. As a user, I want the Spec Page to record the key of every item created from it, so that re-runs can find them.
16. As a user, I want a re-run of to-spec to update the existing Spec Page, Epics and Stories in place, so that I never get duplicates.
17. As a user, I want items already In Progress or Done to get a comment rather than a rewrite on re-run, so that work in flight is never silently changed.
18. As a user, I want to-spec to stop and tell me when Jira can't be reached, so that I know the Backlog was not written.

**plan**

19. As a user, I want plan to create the plan's tasks as Sub-tasks under the right Stories, so that each Story shows its implementation breakdown.
20. As a user, I want blocking edges created as "blocks" links between Sub-tasks, so that the build order shows in Jira.
21. As a user, I want plan to cut each Large-tier slice inside one Story, and to flag any exception (filed under its main Story with "relates to" links), so that Sprint planning by Story stays honest.
22. As a user, I want Small-tier Sub-tasks to carry their exact steps and file paths in the description, so that build has everything it needs from Jira.
23. As a user, I want a re-run of plan to update Sub-tasks in place and leave started ones untouched except for a comment, so that re-planning is safe.
24. As a user, I want plan to stop and tell me when Jira can't be reached.

**build**

25. As a Product Owner, I want `/build` with no argument to work through the active Sprint's unfinished Sub-tasks in "blocks" order, so that the agent builds what I committed to.
26. As a user, I want `/build <key>` to build a single Story or Sub-task, so that I can target work.
27. As a user, I want a Sub-task to move to In Progress when its implementer starts, so that the board shows live work.
28. As a user, I want a Sub-task to move to Done only after its review passes (the task review for S1 and L1, the spec's final review for S2, L2 and Bug builds), with a comment giving the commits or PR and the test evidence, so that Done means verified.
29. As a user, I want the local ledger to keep working for resuming builds, so that compaction or crashes don't redo work.
30. As a user, I want build to keep going when Jira can't be reached, queuing status changes and comments in the ledger and replaying them on the next run that can reach it, so that a Jira blip never stalls delivery.
31. As a user, I want replayed updates never to duplicate a comment or a status change.
32. As a user, I want build to stop and tell me when it can't pull its work list from Jira, so that it never guesses what to build.
33. As a Product Owner, I want the agent never to create, start, close or edit a Sprint, so that Sprint scope stays mine.
33a. As a Product Owner, I want a Bug I put into the active Sprint to be built with a regression test first and moved In Progress and then Done like a Sub-task, so that scheduled Bugs get fixed.
33b. As a user, I want plan, review and build's reviewers to read the whole spec from the Tracker, so that no agent needs a local spec file in Jira Mode.

**debug / review**

34. As a user, I want a defect found inside a Story being built to be fixed within that Sub-task and noted in a comment, so that the history stays on the work item.
35. As a Product Owner, I want a defect found outside current work filed as a Bug in the Backlog, so that I can schedule it.
36. As a user, I want review findings fixed within the Sprint without creating work items, so that the Backlog isn't flooded with noise.

**verify / finish**

37. As a user, I want verify to check each Story against its own Acceptance Criteria with fresh evidence and move it to Done only when they all pass, so that Done Stories are proven.
38. As a user, I want verify to stop when it can't read the Stories from Jira.
39. As a user, I want finish to comment the PR or merge-commit link on every Story it delivers, without changing any status, so that I can trace each Story to code.
40. As a user, I want finish's link comments to queue when Jira is down, rather than block the merge.

**Extensibility and transparency**

41. As a maintainer, I want every phase to call only `publish`, `pull` and `record`, so that a new tracker needs one new Tracker Adapter and no phase edits.
42. As a maintainer, I want Rovo tool names, ADF formatting, issue-type names, status mapping, key bookkeeping and queue replay to live only in the Jira Tracker Adapter, so that Jira changes are fixed in one place.
43. As a stakeholder, I want to follow progress on the Jira board without opening the repo.
44. As a user, I want the agent to leave story points blank, so that the team's velocity isn't distorted.

## Implementation Decisions

**The Tracker contract** is a new shared reference that every phase links to. It defines:

- **Selection.** No `## Tracker` section means Local Files: follow the inline `Local:` line at each call. With `adapter: <name>`, follow that adapter's reference. A section that names an adapter that doesn't exist, or that is incomplete, stops the phase and recommends running setup.
- **Work Ref.** An opaque name for a work item. Phases store and echo it and never parse it.
- **`publish(outline)`**, called by to-spec and plan.
  - On a re-run it shows the user a change summary and waits for a go-ahead inside `publish`, before the first write.
  - The Work Outline is: the Spec Page body, then Epics, then Stories with Acceptance Criteria, then Sub-tasks with `blocks` and `relates` edges, plus the tier.
  - It returns the outline ids mapped to Work Refs, and a `held` list of items it did not rewrite.
  - Invariants: it is called only after the gate approval; it upserts by recorded key; it is idempotent; it never rewrites an In Progress or Done item, commenting on it instead.
  - It stops when the Tracker can't be reached.
- **`pull(scope, level)`**, called by build, verify, plan and review.
  - `scope` is `sprint`, a spec, or a Work Ref. `level` is `story`, `subtask` or `outline`.
  - With `story` or `subtask`, it returns the unfinished items, each with its body and Acceptance Criteria. `story` returns the Stories in outline order, with whether each Story's Sub-tasks are all finished, and never Bugs. Only `subtask` uses "blocks" order, and it returns Bugs in the scope after the Sub-tasks.
  - With `outline`, it returns the whole spec as a Work Outline: the Spec Page (including its Plan section) plus every Epic, Story and Sub-task, finished or not. This is how plan, build's reviewers and review read the spec in Tracker mode.
  - It replays queued records first. It stops when the Tracker can't be reached.
- **`record(ref?, event, evidence)`**, called by build, debug, review, verify and finish.
  - Events:
    - `started`: In Progress.
    - `done`: Done, with an evidence comment.
    - `note`: a comment.
    - `defect`: with a ref, a comment on that item; without one, a Bug in the Backlog.
    - `shipped`: a link comment on every Story of the spec, with no status change. Its evidence is `<link> base <sha>`.
    - `declined`: not an event but a `publish` result: items the user declined at the change summary, which `publish` writes nothing for.
  - It is idempotent and keeps each item's events in order.
  - When the Tracker can't be reached, it returns `queued` and the event goes into the ledger's queue. Callers carry on.
  - **Queue format:** each entry is `- [ ] q<N> | <event> | <ref> | <evidence>` in the ledger's `## Tracker queue`; a sent entry becomes `- [x]`. An event that fails for a reason other than an unreachable Tracker becomes `- [!] … | failed: <reason>`, is reported to the user, and blocks only later entries of the same item. The way out: after the cause is fixed, change `[!]` to `[ ]` to retry or to `[x]` if applied by hand.
  - **Bugs ledger:** a `defect` with no ref queues in `.power-architect/bugs/progress.md`, and Bugs built from a Sprint are recorded there.
  - **Ledgers are pinned to the main checkout** (the ledger root), never a linked worktree, so queues survive worktree deletion.
- **Rule for every Tracker Adapter:** it touches no Sprint, writes no estimates, and implements the whole contract. A tracker that lacks a feature (such as sub-tasks) has that gap absorbed inside its adapter, never in a phase.

**The Jira Tracker Adapter** is a new reference, and the only module that mentions Rovo, MCP tool names or ADF. It holds:

- **Install**, run by setup:
  - check the Rovo MCP server is connected and signed in
  - pick the site, project, board and Confluence space
  - find the issue-type names
  - read the workflow and confirm the status mapping
  - write the `## Tracker` section with `adapter: jira`
- **The three operations, mapped onto Rovo MCP tools**:
  - create and edit work items
  - transitions
  - "blocks" and "relates to" links
  - the active Sprint read
  - Confluence page create and update
- **The key table on the Spec Page**, used for the upsert.
- **Markdown** (`contentFormat: markdown`); never build ADF.
- **The ledger's `## Tracker queue` section**: each entry has an id and is marked sent once replayed.

**Setup command.** `/power-architect:setup-tracker <name>` runs that adapter's Install section. It is listed with the other commands in the skill's command table and the README.

**Phase changes** (each is a call line plus a `Local:` line, with no branching):

- **to-spec:** the spec gate also shows the Epic grouping table (in Jira Mode only, and never for the Small tier), then calls `publish`.
- **plan:**
  - Small-tier save and Large-tier publish become `publish` (Sub-task outline).
  - The rule that each slice sits inside one Story joins the Large-tier slicing step.
- **plan** and **review** read the spec through `pull(spec, outline)`. The `Local:` line reads the spec file as today.
- **build:**
  - The work list comes from `pull(arg or sprint, subtask)`.
  - Reviewers get the spec and plan through `pull(spec, outline)`.
  - A Bug in the work list is fixed with the debug method (a regression test first), with `record(started)` and `record(done)` on the Bug.
  - `record(started)` runs before an implementer is dispatched.
  - `record(done, evidence)` runs after the ledger completion line is written and the item's review has passed: after the task review in S1 and L1; for S2, L2 and Bug builds, for every item built in the run after the spec's final review and its one fix pass (the Bug review, for Bugs), and not at all while a Critical or Important finding stays open. Ledger lines `Final review: passed (spec <Spec Page Work Ref>)` and `Bug review: passed (<Bug ref>)` let a resume tell whether `done` may fire. An S2 or L2 `Task` line carries the token `S2` or `L2`, and a resume classifies items by those tokens only (an S1 line, `review clean`, is never deferred). The final review's fix pass is recorded as `Fix (spec <Spec Page Work Ref>): commits a..b`, and the final review diffs the union of the spec's `Task` and `Fix` ranges.
  - The ledger gains a `## Tracker queue` section.
- **debug** clean-up: `record(ref?, defect)`. **review** "acting on" steps always pass the current item's ref, so they only comment and never file a Bug (user story 36).
- **verify:** `pull(spec, story)`, check each Story's Acceptance Criteria, then `record(story, done)`.
- **finish:** after a PR or merge, `record(spec, shipped, link)`.

**SKILL.md:**
- The sentence "if the user has an issue tracker configured…" is replaced by a pointer to the Tracker contract.
- The file-conventions table notes that Tracker-held artifacts replace local spec and plan files, while Knowledge Docs and the ledger stay local.

**Builder's calls** (settled by the spec author; see the builder check):
- **Ledger in Tracker mode:** the ledger is keyed by the spec's slug (`<spec-slug>` instead of `<plan-slug>`). Its first line names the Spec Page's Work Ref. build, verify and finish for that spec share it, including its `## Tracker queue`. A Sprint holding Sub-tasks from several specs uses one ledger per spec.
- **Large-tier mapping:** each tracer-bullet ticket is one Sub-task. Its description holds the ticket's "what to build" and its acceptance criteria. The Large-tier **Plan** section of the Spec Page is a ticket table (`ticket | title | Blocked by`) with no Review Focus. The Small tier's Plan section carries Goal, Architecture, Tech Stack, Global Constraints and Review Focus. Build's reviewers read the Plan section in place of the local plan header.
- **Spec Page layout:** the shared context first (including the Scope Tier), then `## Plan`, then the `## Work Refs` key table last. The ledger's `## Work Refs` is the fallback when the page has no key table.
- **Drafts** live in git-ignored scratch under the ledger root (`.power-architect/<spec-slug>/`), never in the repo's tracked files.
- **`shipped` coverage:** the Stories that have at least one Sub-task done in this branch. A spec is always named by its Spec Page's Work Ref.
- **Structural changes on re-run:**
  - Each outline item's identity is the Work Ref recorded in the key table, not its number, so renumbering is harmless.
  - A To Do Story moved to another Epic is re-parented. A started one gets a comment.
  - A user story removed from the spec is never deleted. Its item gets a "removed from spec" comment and is listed in `held` for the user.

**Unchanged:** grill and design-interface. They write only Knowledge Docs.

## Testing Decisions

- **What makes a good test:** a test checks the external behaviour of a phase, meaning what it writes locally and which Tracker operations it makes with what results. It never checks the exact wording of a prompt.
- **Confirmed seams** (confirmed by the user on 2026-11-24):
  1. **The Tracker contract.** Scenario files in Given / When / Then form. A fresh subagent runs a phase against a **stubbed Rovo table**: fixed tool responses, plus the ability to simulate "unreachable". It writes out the ordered MCP calls it would make. A reviewer then diffs that against Then. Scenarios to cover:
     - a fresh publish with Epic clustering
     - a Small tier producing one Story
     - a re-run against a Done item (`held` plus a comment)
     - the build order from "blocks" links
     - build running offline (queue, then replay with no duplicates)
     - plan or verify stopping when offline
     - a defect with and without a ref
     - finish's `shipped` link fanning out
     - a malformed `## Tracker` section
     - never touching a Sprint
  2. **The local-mode regression.** The same dry-run scenarios with no `## Tracker` section. Each phase must produce today's files and behaviour, and the read trace must never include the Jira adapter.
  3. **The locality check.** A grep for Rovo, MCP tool names and ADF across the skill must match only the Jira Tracker Adapter.
- **Modules tested:** the Tracker contract, the Jira Tracker Adapter, and the seven changed phase references through their call lines.
- **Prior art:** none in this repo; there are no tests today. The builder-check and reviewer subagent prompts are the nearest pattern: a fresh-context subagent judging behaviour from documents.

## Out of Scope

- GitHub Issues, Linear or any adapter other than Jira.
- Sprint management, estimates, velocity reports and burndown.
- Migrating existing local specs and plans into Jira.
- Jira Server or Data Center (the Rovo MCP server is Jira Cloud only).
- Mirroring Knowledge Docs to Confluence.

## Further Notes

- ADR-0001 (Jira owns the work, the repo owns knowledge) and ADR-0002 (Rovo MCP only, no Sprint control) bind this spec.
- Exact Rovo MCP tool names and parameters must be confirmed against Atlassian's current supported-tools page when the adapter is written. Tools differ between MCP v1 and v2.
- The skill does not dogfood Jira Mode: this repo itself stays in Local Files mode.

## Known deviations from this spec

- A Story with "no Sub-tasks planned" is not verifiable, so verify skips it.
- A first publish makes no Tracker search. Its only guard against a duplicate Spec Page is the create's duplicate-title rejection, which makes the phase ask the user one question before any other write. The accepted gap: with a lost ledger and a title that differs from the existing page, a run silently republishes a duplicate Spec Page and a full duplicate item set.
- The Local-mode sentence about an issue tracker configured through `/setup-matt-pocock-skills` is retained in SKILL.md, not replaced by a pointer.

## Resolved decisions

- Resolved (user decision 2026-11-25): S2, L2 and Bug builds used to record Done right after the ledger line, before any review of the item, which conflicted with user story 28. Done is now deferred until after the spec's final review and its single fix pass (the Bug review, for Bugs); an open Critical or Important finding withholds it.
