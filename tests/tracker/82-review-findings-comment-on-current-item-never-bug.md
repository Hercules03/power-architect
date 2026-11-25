# 82: `/review` of one item's work records one comment on that item listing only the accepted, fixed findings, and never a Bug

**Phase:** /power-architect:review

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
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name. Rows are matched top to bottom. The stub keeps state within this dry run: a read returns what this dry run's own earlier writes left behind.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getJiraIssue | PA-60 | {key: "PA-60", type: Sub-task, summary: "Failed-login counter", status: Done, parent: PA-50} |
  | getJiraIssue | PA-61 | {key: "PA-61", type: Sub-task, summary: "Login handler enforces the lockout", status: In Progress, parent: PA-50} |
  | getJiraIssue | PA-70 | the Bug this dry run created, or the Bug of the Given |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | createJiraIssue | any | {key: "PA-<n>"} (n increments from 70) |
  | searchJiraIssuesUsingJql | any | the issues in this table that match the JQL, with this dry run's own creations (none at the start) |
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, `Task PA-61: complete (commits b2c3d4e..b2c3d4e, tests: … → 3 passed)`.
  - Branch `feat/login-lockout` has the commits `a1b2c3d` (before the fixed point) and `b2c3d4e feat: lock out repeated failed logins` (touches `src/auth/login.ts`). The user names the fixed point `a1b2c3d`, so the review covers only `b2c3d4e`.
- Execution outcomes (take as given): the Standards axis reports F1 "`login.ts` repeats the lock check in two branches (Duplicated Code)" and F2 "`isLocked` result variable `x` is a Mysterious Name" and F3 "extract a `LockPolicy` class (Speculative Generality)". The agent accepts F1 and F2, fixes them test-green, and pushes back on F3.
- Trace: report files read, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:review a1b2c3d` and the agent acts on the review.

## Then
- After F1 and F2 are fixed, the agent calls `record(PA-61, defect, …)` exactly once, with the ref `PA-61` (from the ledger's `Task PA-61` line, whose commit is in the reviewed range)
- It makes one `addOrEditJiraIssueComment` on PA-61, first line `Defect fixed in this item`, then a fenced block with exactly two lines: F1 and F2. F3 (pushed back) appears nowhere in it
- No `createJiraIssue` call is made: no Bug, ever
- No call touches PA-60 (its commit is outside the reviewed range), and no `transitionJiraIssue` is made
- The agent then recommends `/power-architect:verify`
