# 98: finish makes no Tracker call when the user keeps the branch as-is

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
- Tracker state: stubbed Rovo table (a tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name; rows match top to bottom; the stub keeps state within this dry run).

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getConfluenceContent | page 6001 | {id: "6001", title: "Login lockout", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): the shared context of "Login lockout" (Scope Tier `Small`), a `## Plan` section, then the key table: the `spec` row and one row per Epic, Story and Sub-task of the Items list, as `<outline id> \| <kind> \| <key>`} |
  | getJiraIssue | a key in the Items list | that item's row: key, type, summary, status, parent, and description. A Story's description is its user-story sentence, `## Acceptance Criteria` with its `- [ ]` lines, then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`. A Sub-task's description is one line then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001` |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to`. Live input schema: `cloudId`, `issueIdOrKey`, `transitionId`, `transitionName`, `fields`, `sprintId`, `assignToBacklog`, `boardId` |
  | listJiraIssueComments | any | the comments listed for that issue in this Given, plus the comments this dry run has added to it |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} (n increments from 10). Live input schema: `cloudId`, `issueIdOrKey`, `commentBody`, `commentId` |
- Items:
  - PA-5 Epic "Account security" (To Do); PA-70 Bug "Lockout counter is off by one" (To Do, no parent, Backlog).
  - PA-50 Story "Lock out repeated failed logins" (Done, parent PA-5); PA-51 Story "Admins see lockouts" (In Progress, parent PA-5); PA-52 Story "Password reset clears a lockout" (To Do, parent PA-5).
  - Sub-tasks: PA-60 and PA-61 (Done, parent PA-50); PA-62 (Done, parent PA-51); PA-63 (To Do, parent PA-52).
- Ledger / local files:
  - Today is 2026-11-25. `/repo/.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table (Spec Page, Epic PA-5, the Stories and Sub-tasks of the Items list), and the lines `Task PA-60: complete (commits a1b2c3d..a1b2c3d, review clean, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)`, `Task PA-61: complete (commits b2c3d4e..b2c3d4e, …)` and `Task PA-62: complete (commits c3d4e5f..c3d4e5f, …)`. PA-63 has no `Task` line. `/repo/.power-architect/bugs/progress.md` has `Task PA-70: complete (commits d4e5f6a..d4e5f6a, …)`. Neither has a `## Tracker queue` section.
  - `/repo` is the main checkout. The agent is in a linked worktree `/repo/.worktrees/lockout` on branch `feat/login-lockout`, forked from `main`. `git log` on the branch holds a1b2c3d, b2c3d4e, c3d4e5f and d4e5f6a; every one of them is reachable from the branch's HEAD. The base branch is `main`.
- Execution outcomes (take as given): the full suite passes (`14 passed`). `git push -u origin feat/login-lockout` succeeds. Opening the PR returns `https://github.com/acme/app/pull/42`. A local merge into `main` succeeds, the tests on the merged result pass (`14 passed`), and the merge commit is `e5f6a7b8`.
- Trace: report Tracker operations, MCP calls, shell commands, ledger writes and what is said to the user in one chronological list.

## When
The user runs the phase. When asked which option, they reply `3`.

## Then
- The suite is run and the three options are presented; the user's `3` is followed: the agent reports `Keeping branch feat/login-lockout. Worktree preserved at /repo/.worktrees/lockout.`
- No Tracker operation is called: no `record` (so no `shipped`), no `pull`. No Rovo call of any kind is made
- No ledger line (no `Shipped:` line) and no `## Tracker queue` entry is written
- The agent tells the user nothing was shipped, so no link was commented on any Story
- No push, merge or PR is made, and the worktree and branch are left in place
