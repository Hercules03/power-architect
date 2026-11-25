# 97: when Jira is down, finish queues the shipped link comment and the merge still goes ahead

**Phase:** /power-architect:finish

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
- Tracker state: stubbed Rovo table. Every tool, including `atlassianUserInfo`, returns UNREACHABLE.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | * | any | UNREACHABLE |
- Items:
  - PA-5 Epic "Account security" (To Do); PA-70 Bug "Lockout counter is off by one" (To Do, no parent, Backlog).
  - PA-50 Story "Lock out repeated failed logins" (Done, parent PA-5); PA-51 Story "Admins see lockouts" (In Progress, parent PA-5); PA-52 Story "Password reset clears a lockout" (To Do, parent PA-5).
  - Sub-tasks: PA-60 and PA-61 (Done, parent PA-50); PA-62 (Done, parent PA-51); PA-63 (To Do, parent PA-52).
- Ledger / local files:
  - Today is 2026-11-25. `/repo/.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table (Spec Page, Epic PA-5, the Stories and Sub-tasks of the Items list), and the lines `Task PA-60: complete (commits a1b2c3d..a1b2c3d, review clean, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)`, `Task PA-61: complete (commits b2c3d4e..b2c3d4e, …)` and `Task PA-62: complete (commits c3d4e5f..c3d4e5f, …)`. PA-63 has no `Task` line. `/repo/.power-architect/bugs/progress.md` has `Task PA-70: complete (commits d4e5f6a..d4e5f6a, …)`. Neither has a `## Tracker queue` section.
  - `/repo` is the main checkout. The agent is in a linked worktree `/repo/.worktrees/lockout` on branch `feat/login-lockout`, forked from `main`. `git log` on the branch holds a1b2c3d, b2c3d4e, c3d4e5f and d4e5f6a; every one of them is reachable from the branch's HEAD. The base branch is `main`. `git merge-base main feat/login-lockout` returns `9f8e7d6`; the Task commits are NOT on `main`.
- Execution outcomes (take as given): the full suite passes (`14 passed`). `git push -u origin feat/login-lockout` succeeds. Opening the PR returns `https://github.com/acme/app/pull/42`. A local merge into `main` succeeds, the tests on the merged result pass (`14 passed`), and the merge commit is `e5f6a7b8`.
- Trace: report Tracker operations, MCP calls, shell commands, ledger writes and what is said to the user in one chronological list.

## When
The user runs the phase. When asked which option, they reply `1`.

## Then
- The user's `1` is followed: from the main repo root `git checkout main`, `git pull`, `git merge feat/login-lockout`, and the tests on the merged result pass
- `record(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001, shipped, e5f6a7b8 base 9f8e7d6)` is called once, after the merge tests pass and before the worktree cleanup. finish makes no `pull` call
- The delivered Sub-tasks come from the ledger and git alone, with no Tracker read: the ledger gains `Shipped: e5f6a7b8 — base 9f8e7d6 — Sub-tasks PA-60, PA-61, PA-62`
- The first Rovo call of `record` returns UNREACHABLE, so no comment is added. The result is `queued`
- `/repo/.power-architect/2026-11-24-login-lockout/progress.md` gains a `## Tracker queue` section holding exactly `- [ ] q1 | shipped | https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001 | e5f6a7b8 base 9f8e7d6`
- finish does not stop and does not undo the merge: it goes on with step 6: `git worktree remove` of the worktree, `git worktree prune`, then `git branch -d feat/login-lockout`. The main checkout's `.power-architect/` is not deleted
- No Rovo call is made after the first UNREACHABLE. No retry, no read, no write
- The agent tells the user the merge is done and that the `Shipped` link comment is queued, not yet in Jira, and that the next `pull` replays it. It never says the link was commented
