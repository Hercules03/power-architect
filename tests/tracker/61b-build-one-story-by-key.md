# 61b: `/build <Story key>` builds every unfinished Sub-task of that Story in "blocks" order, and nothing else

**Phase:** /power-architect:build PA-50

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
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, state: "active"}, issues: [{key: "PA-50", type: "Story"}, {key: "PA-60"}, {key: "PA-61"}, {key: "PA-62"}, {key: "PA-90", type: "Sub-task", status: "To Do"}]} |
  | searchJiraIssuesUsingJql | a query for the children of PA-50 (such as `parent = PA-50`) | [{key: "PA-62", type: "Sub-task", status: "To Do"}, {key: "PA-61", type: "Sub-task", status: "To Do"}, {key: "PA-60", type: "Sub-task", status: "Done"}] |
  | getConfluenceContent | page 6001 | {id: "6001", title: "Login lockout", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): the shared context, Plan section and key table below} |
  | getJiraIssue | PA-50 | {key: "PA-50", type: Story, summary: "Lock out repeated failed logins", status: In Progress, parent: PA-5, description: the user-story sentence, then `## Acceptance Criteria` with `- [ ] The sixth login attempt within 10 minutes after five failures returns 423.`, then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`} |
  | getJiraIssue | PA-60, PA-61, PA-62 | that item's row of the Items table below, with its current status |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to`. Live input schema: `cloudId`, `issueIdOrKey`, `transitionId`, `transitionName`, `fields`, `sprintId`, `assignToBacklog`, `boardId` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |

  Items (each a Sub-task under PA-50 whose description ends with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`):

  | Key | summary | status | links |
  |---|---|---|---|
  | PA-60 | Failed-login counter | Done | PA-60 blocks PA-61 |
  | PA-61 | Login handler enforces the lockout | To Do | PA-61 is blocked by PA-60; PA-61 blocks PA-62 |
  | PA-62 | Unlock after 15 minutes | To Do | PA-62 is blocked by PA-61 |

  PA-90 is a Sub-task of another spec; it is in the Sprint but not under PA-50.

  Spec Page body on page 6001: the shared context of "Login lockout" (Scope Tier `Small`), a `## Plan` section with Global Constraints and Review Focus, then the key table: `spec`, `1 | Story | PA-50`, `1 | Sub-task | PA-60`, `2 | Sub-task | PA-61`, `3 | Sub-task | PA-62`.
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table, and `Task PA-60: complete (commits a1b2c3d..a1b2c3d, review clean, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)`.
  - The agent is already in a linked worktree; the baseline suite passes.
- Execution outcomes (take as given; dispatching a subagent is described, not performed): every implementer reports DONE and every review is clean. PA-61: commit `b2c3d4e feat: lock out repeated failed logins`, `npx vitest run tests/auth/login.test.ts` → `3 passed`. PA-62: commit `c3d4e5f feat: unlock after 15 minutes`, `npx vitest run tests/auth/unlock.test.ts` → `1 passed`.
- Trace: report dispatches, ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build PA-50`. If asked which execution method to use, they reply "subagent-driven".

## Then
- The agent calls `pull(PA-50, subtask)`, not `pull(sprint, subtask)`. It returns PA-61 then PA-62 (PA-60 is Done and is not returned)
- PA-61 is built completely (`record(PA-61, started)` → implementer → review → ledger line → `record(PA-61, done, …)`) before `record(PA-62, started)`
- Exactly two implementers are dispatched, for PA-61 and PA-62. Nothing is done for PA-60 or PA-90: no brief, no `record` call, no MCP write
- No MCP write on PA-50 (no transition, comment or edit)
- No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`
