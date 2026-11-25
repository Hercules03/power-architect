# 82b: a `/review` covering two items records one comment per item, each holding only that item's findings

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
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, `Task PA-60: complete (commits a1b2c3d..a1b2c3d, tests: … → 2 passed)` and `Task PA-61: complete (commits b2c3d4e..b2c3d4e, tests: … → 3 passed)`.
  - Branch `feat/login-lockout` has the two commits `a1b2c3d feat: count failed logins` (touches `src/auth/attempts.ts`) and `b2c3d4e feat: lock out repeated failed logins` (touches `src/auth/login.ts`). The merge-base with main is the commit before `a1b2c3d`.
- Execution outcomes (take as given): the user names no fixed point, so the review covers both commits. Accepted and fixed findings: F1 "`attempts.ts`: `n` is a Mysterious Name" (in `a1b2c3d`'s file) and F2 "`login.ts` repeats the lock check (Duplicated Code)" and F3 "`login.ts`: `isLocked` called twice" (both in `b2c3d4e`'s file).
- Trace: report files read, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:review` and the agent fixes F1, F2 and F3.

## Then
- The agent calls `record(PA-60, defect, …)` once and `record(PA-61, defect, …)` once, each with its item's ref
- PA-60 gets one comment (first line `Defect fixed in this item`) whose fenced block holds only F1; PA-61 gets one comment whose fenced block holds only F2 and F3
- Exactly two `addOrEditJiraIssueComment` calls in the dry run, and no `createJiraIssue` call
- No `transitionJiraIssue` call
