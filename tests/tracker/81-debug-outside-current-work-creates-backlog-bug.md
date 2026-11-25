# 81: `/debug` on a defect outside current work creates one Bug in the Backlog, never in a Sprint; the same symptom again comments on that Bug

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
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table, and `Task PA-60: complete (commits a1b2c3d..a1b2c3d, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)`. It has no `Task PA-61` line: PA-61 is being built.
  - The agent is in a linked worktree on branch `feat/login-lockout`.
- Execution outcomes (take as given): the loop is the test `reset email greets the user by name` (red). Minimised repro: a reset email for a user named "Zoë" renders `Hello, undefined`. The proven hypothesis: "the template reads `user.name`, but the model field is `displayName`". The fix is one commit; the regression test passes.
- Trace: report files read, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:debug` and says: "I am building PA-61, but separately I noticed the password-reset email says `Hello, undefined`. That has nothing to do with PA-61." The agent works to clean-up. Later the user runs `/power-architect:debug` again in the same repo and reports the same symptom (the reset email says `Hello, undefined`); the agent reaches clean-up again with the same root cause.

## Then
- First run, at clean-up: `record(defect, …)` is called with no ref (the defect is outside PA-61's work)
- The adapter first calls `searchJiraIssuesUsingJql` for an open Bug in project PA on the symptom's key terms; it finds none
- Then exactly one `createJiraIssue`: project `PA`, issue type `Bug`, `summary` the plain one-line symptom with no `symptom:` label (the reset email says `Hello, undefined`), and a `description` holding the symptom, the minimised repro (a user named "Zoë"), the proven root cause (the template reads `user.name`, the field is `displayName`) and the line `Found while working on PA-61`
- The `createJiraIssue` call passes no `parent`, no `priority`, no `assignee`, no estimate and no Sprint, board or backlog field (no `assignToSprint`, `sprintId`, `boardId`, `assignToBacklog`)
- No comment, transition or write of any kind on PA-61
- Second run: the search finds the Bug created by the first run (PA-70), no second `createJiraIssue` is made (the dry run ends with exactly one), and one `addOrEditJiraIssueComment` is made on PA-70 with no `commentId`
- No `manageJiraSprint` or `createJiraBoard` call and no `transitionJiraIssue` anywhere
