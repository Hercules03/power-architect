# 80: `/debug` on a defect found while building PA-61 records one comment on PA-61 and creates no Bug

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
  | createJiraIssue | any | {key: "PA-<n>"} (n increments from 70) |
  | searchJiraIssuesUsingJql | any | the issues in this table that match the JQL, with this dry run's own creations (none at the start) |
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table, and `Task PA-60: complete (commits a1b2c3d..a1b2c3d, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)`. It has no `Task PA-61` line: PA-61 is being built.
  - The agent is in a linked worktree on branch `feat/login-lockout`.
- Execution outcomes (take as given): the feedback loop is the test `locks account across IPs` (red). The minimised repro: five failed logins for one account from two IPs do not lock it. The ranked hypotheses end with the proven one, "the failure counter is keyed per IP, not per account". The fix is one commit; the regression test `locks account across IPs` passes and the suite passes.
- Trace: report files read, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:debug` and says: "While building PA-61 (`/power-architect:build PA-61`) I found that the sixth failed login from a different IP is not locked out." The agent works Phases 1 to 7 and reaches clean-up.

## Then
- At clean-up the agent calls `record(PA-61, defect, …)` once, with `PA-61` as the ref (from the user's current `/build` target, matching no `Task PA-61` line yet)
- The agent opens `references/tracker.md`, then `references/tracker-jira.md`, before that call
- `record` makes exactly one `addOrEditJiraIssueComment` on PA-61, with no `commentId`. Its first line is `Defect fixed in this item`, followed by one fenced block holding the symptom (the sixth failed login from a different IP is not locked out), the root cause (the failure counter is keyed per IP, not per account) and the regression test name `locks account across IPs`
- It first reads PA-61's comments with `listJiraIssueComments`
- No `createJiraIssue` call is made: no Bug is created
- No `transitionJiraIssue` call, no write on any issue other than that one comment on PA-61, and no Sprint, board or backlog field passed anywhere
- The hypothesis that proved correct is stated in the commit message
