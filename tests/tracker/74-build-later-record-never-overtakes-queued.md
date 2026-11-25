# 74: A later `record` for an item with unsent queue entries is queued behind them, even after Jira is reachable again

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
- Tracker state: stubbed Rovo table (a tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name; rows match top to bottom; the stub keeps state within this dry run and across runs of this scenario).

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | transitionJiraIssue | the first call of this run (on PA-61, transition `21`) | UNREACHABLE (the stub answers normally from the second call on) |
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: [{key: "PA-50", type: "Story", status: "In Progress"}, {key: "PA-61", type: "Sub-task", status: "To Do"}, {key: "PA-62", type: "Sub-task", status: "To Do"}]} (each status is the issue's current status) |
  | getConfluenceContent | page 6001 | {id: "6001", title: "Login lockout", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): shared context (Scope Tier `Small`), a `## Plan` section, then the key table `spec`, `1 | Story | PA-50`, `1 | Sub-task | PA-60`, `2 | Sub-task | PA-61`, `3 | Sub-task | PA-62`} |
  | getJiraIssue | PA-50 | {key: "PA-50", type: Story, status: In Progress, parent: PA-5, description: story sentence, `## Acceptance Criteria` with `- [ ] The sixth login attempt within 10 minutes after five failures returns 423.`, `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`} |
  | getJiraIssue | PA-60, PA-61, PA-62 | that item's row of the Items table, with its current status |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} (n increments from 1) |

  Items (each Sub-task's parent is PA-50; each description ends with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`): PA-61 "Login handler enforces the lockout" and PA-62 "Unlock after 15 minutes"; neither blocks the other. Both are in the key table (`2 | Sub-task | PA-61`, `3 | Sub-task | PA-62`)
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table (Spec Page, Story PA-50, Sub-tasks PA-61, PA-62), `Pre-flight: no shared interfaces`, no `Task` line, no queue section. The agent is in a linked worktree; the baseline suite passes.
- Execution outcomes (as given): every implementer reports DONE and every review is clean. PA-61: commit `b2c3d4e feat: lock out repeated failed logins`, `npx vitest run tests/auth/login.test.ts` → `3 passed`. PA-62: commit `c3d4e5f feat: unlock after 15 minutes`, `npx vitest run tests/auth/unlock.test.ts` → `1 passed`.
- Trace: report dispatches, ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build` with no argument. If asked which execution method to use, they reply "subagent-driven".

## Then
- `record(PA-61, started)` reads PA-61 (`getJiraIssue`), then its `transitionJiraIssue` returns UNREACHABLE: the result is `queued` and the ledger holds `- [ ] q1 | started | PA-61 | `. The build carries on and PA-61 is built
- After PA-61's ledger line, `record(PA-61, done, …)` is queued as `- [ ] q2 | done | PA-61 | b2c3d4e feat: lock out repeated failed logins\ntests: npx vitest run tests/auth/login.test.ts → 3 passed` with no Rovo call at all for it (no `getJiraIssue`, no comment, no transition), although the stub would now answer: it never overtakes q1
- PA-62 has no unsent entry, so its events go straight to Jira: `record(PA-62, started)` transitions it with transition `21`, and `record(PA-62, done, …)` adds one `Done` comment and one transition `41`. Neither is queued
- The final ledger queue holds exactly q1 and q2, both `- [ ]`, both for PA-61 and in that order; the user is told PA-61's started and done are queued, and PA-62's are recorded
- No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`.
