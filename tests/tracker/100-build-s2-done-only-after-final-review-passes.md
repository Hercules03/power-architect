# 100: An inline (S2) build writes the `Final review: passed` line and only then records done, for every item, with the Done template

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
- Items: PA-50 Story "Lock out repeated failed logins" (parent PA-5, Acceptance Criteria `- [ ] The sixth login attempt within 10 minutes after five failures returns 423.`); PA-60 Sub-task "Failed-login counter" (blocks PA-61); PA-61 Sub-task "Login handler enforces the lockout" (blocked by PA-60). Both Sub-tasks have status To Do.
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, then the `## Work Refs` table. No `Task` line.
  - The agent is already in a linked worktree on branch `feat/login-lockout`. The baseline suite passes.
- Execution outcomes (take as given): every command's output matches its `Expected:` line. PA-60: commit `a1b2c3d feat: count failed logins`, `npx vitest run tests/auth/attempts.test.ts` → `2 passed`. PA-61: commit `b2c3d4e feat: lock out repeated failed logins`, `npx vitest run tests/auth/login.test.ts` → `3 passed`. The final review finds nothing Critical or Important (one Minor), so its fix pass has nothing to fix.
- Trace: report steps worked, ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build` with no argument. If asked which execution method to use, they reply "inline".

## Then
- For PA-60 then PA-61: `record(<key>, started)` (transition `21`) comes before the task's first step, and the ledger line `Task <key>: complete (commits <sha>..<sha>, S2, tests: <cmd> → <result>)` is written after its commit; PA-61's started comes after PA-60's ledger line
- No `addOrEditJiraIssueComment` and no `transitionJiraIssue` with transition `41` is made on any item between the first `started` and the end of the final review: after PA-60's ledger line and after PA-61's ledger line, both are still In Progress
- The final review runs once, on the diff of the union of the ledger's `Task` ranges, with the Plan section's Review Focus verbatim. The Minor finding goes to the ledger as a deferred minor and blocks nothing
- Only after the final review and its fix pass is the ledger line `Final review: passed (spec https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001)` written, below both `Task` lines. Then `record(PA-60, done, …)` and `record(PA-61, done, …)` are called in that order, each making one `addOrEditJiraIssueComment` (first line `Done`; then a fenced block holding the commit `<sha> <subject>` and the line `tests: <cmd> → <result>`) and one `transitionJiraIssue` with transition `41`; PA-60's holds `a1b2c3d feat: count failed logins` and `tests: npx vitest run tests/auth/attempts.test.ts → 2 passed`, PA-61's holds `b2c3d4e feat: lock out repeated failed logins` and `tests: npx vitest run tests/auth/login.test.ts → 3 passed`. No comment passes a `commentId`
- Each of the two `done` evidences is taken from that item's ledger line, with no other test run in between
- The agent tells the user PA-60 and PA-61 were built and moved to Done after the final review, and recommends `/power-architect:verify`
- No MCP write on PA-50. No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`.
