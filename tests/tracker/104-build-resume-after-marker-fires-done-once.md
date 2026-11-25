# 104: After a crash after `Final review: passed` but before done, the next build fires done once per item and rebuilds and re-reviews nothing

**Phase:** /power-architect:build

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
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name. Rows are matched top to bottom. The stub keeps state within this dry run.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: the Sub-tasks, Story and Bugs of the Items list with their current statuses} |
  | getConfluenceContent | page 6001 | {id: "6001", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): the shared context (Scope Tier `Small`), a `## Plan` section (a Small plan: Goal, Architecture, Tech Stack, `### Global Constraints`, `### Review Focus` with "Failures for different accounts never share a counter (test `counts failures per account`, Task 1)."; a Large plan: the ticket-graph table), then the key table of the Items list as `<outline id> \| <kind> \| <key>`} |
  | getJiraIssue | a key in the Items list | that item's row with its current status (after a transition by this dry run, the new status), parent, links and description; a Sub-task's description ends with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001` |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
- Items: PA-50 Story "Lock out repeated failed logins" (parent PA-5, Acceptance Criteria `- [ ] The sixth login attempt within 10 minutes after five failures returns 423.`); PA-60 Sub-task "Failed-login counter" (blocks PA-61); PA-61 Sub-task "Login handler enforces the lockout" (blocked by PA-60). Both Sub-tasks have status In Progress.
- Ledger / local files:
  - Today is 2026-11-26, a new session. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, then the `## Work Refs` table, `Task PA-60: complete (commits a1b2c3d..a1b2c3d, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)` and `Task PA-61: complete (commits b2c3d4e..b2c3d4e, tests: npx vitest run tests/auth/login.test.ts → 3 passed)`, then the line `Final review: passed (spec https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001)`. No `## Tracker queue` section.
  - The agent is in a linked worktree on branch `feat/login-lockout`. The baseline suite passes.
- Trace: report steps worked, ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build` with no argument. If asked which execution method to use, they reply "inline".

## Then
- `pull(sprint, subtask)` returns PA-60 and PA-61 (both In Progress). Both `Task` lines have the `Final review: passed (spec …)` line after them
- Neither is rebuilt: no brief, no implementer dispatch, no task work, no `record(started)`. No final review is run again and no diff for one is written
- `record(PA-60, done, …)` and then `record(PA-61, done, …)` are each called exactly once, before any other work, with the evidence from their ledger lines: one `Done` comment and one transition `41` on each, PA-60's holding `a1b2c3d` and `tests: npx vitest run tests/auth/attempts.test.ts → 2 passed`
- The ledger still holds exactly one `Task` line per item and exactly one `Final review: passed` line
- No MCP write on PA-50. No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`.
