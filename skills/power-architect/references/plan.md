# /power-architect:plan

Read the approved spec and its Scope Tier first. If the spec covers several independent subsystems, propose splitting it into one plan per subsystem.

- **Small tier**: Superpowers `writing-plans` (section A).
- **Large tier**: Matt Pocock's `to-tickets` (section B).

---

## A. Small tier: implementation plan (Superpowers `writing-plans`)

Announce: "I'm writing the implementation plan."

Write the plan for an engineer who has seen neither this codebase nor this spec. Assume they write idiomatic code once they know the exact interface and the exact test, and that they make reasonable choices wherever the plan leaves one open. What they cannot know is what you decided: which files, which names and signatures, which values from the spec, and which tests prove each task. Write those down. DRY. YAGNI. TDD. Frequent commits.

Save to `docs/plans/YYYY-MM-DD-slug.md`.

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
4. **Quiz the user.** Present the breakdown as a numbered list, showing each ticket's **Title**, **Blocked by**, and **What it delivers**. Ask: does the granularity feel right? Are the blocking edges correct? Should any tickets be merged or split? Iterate until the user approves.
5. **Publish** one file per ticket under `docs/plans/YYYY-MM-DD-slug/NN-ticket-slug.md`, numbered from `01` in dependency order (blockers first). Or publish to the configured issue tracker using its native blocking links.

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
