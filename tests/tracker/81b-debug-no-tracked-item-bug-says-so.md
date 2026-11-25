# 81b: `/debug` with no tracked item at all creates a Bug whose last line says `Found while working on no tracked item`

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
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | createJiraIssue | any | {key: "PA-<n>"} (n increments from 70) |
  | searchJiraIssuesUsingJql | any | the issues in this table that match the JQL, with this dry run's own creations (none at the start) |
- Ledger / local files:
  - Today is 2026-11-25. There is no `.power-architect/` directory. The agent is on branch `main`-derived `fix/reset-email`.
- Execution outcomes (take as given): loop test `reset email greets the user by name` (red); repro: a user named "Zoë" gets `Hello, undefined`; proven hypothesis: the template reads `user.name` but the field is `displayName`; fixed and the regression test passes.
- Trace: report files read, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:debug` and reports that the password-reset email says `Hello, undefined`. They name no work item. The agent works to clean-up.

## Then
- At clean-up the agent calls `record(defect, …)` with no ref
- The adapter searches for an open Bug with that summary (none), then makes one `createJiraIssue` of type `Bug` in project PA whose `description` contains the symptom, repro, root cause and the line `Found while working on no tracked item`
- No Sprint, board, backlog, priority, assignee or estimate field is passed; no comment or transition is made
