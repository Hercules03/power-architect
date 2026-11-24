# 64: With no `## Tracker` section, a Small subagent-driven build runs from the local plan as today, with the plan ledger and no Tracker files

**Phase:** /power-architect:build

## Given
- Repo instructions file (AGENTS.md): exists, with no `## Tracker` section
- Tracker state: none
- Ledger / local files:
  - Today is 2026-11-25. There is no `.power-architect/` directory.
  - `docs/specs/2026-11-24-login-lockout.md` exists: the approved spec "Login lockout", Scope Tier Small.
  - `docs/plans/2026-11-24-login-lockout.md` exists: its header's **Spec:** line is `docs/specs/2026-11-24-login-lockout.md`; `## Global Constraints` holds "Five failures within 10 minutes lock the account.", "The lock lasts 15 minutes." and "A locked login returns 423."; `## Review Focus` holds "Failures for different accounts never share a counter (test `counts failures per account`, Task 1)."; then Task 1 "Failed-login counter" (Create `src/auth/attempts.ts`, Test `tests/auth/attempts.test.ts`) and Task 2 "Login handler enforces the lockout" (Modify `src/auth/login.ts:40-62`, Test `tests/auth/login.test.ts`; consumes Task 1's `recordFailure` and `isLocked`), each with five steps ending in a commit.
  - The agent is already in a linked worktree on branch `feat/login-lockout`. The baseline suite `npx vitest run` passes.
- Execution outcomes (take as given; dispatching a subagent is described, not performed): every implementer reports DONE and every review is clean. Task 1: commit `a1b2c3d feat: count failed logins`. Task 2: commit `b2c3d4e feat: lock out repeated failed logins`.
- Trace: report dispatches, ledger writes and any Tracker operation in one chronological list.

## When
The user runs `/power-architect:build`. If asked which execution method to use, they reply "subagent-driven".

## Then
- The agent checks for a `## Tracker` section, finds none, and uses Local Files
- The agent never opens `references/tracker.md` or any `references/tracker-*.md`
- No Tracker operation (publish / pull / record) is attempted and no MCP call is made
- The agent reads `docs/plans/2026-11-24-login-lockout.md` and `docs/specs/2026-11-24-login-lockout.md`
- The ledger is `.power-architect/2026-11-24-login-lockout/progress.md`, whose first line is `# Ledger — plan: docs/plans/2026-11-24-login-lockout.md`. It gets a pre-flight row for Task 1 and Task 2 (they share `recordFailure` / `isLocked`)
- Task 1 is completed (brief → implementer → task review → ledger line) before Task 2's brief is written. Each task brief holds the task's full text from the plan
- The completion lines are `Task 1: complete (commits …, review clean)` and `Task 2: complete (commits …, review clean)`: numbered by task, with no Work Ref and no `tests:` part
- The final reviewer is given the plan's Review Focus verbatim and the spec path `docs/specs/2026-11-24-login-lockout.md`
- The agent recommends `/power-architect:verify`, then `/power-architect:finish`
