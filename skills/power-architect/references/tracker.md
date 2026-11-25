# Tracker contract

The **Tracker** is where the pipeline keeps work items: local files (the default), or one external tracker named in the repo's config. Phases reach it through three operations: `publish`, `pull` and `record`. Each phase file shows the call, with a `Local:` line beside it saying what to do in Local Files mode. Phases never branch on which tracker is in use.

This file is tracker-neutral. It never names a tracker's tools or formats. Those live only in that tracker's **Tracker Adapter**, `tracker-<name>.md` in this directory.

## Selection

SKILL.md sends you here when the repo's AGENTS.md or CLAUDE.md has a `## Tracker` section. Without one you are in Local Files mode: phases follow their `Local:` lines and never open this file.

1. **A section with `adapter: <name>`:** open `tracker-<name>.md` beside this file. Every operation below then runs as that adapter describes, and you ignore the phase's `Local:` lines.
2. **Stop the phase before any other work**, and tell the user what is wrong, in any of these cases:
   - the section has no `adapter:` line
   - no `tracker-<name>.md` exists
   - the adapter's own config check fails

   Recommend `/power-architect:setup-tracker <name>`. Never fall back to Local Files on your own. The user configured a Tracker, so silently writing local files would hide work from them.

One repo has exactly one Tracker. There are no partial or mixed modes.

## Setup

`/power-architect:setup-tracker <name>` puts a repo into that Tracker's mode.

1. Look for `tracker-<name>.md` beside this file. If none exists, stop: tell the user there is no adapter named `<name>`, and list the adapters that do exist (the `tracker-*.md` files). Write nothing.
2. Otherwise open it and run its **Install** section exactly. Install checks the connection and writes the repo's `## Tracker` section.

Setup does not apply the Selection rules above. A missing, incomplete or different `## Tracker` section is exactly what Install replaces.

## Work Ref

An opaque name for one work item: a key in an external tracker, or a file and anchor in Local Files mode. Phases store it, pass it on and show it to the user, and never parse or build one. Only the adapter knows its shape.

## Work Outline

What `publish` writes and `pull(…, outline)` returns. It carries the spec's **Scope Tier** (Small or Large) at its root. Below that it is a tree, and each item carries an **outline id**, which is stable within one spec:

- **Spec Page**: the spec's shared context (problem, solution, global decisions, cross-Epic test seams). After `/plan`, it also has a **Plan** section holding the plan-level content: in the Small tier the Goal, Architecture, Tech Stack, Global Constraints and Review Focus; in the Large tier an overview of the ticket graph (each ticket's title and what blocks it). The Plan section is not shared context.
- **Epic**: a cluster of the spec's user stories, grouped by functional area, user persona or system boundary, with its own slice of goals and decisions, and links to the relevant ADRs. A Small-tier spec has one Epic: one the user names, or a new one.
- **Story**: one user story. It carries the user-story sentence and its Acceptance Criteria, and sits under exactly one Epic.
- **Sub-task**: one unit of a plan (a Small-tier plan task, or a Large-tier tracer-bullet ticket), under exactly one Story. It carries a title, a description, `blocks` edges (and `relates` edges to Stories, for a flagged slice that spans Stories). In the Small tier, it also carries the exact steps and file paths. Its outline id is the ticket or task number, as text (`01`, or `1`). Outline ids are unique within a kind, so a Sub-task `1` and a Story `1` are different items.

A spec is always referred to by its Spec Page's Work Ref.

## Operations

### `publish(outline)`

Called by to-spec (the Spec Page, Epics and Stories) and by plan (Sub-tasks and the Plan section).

- **Returns:** a map from outline id to Work Ref, a `held` list of items it did not rewrite, each with the reason, and a `declined` list of items it would have written on a re-run but did not, because the user declined the go-ahead. On a re-run, the map holds every item recorded for the spec, including removed ones.
- **Order:** only after the phase's approval gate. Parents are written before children: Spec Page, then Epic, then Story, then Sub-task.
- **Re-run.** When the spec was published before, the outline names its Spec Page's Work Ref and the Work Refs the phase recorded for it. Without them, `publish` asks the Tracker for this spec's existing Spec Page, and the user confirms a match before anything is written. On a re-run, `publish` shows the user a change summary (created, updated, re-parented, held, removed) and waits for their go-ahead before its first write. If nothing changed, it writes nothing.
- **Plan's outline.** plan always names the Spec Page's Work Ref and the recorded Work Refs: it publishes only after to-spec, and never creates a Spec Page. Its first publish (no Sub-task recorded for the spec yet) creates the Sub-tasks and the Plan section without a change summary. Once any Sub-task is recorded, a plan run is a re-run.
- **Invariants:**
  - **Updates in place.** Items are matched by the Work Refs recorded for this spec, so running it again creates no duplicates. Each outline item pairs with a recorded item by its text first (a Story's user-story sentence, an Epic's name, after normalising as below), then by outline id, so renumbering is harmless. If a pairing is ambiguous, the user picks. If an outline item and a recorded item of the same kind both remain unpaired, `publish` never guesses: before any write, its change summary lists each candidate pair and asks the user, for each remaining outline item, "same as <Work Ref>" or "new". The answer is final for this run. A started item the user names as the same is held with a comment, never rewritten; a recorded item no answer claims is removed from spec. A publish that stopped partway is finished, never duplicated.
  - **Compares only user-approved spec content.** On a re-run, `publish` compares only each Story's user-story sentence, each Story's Epic, each Epic's name and its member Stories, and the Spec Page's shared context, and the shared context only when the user changed it in this session (otherwise the page body is kept exactly as read). Sentences and names are compared after normalising case, whitespace, list markers, Markdown escapes and link wrapping; equal after normalising is unchanged and is not written.
  - **Keeps drafted text verbatim.** Story titles, Acceptance Criteria and Epic slices are drafted by the agent, so the Tracker text is their only record. Each item's text starts exactly as read from the Tracker and is never rewritten because the agent would word it differently now. It is redrafted only on an item that is not started, and only when its Story's sentence changed (title and Acceptance Criteria), when its Epic's member Stories change in this run (the slice), or when the user names the item at the go-ahead. Each redraft is shown in the change summary. A redraft equal to the text read (after normalising) is not an update: no write, not listed as updated.
  - **Never rewrites an item that is In Progress or Done** (any status outside the To Do bucket). A started item whose approved spec content changed gets a comment describing the change and goes into `held`. A started Epic whose only change is its member Stories gets no comment.
  - A To Do Story moved to another Epic is re-parented.
  - An item no longer in the outline is never deleted. It gets a "removed from spec" comment and goes into `held`.
  - A comment holds only approved spec text: the old and new user-story sentence, an Epic's old and new name, or the Epic move. Never Acceptance Criteria or other drafted text.
  - A comment is never repeated: an unchanged re-run adds none. A comment starts with a fixed first line, and is a repeat when that line and its changed sentences or Epic lines, compared as normalised text, match an existing comment (a "removed from spec" comment: the first line alone). That text comparison applies to Stories and Epics only; a Sub-task's repeat is decided by the next rule.
  - Recorded items of kinds the outline does not carry (Sub-tasks, when to-spec publishes; Epics and Stories, when plan publishes) are left alone. So is an item the outline names by an existing Work Ref that was not created from this spec.
  - **The Spec Page has two owners.** A to-spec run keeps the Plan section exactly as read. A plan run keeps the shared context exactly as read, and replaces the Plan section only when the approved plan-level content changed.
  - **Sub-tasks follow the same rules, with the plan in place of the spec.** Both tiers compare each Sub-task's title, parent Story, blocked-by set and relates-to set. The Small tier also compares its approved step list. The Large tier compares nothing more: its description is drafted text, kept verbatim. A started Sub-task whose approved content changed gets one comment and goes into `held`. For a held Sub-task, a repeat comment is the same change: the same title, parent Story, blocked-by and relates-to edges added or removed, and for steps the same command(s) and expected result, whatever the wording. If a run asks for the earlier-commented change plus a new one, one new comment holds only the new part; one no longer in the plan gets one "removed from plan" comment. Edges are only ever added: an edge the plan dropped is never deleted, and gets a comment instead. A not-started Sub-task whose blocker or relates-to Story was dropped is still updated where its other approved content changed; the dropped edge stays, one comment explains it, and the item goes into `held` for that edge.
- **Errors:**
  - Tracker unreachable: **stop**. Tell the user nothing was published, or exactly what was, and return the Work Refs of what was so the phase can record them.

### `pull(scope, level)`

Called by plan, build, review and verify.

- **Arguments:**
  - `scope`: `sprint` (the active Sprint), a spec, or a Work Ref.
  - `level`: one of three:
    - `story`: the unfinished Stories of a spec, in outline order, each with its Work Ref, title, body, Acceptance Criteria and status, and whether all its Sub-tasks are finished, naming each that is not. A Story with no Sub-task counts as having an unfinished one. A Bug is never returned.
    - `subtask`: the unfinished Sub-tasks in scope, plus any Bugs in scope, in `blocks` order with blockers first. Each comes with its body and acceptance criteria. With `sprint`, the scope is the Sub-tasks and Bugs in the active Sprint; with a Story's Work Ref, that Story's Sub-tasks; with a Sub-task's or a Bug's Work Ref, that item.
      - A **Bug** has no spec, Story, Scope Tier or `blocks` edge. It is always ready, and comes after every Sub-task in the list.
      - Each item carries its Work Ref, title, description, status, Story, the Spec Page Work Ref of its spec, that spec's Scope Tier, and its blockers with their status. Ties in `blocks` order follow the spec's outline order.
      - An item is **ready** when each of its blockers is finished or comes earlier in the returned list. An item with an unfinished blocker outside scope, or blocked by an item that is not ready, is not returned for building: it comes back in a separate `blocked` list, naming that blocker ("blocked by <Work Ref> outside scope").
    - `outline`: the whole Work Outline of the spec, finished items included: the Spec Page (its shared context and its Plan section), then every Epic, Story and Sub-task with its outline id, kind, status, parent, and `blocks` and `relates` edges. This is how a phase reads the spec and plan in Tracker mode.
- **Order:** replays any queued `record` events first (see `record`), then reads.
- **Errors:**
  - Tracker unreachable: **stop**. Never build or verify from a guess.
  - Unknown Work Ref: **stop** and report it.
  - `sprint` with no active Sprint: **stop** and tell the user. The Product Owner starts Sprints; the agent never does.

### `record(ref?, event, evidence)`

Called by build, debug, review, verify and finish.

| Event | Effect |
|---|---|
| `started` | The item moves to In Progress. |
| `done` | The item moves to Done, with a comment holding `evidence`. For a Sub-task or Bug, that is commits or PR, plus the test command and its result. For a Story (from verify), it is one line per Acceptance Criterion, each with the command that proved it and its result. A Story already Done gets no move and no comment. |
| `note` | A comment on the item. |
| `defect` | With a `ref`: one comment on that item. Without one: a new Bug in the Backlog, never in a Sprint, and no priority, estimate or assignee. A defect already recorded (the same comment, or an open Bug for the same symptom and root cause) adds nothing new to the Tracker's items. |
| `shipped` | `ref` is a spec. `evidence` is the PR or merge link. Comments the link on every Story of that spec with at least one Sub-task done on this branch (the Sub-tasks of the spec ledger's `Task <ref>: complete` lines whose commits are on this branch). Changes no status. The adapter records the delivered Sub-tasks in the ledger before its first write, so a replay re-derives nothing. |

- **Returns:** `ok`, or `queued`.
- **Invariants:**
  - Safe to repeat: replaying an event already applied changes nothing. `started` on an item already In Progress or Done changes nothing; `done` never adds a second evidence comment.
  - An item's events apply in the order they were recorded.
- **Order:**
  - For `done`, write the phase's own completion record (such as the ledger line) **before** calling `record`.
  - A `defect` from review always passes the current item's `ref`.
- **Errors:**
  - Tracker unreachable: the event is **queued** and the result is `queued`. **The phase carries on.** The first failing call decides, and a failure partway through one event queues the whole event (replay repeats it safely). An adapter must queue; it never stops a phase for an unreachable `record`.
- **The queue** is the `## Tracker queue` section of the ledger of the item's spec (for `shipped`, the spec's ledger; for a Bug, the bugs ledger), one line per event: `- [ ] q<N> | <event> | <ref or spec> | <evidence, verbatim, on one line>`. `<N>` rises by one per ledger. Escaping in the evidence: `\` is written `\\`, a literal ` | ` is written ` \| `, a newline is written `\n`. A failure reason is split off at the first unescaped ` | failed: `.
  - **Where.** Ledgers and queues live in the main checkout's `.power-architect/` (the ledger root), never in a linked worktree's, so a build run in a worktree still leaves its queue where later runs find it and where deleting the worktree does not lose it. Replay scans the ledgers under that root only. A sent event becomes `- [x]`; an event that fails for a reason other than an unreachable Tracker becomes `- [!] … | failed: <reason>`.
  - **A defect with no ref** (a Bug to be created) has no item and may have no spec ledger. When the Tracker is unreachable it is queued like any event, into the bugs ledger `<ledger root>/.power-architect/bugs/progress.md` (created with first line `# Ledger — bugs` if missing), as `- [ ] q<N> | defect | - | <evidence verbatim>`. Its replay repeats the open-Bug search first, then comments on the matching Bug or creates one, so a second Bug is never created. Nothing is ever queued behind it (it has no item), and it is never queued behind another entry: an entry with ref `-` never blocks and is never blocked by another entry, each no-ref defect being independent.
  - While an item has an unsent entry (`[ ]` or `[!]`), every later `record` for it (an entry with ref `-` is not an item, so this never applies to it) is queued behind it, without calling the Tracker, so events never overtake.
  - Every `pull` that reaches the Tracker first replays the unsent entries of all ledgers (per ledger in `q` order; ledgers in directory-name order), each as the online `record` would apply it, then reads. It stops replaying at the first unreachable call (and then stops, as `pull` does). A `[!]` entry is reported to the user and blocks only later entries of the same item. The report says how to clear it: after the cause is fixed, change the entry's marker to `- [ ]` to retry it, or to `- [x]` if it was applied by hand.
  - Local Files mode has no Tracker and no queue.

## Every Tracker Adapter must

- implement all three operations and the selection check, absorbing any gap in its tracker inside the adapter. A phase never learns that a tracker lacks a feature.
- never create, start, close or edit a Sprint.
- never set story points or estimates.
- hold an **Install** section that `/power-architect:setup-tracker <name>` runs. It checks the connection and writes the repo's `## Tracker` section.
- be the only file that names its tracker's tools or formats.
