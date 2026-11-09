# {Feature Name} Implementation Plan

> **For agentic workers:** execute with `/power-architect:build` (subagent-driven or inline). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** {one sentence}
**Architecture:** {2–3 sentences}
**Tech Stack:** {key technologies}
**Spec:** `docs/specs/YYYY-MM-DD-slug.md`

## Global Constraints

- {project-wide requirement, exact value copied verbatim from the spec}

## Review Focus

- {input class or failure mode no task's tests exercise → the behaviour a reasonable person expects}

---

### Task 1: {Component Name}

**Files:**
- Create: `exact/path/to/file`
- Test: `tests/exact/path/to/test`

**Interfaces:**
- Consumes: {exact signatures from earlier tasks}
- Produces: {exact names and types later tasks rely on}

- [ ] **Step 1: Write the failing test**
- [ ] **Step 2: Run it to verify it fails**: Run: `{command}` Expected: FAIL with "{reason}"
- [ ] **Step 3: Implement `{name(params) -> Return}` in `{path}`**
- [ ] **Step 4: Run it to verify it passes**: Run: `{command}` Expected: PASS
- [ ] **Step 5: Commit**
