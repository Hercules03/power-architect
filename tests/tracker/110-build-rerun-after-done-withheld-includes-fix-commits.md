# 110: A re-run after Done was withheld reviews the union of the Task and Fix ranges plus the user's later commits, then writes the marker and fires Done with the Fix commits in the evidence

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
  - Today is 2026-11-26, a new session. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, then the `## Work Refs` table, `Task PA-60: complete (commits a1b2c3d..a1b2c3d, S2, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)`, `Task PA-61: complete (commits b2c3d4e..b2c3d4e, S2, tests: npx vitest run tests/auth/login.test.ts → 3 passed)` and `Fix (spec https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001): commits c4d5e6f..c4d5e6f`. The previous run's final review left an Important finding open after its one fix pass, so there is no `Final review: passed` line and Done was withheld. No `## Tracker queue` section.
  - The agent is in a linked worktree on branch `feat/login-lockout`. The branch history is `a1b2c3d`, `b2c3d4e`, `c4d5e6f fix: count failures per account` (the earlier fix pass), then `d5e6f7a fix: reset the counter when the lockout expires`, which the user committed after being told the finding was open. No ledger line names `d5e6f7a`. The baseline suite passes.
- Execution outcomes (take as given): the final review of the union finds nothing Critical or Important.
- Trace: report steps worked, ledger writes, Tracker operations, MCP calls and the final-review diff command in one chronological list.

## When
The user runs `/power-architect:build` with no argument. If asked which execution method to use, they reply "inline".

## Then
- `pull(sprint, subtask)` returns PA-60 and PA-61 (both In Progress). Both `Task` lines carry the token `S2`, so both are deferred items with no `Final review: passed` line after them. Neither is rebuilt: no brief, no task work, no `record(started)`; no `record(done)` is called before the review
- The ledger gains the line `Fix (spec https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001): commits d5e6f7a..d5e6f7a` before the review, so the user's commit is recorded
- The final review runs once, on the diff of the UNION of the ranges `a1b2c3d^..a1b2c3d`, `b2c3d4e^..b2c3d4e`, `c4d5e6f^..c4d5e6f` and `d5e6f7a^..d5e6f7a`, with the Review Focus verbatim; the trace shows the reviewer told these four commits, and the diff is not one first-to-last span
- Nothing Critical or Important is open, so the ledger line `Final review: passed (spec https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001)` is written below the `Task` and `Fix` lines. Then `record(PA-60, done, …)` and `record(PA-61, done, …)` are called once each: each makes one `Done` comment and one transition `41`. PA-60's evidence lists `a1b2c3d feat: count failed logins`, then once `c4d5e6f fix: count failures per account` and `d5e6f7a fix: reset the counter when the lockout expires`, then `tests: npx vitest run tests/auth/attempts.test.ts → 2 passed`; PA-61's lists `b2c3d4e feat: lock out repeated failed logins`, the same two fix commits once, then its `tests:` line
- The ledger still holds exactly one `Task` line per item
- No MCP write on PA-50. No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`.
