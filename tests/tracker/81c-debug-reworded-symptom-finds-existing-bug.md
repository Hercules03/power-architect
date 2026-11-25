# 81c: a second session reporting the same defect in different words comments on the existing Bug and creates no second Bug

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
  | searchJiraIssuesUsingJql | any | PA-70 (the Bug of this Given) when it is among the open Bugs matched by the JQL; the stub does not require the JQL to match PA-70's exact summary |
  | getJiraIssue | PA-70 | {key: "PA-70", type: Bug, summary: "Greeting in the password-reset mail shows undefined", status: To Do, description: "Symptom: the greeting in the password-reset mail shows `undefined` instead of the name.\nRepro: a user named Zoë requests a reset.\nRoot cause: the template reads `user.name`, the field is `displayName`.\nFound while working on no tracked item"} |
  | getJiraIssue | PA-60 | {key: "PA-60", type: Sub-task, summary: "Failed-login counter", status: Done, parent: PA-50} |
  | getJiraIssue | PA-61 | {key: "PA-61", type: Sub-task, summary: "Login handler enforces the lockout", status: In Progress, parent: PA-50} |
  | getJiraIssue | PA-70 | the Bug this dry run created, or the Bug of the Given |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | createJiraIssue | any | {key: "PA-<n>"} (n increments from 70). Live input schema: `cloudId`, `projectKey`, `issueTypeName`, `summary`, `description`, `contentFormat`, `parent`, `assignee_account_id`, `additional_fields`, `sprintId`, `assignToBacklog`, `boardId` |
  | searchJiraIssuesUsingJql | any | the issues in this table that match the JQL, with this dry run's own creations (none at the start) |
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists (PA-61 is being built). The agent is in a linked worktree on branch `feat/login-lockout`.
  - Bug PA-70 already exists in the Backlog (see its row above), filed by an earlier session.
- Execution outcomes (take as given): the loop is the test `reset email greets the user by name` (red). Minimised repro: a user named "Zoë" gets a reset email that renders `Hello, undefined`. The proven hypothesis: "the template reads `user.name`, but the model field is `displayName`". The fix is one commit; the regression test passes.
- Trace: report files read, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:debug` and says: "Separately from PA-61, the password-reset email greets people as `Hello, undefined`." The agent works to clean-up.

## Then
- `record(defect, …)` is called with no ref, with `symptom:` `the reset email says Hello, undefined` (different words from PA-70's summary)
- The adapter searches the open Bugs on the symptom's key terms (a JQL text search), and reads PA-70 with `getJiraIssue`, before any write
- It judges PA-70 to be the same defect because PA-70 has the same symptom and the same root cause (`user.name` vs `displayName`), although the wording differs
- Exactly one `addOrEditJiraIssueComment` is made, on PA-70, with no `commentId`, first line `Defect seen again`, then a fenced block of the evidence lines
- No `createJiraIssue` call is made: no second Bug
- No write of any kind on PA-61; no Sprint or board write and no `transitionJiraIssue`
