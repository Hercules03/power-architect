# 81e: a defect found in the code of a finished (Done) Sub-task files a Backlog Bug, not a comment on that Sub-task

(Red first: against the old text, any item with a ledger `Task` line counted as "currently being built", so this defect became a comment on PA-60.)

**Phase:** /power-architect:debug

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
  | createJiraIssue | any | {key: "PA-<n>"} (n increments from 70). Live input schema: `cloudId`, `projectKey`, `issueTypeName`, `summary`, `description`, `contentFormat`, `parent`, `assignee_account_id`, `additional_fields`, `sprintId`, `assignToBacklog`, `boardId` |
  | searchJiraIssuesUsingJql | any | the issues in this table that match the JQL, with this dry run's own creations (none at the start) |
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table, and `Task PA-60: complete (commits a1b2c3d..a1b2c3d, tests: … → 2 passed)`. PA-60 is Done in Jira. Nothing is being built this session: no `record(started)` happened, the user names no build target.
- Execution outcomes (take as given): the defect is in `src/auth/attempts.ts`, code PA-60 added. Loop, minimised repro and root cause are proven; the fix is one commit with a regression test.
- Trace: report files read, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:debug` and reports that failed logins for an account with a trailing space in its name are counted separately. The agent works to clean-up.

## Then
- `record(defect, …)` is called with no ref: PA-60 has a `Task` completion line but is finished, so it is not the current item
- The adapter searches open Bugs, finds none, and makes exactly one `createJiraIssue` of type `Bug` in project `PA` with no parent and no Sprint, board or backlog field
- No `addOrEditJiraIssueComment` on PA-60 and no write of any kind on PA-60
