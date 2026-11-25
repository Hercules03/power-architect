# 82c: a `/review` of a branch with no tracked item makes no Tracker call and tells the user

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
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | createJiraIssue | any | {key: "PA-<n>"} (n increments from 70) |
  | searchJiraIssuesUsingJql | any | the issues in this table that match the JQL, with this dry run's own creations (none at the start) |
- Ledger / local files:
  - Today is 2026-11-25. There is no `.power-architect/` directory. Branch `fix/typo-in-readme` has one commit `c0ffee1 docs: fix typo`; no commit message names a work item.
- Execution outcomes (take as given): the user names no spec, so the Spec axis is skipped. The Standards axis reports one finding F1, which the agent accepts and fixes.
- Trace: report files read, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:review` and the agent fixes F1.

## Then
- No `record` call and no MCP call is made, and in particular no `createJiraIssue` and no `addOrEditJiraIssueComment`
- The agent tells the user that no tracked item could be identified, so F1 was not recorded in the Tracker
- The agent recommends `/power-architect:verify`
