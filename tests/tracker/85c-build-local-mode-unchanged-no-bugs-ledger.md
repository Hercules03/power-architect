# 85c: With no `## Tracker` section, a build runs from the local plan, never reads Tracker files and never writes a bugs ledger

**Phase:** /power-architect:build

## Given
- Repo instructions file (AGENTS.md): exists, with no `## Tracker` section
- Tracker state: none
- Ledger / local files:
  - Today is 2026-11-25. There is no `.power-architect/` directory. `docs/specs/2026-11-24-login-lockout.md` and `docs/plans/2026-11-24-login-lockout.md` exist as in scenario 64 (Scope Tier Small, two tasks).
  - The agent is in a linked worktree on branch `feat/login-lockout`. The baseline suite passes.
- Execution outcomes (take as given): every implementer reports DONE and every review is clean. Task 1: commit `a1b2c3d`. Task 2: commit `b2c3d4e`.
- Trace: report dispatches, ledger writes and any Tracker operation in one chronological list.

## When
The user runs `/power-architect:build`. If asked which execution method to use, they reply "subagent-driven".

## Then
- The agent never opens `references/tracker.md` or any `references/tracker-*.md`, and no MCP call or Tracker operation is made
- The ledger is `.power-architect/2026-11-24-login-lockout/progress.md` with first line `# Ledger — plan: docs/plans/2026-11-24-login-lockout.md`; no `.power-architect/bugs/progress.md` is written
- The completion lines are `Task 1: complete (commits …, review clean)` and `Task 2: complete (commits …, review clean)`
- The final review diff is the whole-branch merge-base diff and it runs
