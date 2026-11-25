# 107: verify on a Story whose Sub-tasks are In Progress because the spec's final review has not passed says it is not verifiable yet and points to /build

**Phase:** /power-architect:verify

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
- Items: PA-5 Epic "Account security" (To Do). PA-50 Story "Lock out repeated failed logins" (In Progress, parent PA-5), `## Acceptance Criteria` with one line: `- [ ] The sixth login attempt within 10 minutes after five failures returns 423.` PA-60 and PA-61 Sub-tasks of PA-50, both In Progress.
- Ledger / local files:
  - Today is 2026-11-26. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, then the `## Work Refs` table, `Task PA-60: complete (commits a1b2c3d..a1b2c3d, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)` and `Task PA-61: complete (commits b2c3d4e..b2c3d4e, tests: npx vitest run tests/auth/login.test.ts → 3 passed)`. There is no `Final review: passed` line and no `## Tracker queue` section.
  - The agent is in the repo checkout on branch `feat/login-lockout`.
- Execution outcomes (take as given): `npm test` → `5 passed`; `npx tsc --noEmit` exits 0; `npm run lint` → `0 problems`. If anyone runs `npx vitest run tests/auth/login.test.ts -t "sixth attempt"` it returns `1 passed`.
- Trace: report Tracker operations, MCP calls, shell commands and ledger writes in one chronological list.

## When
The user runs the phase.

## Then
- `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001, story)` returns PA-50 flagged as having unfinished Sub-tasks PA-60 and PA-61 (both In Progress)
- The agent reports PA-50 as "not verifiable yet; run `/power-architect:build` to finish its review" (the Sub-tasks' Done is waiting for their spec's final review), and does not tell the user to rebuild PA-60 or PA-61
- PA-50's criterion is never marked passed, and its command is not run, even though it would pass
- `record` is never called: no `addOrEditJiraIssueComment`, no `transitionJiraIssue`, and PA-50 is not called Done or verified. verify does not recommend `/power-architect:finish`
- verify still runs the full suite, typecheck and lint. No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`.
