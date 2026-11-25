# 113: A re-run that also builds a new item for another spec does not absorb that spec's commits into the first spec's review or Done evidence

This scenario is the single-attribution case that follows the user's answer (114 covers the two-commit case).

**Phase:** /power-architect:build

## Given
- Repo instructions file (AGENTS.md):
  ```md
  ## Tracker
  adapter: jira
  site: https://acme.atlassian.net
  cloud-id: 11111111-2222-3333-4444-555555555555
  project: PA
  board: 12
  confluence-space: PASPEC
  confluence-space-id: 98765
  type-epic: Epic
  type-story: Story
  type-subtask: Sub-task
  type-bug: Bug
  status-todo: To Do
  status-in-progress: In Progress, In Review
  status-done: Done
  link-blocks: Blocks
  link-relates: Relates
  ```
- Tracker state: stubbed Rovo table as in scenario 110, extended with spec B: `getConfluenceContent` page 7001 (title "Password reset", Scope Tier `Small`, Review Focus "A reset link works once.", key table `1 | Story | PA-80`, `1 | Sub-task | PA-81`, `2 | Sub-task | PA-82`), PA-81 Sub-task "Reset token store" (parent PA-80, status To Do) and PA-82; each description ends with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/7001`. The sprint lists PA-60, PA-61, PA-82, PA-81 in that order. PA-60 and PA-61 (spec A, Login lockout, page 6001) are In Progress as in scenario 110.
- Ledger / local files:
  - Today is 2026-11-26. Spec A's ledger `.power-architect/2026-11-24-login-lockout/progress.md` is as in scenario 110: `Task PA-60` (`a1b2c3d..a1b2c3d`, S2), `Task PA-61` (`b2c3d4e..b2c3d4e`, S2), `Fix` (`c4d5e6f..c4d5e6f`), no `Final review: passed` line. Spec B's ledger `.power-architect/2026-11-20-password-reset/progress.md` holds its `## Work Refs` table and `Task PA-82: complete (commits 9a8b7c6..9a8b7c6, S2, tests: npx vitest run tests/reset/endpoint.test.ts → 3 passed)`; PA-82 (Sub-task "Reset endpoint", parent PA-80) is In Progress, with no `Final review: passed` line.
  - The agent is in a linked worktree on branch `feat/sprint-7`. Branch history: `a1b2c3d feat: count failed logins`, `b2c3d4e feat: lock out repeated failed logins`, `c4d5e6f fix: count failures per account` (spec A), `9a8b7c6 feat: reset endpoint` (spec B's PA-82, named by spec B's ledger), then `d5e6f7a fix: reset the counter when the lockout expires` (the user's fix for spec A's open finding, named by no ledger). The baseline suite passes.
- Execution outcomes (take as given): PA-81 is the new item, built in this run after spec A: commit `1f2e3d4 feat: reset token store`, `npx vitest run tests/reset/token.test.ts` → `2 passed`. Both final reviews find nothing Critical or Important.
- Trace: report ledger writes, the later-commit computation, final-review diff commands and Tracker operations in one chronological list.

## When
The user runs `/power-architect:build` with no argument. If asked which execution method to use, they reply "inline". When asked which spec owns the uncovered commit, the user answers that `d5e6f7a` belongs to spec A (the first spec).

## Then
- Because two specs lack a marker and one uncovered commit exists, the build asks which spec `d5e6f7a` belongs to before any write; after the answer no further question is asked
- Spec A is processed first (PA-60 appears first in the work list). Before anything is built in this run, the agent computes spec A's later commits as the commits on `<merge-base with the base branch>..HEAD` covered by NO `Task` or `Fix` range in ANY ledger under the ledger root and not Bug commits: the set is exactly `d5e6f7a`, and the trace shows it computed before the first `record(PA-81, started)`
- `Fix (spec https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001): commits d5e6f7a..d5e6f7a` is written to spec A's ledger first. Spec A's review diff is the union of `a1b2c3d`, `b2c3d4e`, `c4d5e6f` and `d5e6f7a`, and neither `9a8b7c6` (spec B's) nor `1f2e3d4` (built later) is in it
- PA-60's and PA-61's `Done` evidence lists only spec A's commits: each item's own commit (`a1b2c3d` for PA-60, `b2c3d4e` for PA-61), then `c4d5e6f` and `d5e6f7a` (the `Fix` lines' `c4d5e6f..c4d5e6f` and `d5e6f7a..d5e6f7a`), then its `tests:` line; it lists neither `9a8b7c6` nor `1f2e3d4`
- Spec B is processed second: PA-81 gets `record(started)` and `Task PA-81: … S2 …` in spec B's ledger only; spec B's final review covers `9a8b7c6` and `1f2e3d4` (the union of its `Task` ranges) and not `d5e6f7a`; the marker is written in spec B's ledger and `record(PA-82, done, …)` and `record(PA-81, done, …)` follow, each evidence listing only spec B's commits
- No MCP write on PA-50 or PA-80. No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call.
