# 108: With no `## Tracker` section, an inline (S2) build behaves as before: plan ledger lines, no Tracker call, no review marker, and the final review always runs

**Phase:** /power-architect:build

## Given
- Repo instructions file (AGENTS.md): exists, with no `## Tracker` section
- Tracker state: none
- Ledger / local files:
  - Today is 2026-11-25. There is no `.power-architect/` directory. `docs/specs/2026-11-24-login-lockout.md` and `docs/plans/2026-11-24-login-lockout.md` exist as in scenario 64 (Scope Tier Small, two tasks).
  - The agent is already in a linked worktree on branch `feat/login-lockout`. The baseline suite `npx vitest run` passes.
- Execution outcomes (take as given): every command's output matches its `Expected:` line. Task 1: commit `a1b2c3d feat: count failed logins`, `npx vitest run tests/auth/attempts.test.ts` → `2 passed`. Task 2: commit `b2c3d4e feat: lock out repeated failed logins`, `npx vitest run tests/auth/login.test.ts` → `3 passed`. The final review finds nothing Critical or Important.
- Trace: report steps worked, ledger writes and any Tracker operation in one chronological list.

## When
The user runs `/power-architect:build`. If asked which execution method to use, they reply "inline".

## Then
- The agent never opens `references/tracker.md` or any `references/tracker-*.md`, and no Tracker operation (publish / pull / record) and no MCP call is made
- The ledger is `.power-architect/2026-11-24-login-lockout/progress.md`, first line `# Ledger — plan: docs/plans/2026-11-24-login-lockout.md`. No `.power-architect/bugs/progress.md` is written and no `## Tracker queue` section is created
- The completion lines are exactly `Task 1: complete (commits a1b2c3d..a1b2c3d, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)` and `Task 2: complete (commits b2c3d4e..b2c3d4e, tests: npx vitest run tests/auth/login.test.ts → 3 passed)`: numbered by task, with no Work Ref and no `L2` token
- The ledger never gets a `Final review: passed` or `Bug review: passed` line
- The final review diff is the whole-branch merge-base diff (`git merge-base main HEAD`..HEAD), the final review runs, and the final reviewer is given the plan's Review Focus verbatim and the spec path `docs/specs/2026-11-24-login-lockout.md`
- The agent recommends `/power-architect:verify`, then `/power-architect:finish`
