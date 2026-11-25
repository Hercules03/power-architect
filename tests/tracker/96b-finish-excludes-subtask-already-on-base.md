# 96b: finish does not count a Sub-task whose commit is already on the base branch

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
  - PA-5 Epic "Account security" (To Do).
  - PA-50 Story "Lock out repeated failed logins" (Done, parent PA-5); PA-51 Story "Admins see lockouts" (In Progress, parent PA-5).
  - Sub-tasks: PA-60 (Done, parent PA-50); PA-62 (Done, parent PA-51).
- Ledger / local files:
  - Today is 2026-11-25. `/repo/.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table, and the lines `Task PA-60: complete (commits a1b2c3d..a1b2c3d, …)` and `Task PA-62: complete (commits c3d4e5f..c3d4e5f, …)`. No `## Tracker queue` section.
  - `/repo` is the main checkout. The agent is in a linked worktree `/repo/.worktrees/lockout` on branch `feat/login-lockout`, forked from `main`. The merge-base of the branch and `main` is `9f8e7d6`. Commit a1b2c3d (PA-60) is already on `main` (the branch was forked after it); c3d4e5f (PA-62) is only on the branch, in `9f8e7d6..feat/login-lockout`. Both are reachable from the branch's HEAD. The base branch is `main`.
- Execution outcomes (take as given): the full suite passes (`14 passed`). `git push -u origin feat/login-lockout` succeeds. Opening the PR returns `https://github.com/acme/app/pull/42`. A local merge into `main` succeeds, the tests on the merged result pass (`14 passed`), and the merge commit is `e5f6a7b8`.
- Trace: report Tracker operations, MCP calls, shell commands, ledger writes and what is said to the user in one chronological list.

## When
The user runs the phase. When asked which option, they reply `2`.

## Then
- Before the push, `git merge-base main feat/login-lockout` is run and `9f8e7d6` is kept; after the PR is opened, `record(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001, shipped, https://github.com/acme/app/pull/42, base 9f8e7d6)` is called once
- The delivered Sub-tasks are only those whose commit is in `9f8e7d6..feat/login-lockout`: PA-62. PA-60 (commit already on `main`) is not delivered, though its commit is reachable from HEAD
- The ledger gains the line `Shipped: https://github.com/acme/app/pull/42 — base 9f8e7d6 — Sub-tasks PA-62` before the first Rovo write
- Exactly one `addOrEditJiraIssueComment`, on PA-51, preceded by `listJiraIssueComments`, whose first line is `Shipped` and next line `https://github.com/acme/app/pull/42`
- No `addOrEditJiraIssueComment` or any other write on PA-50, PA-5 or any Sub-task. No `transitionJiraIssue` call at all
- No Sprint or board write, and no `commentId` is passed
