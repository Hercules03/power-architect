# 67: An inline (S2) build records started before each task's steps and done for both tasks only after the spec's final review has passed

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
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: [{key: "PA-50", type: "Story", status: "To Do"}, {key: "PA-61", type: "Sub-task", status: "To Do"}, {key: "PA-60", type: "Sub-task", status: "To Do"}]} |
  | getConfluenceContent | page 6001 | {id: "6001", title: "Login lockout", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): the shared context of "Login lockout" (Scope Tier `Small`), a `## Plan` section (Goal, Architecture, Tech Stack, `### Global Constraints` with three lines, `### Review Focus` with "Failures for different accounts never share a counter (test `counts failures per account`, Task 1)."), then the key table: `spec`, `1 \| Story \| PA-50`, `1 \| Sub-task \| PA-60`, `2 \| Sub-task \| PA-61`} |
  | getJiraIssue | PA-50 | {key: "PA-50", type: Story, summary: "Lock out repeated failed logins", status: To Do, description: the user-story sentence, `## Acceptance Criteria` with `- [ ] The sixth login attempt within 10 minutes after five failures returns 423.`, the Spec Page line} |
  | getJiraIssue | PA-60 | {key: "PA-60", type: Sub-task, summary: "Failed-login counter", status: To Do (after a transition by this dry run, the new status), parent: PA-50, links: PA-60 blocks PA-61, description: Files, Interfaces and five `- [ ]` steps, the test step running `npx vitest run tests/auth/attempts.test.ts` with `Expected: PASS`, then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`} |
  | getJiraIssue | PA-61 | {key: "PA-61", type: Sub-task, summary: "Login handler enforces the lockout", status: To Do (after a transition by this dry run, the new status), parent: PA-50, links: PA-61 is blocked by PA-60, description: Files, Interfaces and five `- [ ]` steps, the test step running `npx vitest run tests/auth/login.test.ts` with `Expected: PASS`, then the Spec Page line} |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to`. Live input schema: `cloudId`, `issueIdOrKey`, `transitionId`, `transitionName`, `fields`, `sprintId`, `assignToBacklog`, `boardId` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, then the `## Work Refs` table. No `Task` line.
  - The agent is already in a linked worktree on branch `feat/login-lockout`. The baseline suite passes.
- Execution outcomes (take as given): every command's output matches its `Expected:` line. PA-60's steps end in commit `a1b2c3d feat: count failed logins`, with `npx vitest run tests/auth/attempts.test.ts` → `2 passed`. PA-61's steps end in commit `b2c3d4e feat: lock out repeated failed logins`, with `npx vitest run tests/auth/login.test.ts` → `3 passed`. The final review finds nothing Critical or Important.
- Trace: report steps worked, ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build` with no argument. If asked which execution method to use, they reply "inline".

## Then
- `pull(sprint, subtask)` returns PA-60 then PA-61
- The agent follows S2 (inline): no implementer or task reviewer subagent is dispatched
- For PA-60 and then PA-61: `record(<key>, started)` (transition `21` on that key) comes before the first step of that task is worked → its steps are worked and committed → the ledger line `Task <key>: complete (commits …, tests: <cmd> → <result>)`. No `record(<key>, done, …)` and no transition `41` comes before the final review. PA-61's `record(started)` comes after PA-60's ledger line, though PA-60 is still In Progress
- The final reviewer is given the Review Focus line from the Spec Page's Plan section verbatim
- Only after the final review (clean) and its fix pass (none needed) is the ledger line `Final review: passed (spec https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001)` written, then `record(PA-60, done, …)` and `record(PA-61, done, …)` in that order, each with one `addOrEditJiraIssueComment` (first line `Done`; the commit and the test command with its result in a fenced code block) and one `transitionJiraIssue` with transition `41`
- No MCP write on PA-50. No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`
