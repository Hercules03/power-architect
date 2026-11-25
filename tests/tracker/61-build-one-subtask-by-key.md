# 61: `/build <Sub-task key>` builds only that Sub-task, even when the Sprint holds other unfinished ones

**Phase:** /power-architect:build PA-61

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
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: [{key: "PA-50", type: "Story", status: "In Progress"}, {key: "PA-60", type: "Sub-task", status: "Done"}, {key: "PA-61", type: "Sub-task", status: "To Do"}, {key: "PA-62", type: "Sub-task", status: "To Do"}]} |
  | getConfluenceContent | page 6001 | {id: "6001", title: "Login lockout", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): the shared context, Plan section and key table below} |
  | getJiraIssue | PA-50 | {key: "PA-50", type: Story, summary: "Lock out repeated failed logins", status: In Progress, parent: PA-5, description: "As a user, I want my account locked for 15 minutes after five failed logins in 10 minutes, so that my password can't be guessed.", then `## Acceptance Criteria` with `- [ ] The sixth login attempt within 10 minutes after five failures returns 423.`, then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`; no links} |
  | getJiraIssue | PA-60, PA-61, PA-62 | that item's row of the Items table below, with its current status (after a transition by this dry run, the new status) |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to`. Live input schema: `cloudId`, `issueIdOrKey`, `transitionId`, `transitionName`, `fields`, `sprintId`, `assignToBacklog`, `boardId` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |

  Items (each Sub-task's parent is PA-50; each description ends with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`):

  | Key | Kind | summary | status | links | description (before the Spec Page line) |
  |---|---|---|---|---|---|
  | PA-60 | Sub-task | Failed-login counter | Done | PA-60 blocks PA-61 | Task 1's files and steps (test file `tests/auth/attempts.test.ts`) |
  | PA-61 | Sub-task | Login handler enforces the lockout | To Do | PA-61 is blocked by PA-60; PA-61 blocks PA-62 | Files: Modify `src/auth/login.ts:40-62`; Test `tests/auth/login.test.ts`. Steps as `- [ ]` lines: write the failing test `returns 423 after five failures`; run `npx vitest run tests/auth/login.test.ts` (Expected: FAIL); implement; run it again (Expected: PASS); commit |
  | PA-62 | Sub-task | Unlock after 15 minutes | To Do | PA-62 is blocked by PA-61 | Task 3's files and steps (test file `tests/auth/unlock.test.ts`) |

  Spec Page body on page 6001: the shared context of the spec "Login lockout" (with a Scope Tier section reading `Small`), then a `## Plan` section (Goal, Architecture, Tech Stack, `### Global Constraints` with "Five failures within 10 minutes lock the account.", "The lock lasts 15 minutes.", "A locked login returns 423.", and `### Review Focus` with "Failures for different accounts never share a counter (test `counts failures per account`, Task 1)."), then the key table: `spec | Spec Page | …/pages/6001`, `1 | Story | PA-50`, `1 | Sub-task | PA-60`, `2 | Sub-task | PA-61`, `3 | Sub-task | PA-62`.
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists. Its first line is `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, then the `## Work Refs` table (5 rows), then `Task PA-60: complete (commits a1b2c3d..a1b2c3d, review clean, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)`.
  - The agent is already in a linked worktree on branch `feat/login-lockout`. The baseline suite passes.
- Execution outcomes (take as given; dispatching a subagent is described, not performed): the implementer for PA-61 reports DONE with one commit `b2c3d4e feat: lock out repeated failed logins`; its test run `npx vitest run tests/auth/login.test.ts` → `3 passed`. The task review and the final review are clean. `git log --oneline` over the task's range shows that one commit.
- Trace: report dispatches, ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build PA-61`. If asked which execution method to use, they reply "subagent-driven".

## Then
- The agent calls `pull(PA-61, subtask)`, never `pull(sprint, subtask)`. It returns only PA-61 (ready: its blocker PA-60 is Done), with tier Small and the Spec Page `https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`
- Exactly one implementer is dispatched, for PA-61. No brief is written for PA-60 or PA-62
- In order: `record(PA-61, started)` (a `transitionJiraIssue` on PA-61 with transition `21`) → implementer dispatch → task review → ledger line `Task PA-61: complete (…)` naming `b2c3d4e` → `record(PA-61, done, …)` (one `addOrEditJiraIssueComment` on PA-61 starting with the line `Done`, holding `b2c3d4e feat: lock out repeated failed logins` and `npx vitest run tests/auth/login.test.ts` → `3 passed`, and one `transitionJiraIssue` on PA-61 with transition `41`)
- No `record` call and no MCP write on PA-60, PA-62 or PA-50. The ledger keeps its PA-60 line unchanged and gains only the PA-61 line
- No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`
- The agent tells the user PA-61 was built and moved to Done
