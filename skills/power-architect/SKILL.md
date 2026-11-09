---
name: power-architect
description: Hybrid software architecture and TDD execution workflow combining Matt Pocock's skills and Jesse Vincent's Superpowers. Use when the user asks to design, architect, spec, plan, implement, debug, or review software features, or invokes slash commands like /grill, /design-interface, /to-spec, /plan, /build, /debug, /review, or /retro. Guides the user step-by-step and always prompts the next recommended slash command.
---

# Power Architect

Power Architect merges Matt Pocock's front-end domain modeling and vertical-slice architecture with Jesse Vincent's Superpowers TDD execution, automating low-level implementation and verification.

## When to Use

- Starting a new feature, refactor, or system architecture design
- Interrogating requirements and updating domain documentation (`/grill`)
- Exploring module boundaries and deep interfaces (`/design-interface`)
- Turning discussions into formal specifications (`/to-spec`) and actionable plans (`/plan`)
- Executing code via size-adaptive TDD (`/build`)
- Investigating bugs or test failures scientifically (`/debug`)
- Running two-stage spec and code quality reviews (`/review`) or session retrospectives (`/retro`)

## Directory Convention

Store and maintain all project artifacts inside the `docs/` directory, creating subdirectories automatically as needed:

- `docs/CONTEXT.md`: Canonical domain glossary, ubiquitous language, and system mental model
- `docs/adr/NNN-slug.md`: Architectural Decision Records for significant technical trade-offs
- `docs/specs/YYYY-MM-DD-slug.md`: Approved feature specifications and interface contracts
- `docs/plans/YYYY-MM-DD-slug.md`: Execution plans (micro-tasks or vertical tracer-bullet slices)
- `docs/retros/YYYY-MM-DD-slug.md`: Post-implementation retrospectives and architecture health notes

## Core Workflow Steps

### Step 1: Triage and Next-Command Routing
At the start of any request and at the end of every response, evaluate the current state of the task and display a **Next Step Footer** recommending the exact slash command to run next.

### Step 2: Interrogate and Align (`/grill`)
1. Check `docs/CONTEXT.md` and `docs/adr/` if they exist to align with established domain terms.
2. Identify unresolved branches in the requirements decision tree (edge cases, state transitions, error boundaries, data ownership).
3. Ask focused, high-leverage questions (1 to 3 at a time).
4. Update `docs/CONTEXT.md` with new domain terminology and record major architectural choices in `docs/adr/NNN-slug.md`.
5. Prompt the user to run `/design-interface` or `/to-spec`.

### Step 3: Deepen Interfaces (`/design-interface`)
1. Propose at least two radically different interface designs ("Design It Twice") for the target module or seam.
2. Optimize for **deep modules** (simple, narrow public signatures that hide substantial internal complexity).
3. Compare trade-offs across testability, cognitive load, and coupling, then prompt `/to-spec`.

### Step 4: Synthesize Specification (`/to-spec`)
Consolidate the agreed design into `docs/specs/YYYY-MM-DD-slug.md`:
1. Include Problem Statement, Ubiquitous Language refs (`docs/CONTEXT.md`), Interface Contracts, Data Flow, Edge Cases, and Verification Criteria.
2. Estimate the **Scope Tier**:
   - **Micro / Small**: 1 to 3 files, well-defined single seam, zero architectural ambiguity.
   - **Medium / Large**: 4+ files, multiple system seams, database/state migrations, or cross-cutting concerns.
3. Present the spec summary and Scope Tier to the user, then prompt `/plan`.

### Step 5: Size-Adaptive Planning (`/plan`)
Generate `docs/plans/YYYY-MM-DD-slug.md` tailored to the approved Scope Tier:
- **Micro / Small Scope (Autonomous Micro-Task Plan)**: Deconstruct into 2 to 5 minute micro-tasks with exact file paths, failing test first, implementation approach, and verification command. Prompt `/build`.
- **Medium / Large Scope (Interactive Vertical Slices)**: Deconstruct into end-to-end tracer-bullet vertical slices with explicit blocking edges (`Slice 1 -> Slice 2`). Prompt `/build slice-1`.

### Step 6: Disciplined TDD Execution (`/build`)
Execute the plan using strict **Red-Green-Refactor** discipline:
1. **Git Isolation Check**: Verify a clean test baseline on a dedicated branch or git worktree.
2. **Red-Green-Refactor Loop**: Write failing test first (RED) -> minimal code to pass (GREEN) -> deepen modules (REFACTOR).
3. **Execution Autonomy by Scope Tier**:
   - **Micro / Small (Auto Mode)**: Execute all micro-tasks sequentially with an internal Two-Stage Self-Review (Stage 1: Spec Compliance; Stage 2: Code Quality) after each task.
   - **Medium / Large (Interactive Vertical Slice Mode)**: Execute only the current vertical slice, show passing test output and diff summary, update `docs/plans/`, and pause for `/build slice-N+1`.

### Step 7: Scientific Debugging (`/debug`)
1. **Reproduce**: Establish a deterministic reproduction command or failing test.
2. **Hypothesize**: Trace data flow backward and list 2 to 3 ranked, falsifiable hypotheses.
3. **Instrument and Verify**: Confirm root cause before changing logic.
4. **Fix and Guard**: Apply minimal root-cause fix with a regression test and remove temporary logs.

### Step 8: Two-Stage Review and Retrospective (`/review` & `/retro`)
1. **`/review`**: Pass 1 checks Spec Compliance against `docs/specs/`; Pass 2 checks Code Quality, module depth, and `docs/CONTEXT.md` naming alignment.
2. **`/retro`**: Record lessons learned and architectural debt in `docs/retros/YYYY-MM-DD-slug.md`.

## Mandatory Next-Step Prompt Format

```text
---
[Power Architect | Current Phase: <Phase Name> | Scope Tier: <Micro/Small | Medium/Large | TBD>]
Artifacts Updated: <list of docs/... paths or "None">
Recommended Next Step:
- Run `<slash-command>` to <concise explanation of what happens next>
- Alternative: Run `<alt-slash-command>` if you want to <alternative action>
```
