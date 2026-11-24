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

- **Spec Page**: the spec's shared context (problem, solution, global decisions, cross-Epic test seams). After `/plan`, it also has a **Plan** section: Goal, Architecture, Global Constraints, Review Focus.
- **Epic**: a cluster of the spec's user stories, grouped by functional area, user persona or system boundary, with its own slice of goals and decisions, and links to the relevant ADRs. A Small-tier spec has one Epic: one the user names, or a new one.
- **Story**: one user story. It carries the user-story sentence and its Acceptance Criteria, and sits under exactly one Epic.
- **Sub-task**: one unit of a plan (a Small-tier plan task, or a Large-tier tracer-bullet ticket), under exactly one Story. It carries `blocks` edges (and `relates` edges for a flagged slice that spans Stories). In the Small tier, it also carries the exact steps and file paths.

A spec is always referred to by its Spec Page's Work Ref.

## Operations

### `publish(outline)`

Called by to-spec (the Spec Page, Epics and Stories) and by plan (Sub-tasks and the Plan section).

- **Returns:** a map from outline id to Work Ref, and a `held` list of items it did not rewrite, each with the reason.
- **Order:** only after the phase's approval gate. Parents are written before children: Spec Page, then Epic, then Story, then Sub-task.
- **Invariants:**
  - **Updates in place.** Items are matched by the Work Refs recorded for this spec, so running it again creates no duplicates.
  - **Never rewrites an item that is In Progress or Done.** That item gets a comment describing the change and goes into `held`.
  - A To Do Story moved to another Epic is re-parented.
  - An item no longer in the outline is never deleted. It gets a "removed from spec" comment and goes into `held`.
- **Errors:**
  - Tracker unreachable: **stop**. Tell the user nothing was published, or exactly what was, and return the Work Refs of what was so the phase can record them.

### `pull(scope, level)`

Called by plan, build, review and verify.

- **Arguments:**
  - `scope`: `sprint` (the active Sprint), a spec, or a Work Ref.
  - `level`: one of three:
    - `story`: the unfinished Stories in scope, in outline order, each with its body and Acceptance Criteria.
    - `subtask`: the unfinished Sub-tasks in scope, plus any Bugs in scope, in `blocks` order with blockers first. Each comes with its body and acceptance criteria.
    - `outline`: the whole Work Outline of the spec, finished items included. This is how a phase reads the spec and plan in Tracker mode.
- **Order:** replays any queued `record` events first (see `record`), then reads.
- **Errors:**
  - Tracker unreachable: **stop**. Never build or verify from a guess.
  - Unknown Work Ref: **stop** and report it.

### `record(ref?, event, evidence)`

Called by build, debug, review, verify and finish.

| Event | Effect |
|---|---|
| `started` | The item moves to In Progress. |
| `done` | The item moves to Done, with a comment holding `evidence` (commits or PR, plus the test command and its result). |
| `note` | A comment on the item. |
| `defect` | With a `ref`: a comment on that item. Without one: a new Bug in the Backlog, never in a Sprint. |
| `shipped` | `ref` is a spec. `evidence` is the PR or merge link. Comments the link on every Story of that spec with at least one Sub-task done on this branch. Changes no status. |

- **Returns:** `ok`, or `queued`.
- **Invariants:**
  - Safe to repeat: replaying an event already applied changes nothing.
  - An item's events apply in the order they were recorded.
- **Order:**
  - For `done`, write the phase's own completion record (such as the ledger line) **before** calling `record`.
  - A `defect` from review always passes the current item's `ref`.
- **Errors:**
  - Tracker unreachable: the event goes into the ledger's `## Tracker queue` and the result is `queued`. **The phase carries on.** The next `pull` that reaches the Tracker replays the queue in order.

## Every Tracker Adapter must

- implement all three operations and the selection check, absorbing any gap in its tracker inside the adapter. A phase never learns that a tracker lacks a feature.
- never create, start, close or edit a Sprint.
- never set story points or estimates.
- hold an **Install** section that `/power-architect:setup-tracker <name>` runs. It checks the connection and writes the repo's `## Tracker` section.
- be the only file that names its tracker's tools or formats.
