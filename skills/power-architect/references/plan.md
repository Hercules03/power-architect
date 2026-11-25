# /power-architect:plan

In Local Files mode, read the approved spec and its Scope Tier first (with a Tracker, `pull` below reads them). If the spec covers several independent subsystems, propose splitting it into one plan per subsystem.

A step with a `Local:` line below it reads two ways. With a Tracker configured, do what the step says. Without one (no `## Tracker` section), do only what its `Local:` line says.

**Read the spec from the Tracker.** Find its Spec Page's Work Ref: the first line of a ledger `.power-architect/<spec-slug>/progress.md` under the ledger root (see the "Where" bullet in [tracker.md](tracker.md#recordref-event-evidence)) names it (`# Ledger — spec: <Work Ref>`; if several ledgers do, ask the user which spec). Without one, ask the user for the Spec Page's Work Ref or URL. If they have none, stop: there is no published spec to plan from, so recommend `/power-architect:to-spec`. Never plan from a local spec file. Then call `pull(<Spec Page Work Ref>, outline)` (see the [Tracker contract](tracker.md#pullscope-level)): it returns the Scope Tier, the Spec Page (shared context, and a Plan section if plan ran before), the Stories with their Acceptance Criteria, and any Sub-tasks. If `pull` stops, stop the phase: write nothing and tell the user no plan was made. If the Tracker was unreachable, recommend re-running `/power-architect:plan` once it is reachable. If the Work Ref is unknown, ask the user to check the Spec Page's Work Ref and the ledger's first line. `<spec-slug>` is the ledger's directory name; without a ledger, today's date and the spec title's slug.
`Local:` Read the spec file.

**Re-plan.** If `pull` returned Sub-tasks, plan ran before. Start from the plan as read from the Tracker, not from a fresh draft: the Plan section's content, and each Sub-task's title, Story, blocked-by and relates-to edges and description (Small tier: its files and steps too), all as read. Apply only the changes the user asks for in this session, and changes where the spec changed. A new session would word things differently; that is not a change. A change to a started or Done Sub-task is held, not applied, so it is not in what was read: it is published again only if the user asks for it again. `publish` then compares it with the comment the Tracker already holds for that item; the same change (same title, Story, links, and for steps the same commands and expected result, whatever the wording) adds no comment and no write, and a different change, or a new part beside an already-commented one, adds one comment holding only the new part. If the user does not ask for it again, nothing is written or commented for that item.
`Local:` Nothing to read; plan as below.

- **Small tier**: Superpowers `writing-plans` (section A).
- **Large tier**: Matt Pocock's `to-tickets` (section B).

---

## A. Small tier: implementation plan (Superpowers `writing-plans`)

Announce: "I'm writing the implementation plan."

Write the plan for an engineer who has seen neither this codebase nor this spec. Assume they write idiomatic code once they know the exact interface and the exact test, and that they make reasonable choices wherever the plan leaves one open. What they cannot know is what you decided: which files, which names and signatures, which values from the spec, and which tests prove each task. Write those down. DRY. YAGNI. TDD. Frequent commits.

Write the plan as a draft to `.power-architect/<spec-slug>/plan-draft.md` under the ledger root (git-ignored scratch). Its header's **Spec:** line names the Spec Page's Work Ref. Nothing reaches the Tracker before the user approves the plan at Handoff.
`Local:` Save to `docs/plans/YYYY-MM-DD-slug.md`.

### File structure first

Before defining tasks, map which files are created or modified and what each is responsible for. Give each file one clear responsibility. Prefer smaller, focused files. Files that change together live together, split by responsibility, not by technical layer. In existing codebases, follow established patterns.

### Task right-sizing and steps

A task is the smallest unit that carries its own test cycle and is worth a fresh reviewer's gate. Fold setup, configuration, scaffolding, and docs into the task whose deliverable needs them. Split only where a reviewer could reject one task while approving its neighbour. Each step is one action with a checkable result.

### Plan header (required)

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** execute with `/power-architect:build` (subagent-driven or inline). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [one sentence]
**Architecture:** [2–3 sentences]
**Tech Stack:** [key technologies]
**Spec:** [path to the spec; executors read both]

## Global Constraints
[The spec's project-wide requirements, one line each, with exact values copied verbatim. Every task implicitly includes this section.]

## Review Focus
[The five input classes or failure modes the spec implies but no task's tests exercise that are most likely to bite a user, one line each, naming the input or condition and the behaviour a reasonable person expects, most likely first. For each line, add the test that pins it to the task that owns the code.]

---
```

### Task structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks, as exact signatures]
- Produces: [what later tasks rely on: exact names, parameter and return types]

- [ ] **Step 1: Write the failing test**   (test name + assertions as code, with the spec's exact values)
- [ ] **Step 2: Run it to verify it fails**   Run: `<command>`  Expected: FAIL with "<reason>"
- [ ] **Step 3: Implement `name(params) -> Return` in `path`**   (one line on the approach if the signature and test leave a choice; a code body only for an algorithm they don't determine)
- [ ] **Step 4: Run it to verify it passes**   Run: `<command>`  Expected: PASS
- [ ] **Step 5: Commit**   `git add <files> && git commit -m "<message>"`
````

A step is done when the implementer can write exactly one reasonable thing from it. A plan longer than the code it describes has written the code instead. Lines that decide nothing ("TBD", "handle edge cases", "add validation", "write tests for the above", a type no task defines) are the opposite failure.

### Self-review (run it yourself, not a subagent)

1. **Spec coverage:** every spec requirement points to a task. Add a task for any gap.
2. **Step scan:** no step decides nothing, and no step contains a body the signature and tests already determine.
3. **Type consistency:** names and signatures in later tasks match earlier tasks (`clearLayers()` vs `clearFullLayers()` is a bug).
4. **Review Focus:** each line has its test in its owning task. An empty section means you checked, not that you skipped the check.
5. **Proportion:** if code blocks are most of the document, replace bodies with signatures, test names, and assertions.

Fix issues inline.

### Handoff

Link the plan, ask the user to review it, and ask which execution method they want, with your recommendation and a one-sentence reason (how much the tasks depend on each other's interfaces, how many there are, what a shipped mistake would cost):

- **Subagent-driven**: a fresh implementer and a fresh reviewer per task, then a whole-branch review. Most thorough.
- **Inline**: you implement every task in this session, then one fresh reviewer checks the whole branch. Cheapest.

**Publish.** Wait for the user to approve the plan. Then build the [Work Outline](#work-outline) from the approved draft, call `publish(outline)` (see the [Tracker contract](tracker.md#publishoutline)), and update the [ledger](#ledger).
`Local:` Nothing to publish; the plan file is the record.

Then recommend `/power-architect:build`.

---

## B. Large tier: tracer-bullet tickets (Matt `to-tickets`)

1. **Gather context** from the spec and the conversation.
2. **Explore the codebase** if you haven't already. Use glossary vocabulary and respect ADRs. Look for **prefactoring** opportunities: "make the change easy, then make the easy change."
3. **Draft vertical slices.** Each ticket is a tracer bullet:
   - It cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests). It is vertical, never a horizontal slice of one layer.
   - A completed ticket is demoable or verifiable on its own.
   - Each ticket fits in a single fresh context window.
   - Any prefactoring comes first.

   Give each ticket its **blocking edges**: the tickets that must finish before it can start.

   **Wide refactors are the exception.** When one mechanical change fans across the codebase (rename a column, retype a shared symbol), use **expand–contract**: expand (add the new form beside the old) → migrate call sites in batches sized by blast radius, each batch its own ticket blocked by the expand → contract (delete the old form) in a ticket blocked by every batch. If even the batches can't stay green alone, they share an integration branch and all block a final integrate-and-verify ticket.

   **Each ticket sits inside one Story** (the spec's Stories, from `pull`). Give each ticket its Story. A slice that truly spans Stories is the rare exception: file it under its main Story, give it a relates-to edge to each other Story it spans, and flag it in the quiz.
   `Local:` No Stories; slice as above.
4. **Quiz the user.** Present the breakdown as a numbered list, showing each ticket's **Title**, **Blocked by**, and **What it delivers**. Ask: does the granularity feel right? Are the blocking edges correct? Should any tickets be merged or split? Iterate until the user approves.

   Show each ticket's **Story** too, and end the list with a summary that flags each ticket spanning Stories (its main Story and the others). Keep the breakdown in `.power-architect/<spec-slug>/tickets-draft.md` under the ledger root (git-ignored scratch), updated after every change. Nothing reaches the Tracker before the user approves.
   `Local:` As above: no Story, no draft file.
5. **Publish.** Number the tickets from `01` in dependency order (blockers first), build the [Work Outline](#work-outline) from the approved breakdown, call `publish(outline)` (see the [Tracker contract](tracker.md#publishoutline)), and update the [ledger](#ledger).
   `Local:` Publish one file per ticket under `docs/plans/YYYY-MM-DD-slug/NN-ticket-slug.md`, numbered from `01` in dependency order (blockers first). Or publish to the configured issue tracker using its native blocking links.

Ticket template (no file paths or code snippets; the prototype exception from the spec applies):

```markdown
# NN: <Ticket title>

**What to build:** the end-to-end behaviour this ticket makes work, from the user's perspective, not a layer-by-layer list.

**Blocked by:** NN, NN, or "None (can start immediately)".

**Status:** ready-for-agent

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2
```

The **frontier** is every ticket whose blockers are done. Recommend `/power-architect:build 01`, or `/power-architect:build all` to run the whole graph.

---

## Work Outline

Built at Publish from the approved draft. `Local:` not built.

- **Scope Tier**: Small or Large.
- **Earlier publish**: the Spec Page's Work Ref and the ledger's `## Work Refs` rows. Plan always has them, because it follows a published spec.
- **Plan section**: Small tier: the Goal, Architecture, Tech Stack, Global Constraints and Review Focus, as in the plan header. Large tier: each ticket's number, title and Blocked by.
- **Sub-tasks**, one per Small-tier task or Large-tier ticket:
  - outline id: the task number (`1`) or the ticket number (`01`), as text
  - title: the task's name, or the ticket's title
  - Story: its Story's outline id. Small tier: the spec's one Story
  - blocked by: the outline ids of its blockers. Large tier: its blocking edges. Small tier: only the earlier tasks whose interfaces it consumes, never just the task before it
  - relates to: the other Stories a flagged ticket spans (Large tier only)
  - description: Large tier: the ticket's What to build and its acceptance criteria. Small tier: the task's Files, Interfaces and steps with their commands, exactly as in the plan

## Ledger

After `publish` returns, replace the `## Work Refs` table of the ledger `.power-architect/<spec-slug>/progress.md` (under the ledger root) with one row per item it returned (`outline id | kind | Work Ref | title`), leaving the rest of the ledger unchanged. Without a ledger, write one: first line `# Ledger — spec: <the Spec Page's Work Ref>`, then that table.

- If `publish` stops partway, record what it returned the same way and tell the user the plan is only partly published. Re-running plan finishes it without duplicates.
- On a re-run, `publish` shows a change summary and waits for the user's go-ahead. Afterwards tell the user each `held` item with its reason. If `declined` is not empty, tell the user nothing was written and list the declined items.

`Local:` No ledger is written here.
