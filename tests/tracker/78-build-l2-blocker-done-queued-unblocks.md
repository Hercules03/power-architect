# 78: In L2, a merged blocker with a ledger line still unblocks its dependent although its `done` is not yet sent, and the build completes with the queued states reported

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
  | * | any, once PA-60's merger has merged PA-60 (every call from then on, for the rest of this run) | UNREACHABLE |
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: [{key: "PA-50", type: "Story", status: "In Progress"}, {key: "PA-60", type: "Sub-task", status: "To Do"}, {key: "PA-61", type: "Sub-task", status: "To Do"}]} (each status is the issue's current status) |
  | getConfluenceContent | page 6001 | {id: "6001", title: "Login lockout", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): shared context (a Scope Tier section reading `Large`), a `## Plan` section with the table `\| ticket \| title \| Blocked by \|` (01 None; 02 01), then the key table `spec`, `1 | Story | PA-50`, `01 | Sub-task | PA-60`, `02 | Sub-task | PA-61`} |
  | getJiraIssue | PA-50 | {key: "PA-50", type: Story, status: In Progress, parent: PA-5, description: story sentence, `## Acceptance Criteria` with `- [ ] The sixth login attempt within 10 minutes after five failures returns 423.`, `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`} |
  | getJiraIssue | PA-60, PA-61 | that item's row of the Items table, with its current status |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} (n increments from 1) |

  Items (each Sub-task's parent is PA-50; each description ends with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`): PA-60 "Failed-login counter" (PA-60 blocks PA-61); PA-61 "Login handler enforces the lockout" (blocked by PA-60).
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table (Spec Page, Story PA-50, Sub-tasks PA-60, PA-61), no `Task` line and no `## Tracker queue` section.
  - The agent is already in a linked worktree on branch `feat/login-lockout`. The baseline suite passes.
- Execution outcomes (take as given; dispatching a subagent is described, not performed): every implementer reports DONE, every merger merges cleanly and the final review is clean. PA-60: commit `a1b2c3d feat: count failed logins`, `npx vitest run tests/auth/attempts.test.ts` → `2 passed`. PA-61: commit `b2c3d4e feat: lock out repeated failed logins`, `npx vitest run tests/auth/login.test.ts` → `3 passed`.
- Trace: report dispatches, merges, ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build` with no argument.

## Then
- The agent follows L2. The first frontier is PA-60 alone; `record(PA-60, started)` is sent before its dispatch
- After PA-60's merge, the ledger line `Task PA-60: complete (…)` is written and no `record(PA-60, done, …)` is called yet (PA-60 stays In Progress)
- PA-61 joins the frontier although PA-60 is still In Progress and has no `done`: PA-60 is merged and has its ledger line, so PA-61 is dispatched, not held back
- `record(PA-61, started)` is queued as `- [ ] q1 | started | PA-61 | ` because Jira is unreachable (its first Rovo call fails), not because of any entry of PA-61's own; PA-61's implementer is still dispatched
- After PA-61's merge its ledger line is written. After the final review and its fix pass, the ledger line `Final review: passed (spec https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001)` is written, then `record(PA-60, done, …)` is queued as `- [ ] q2 | done | PA-60 | a1b2c3d feat: count failed logins\ntests: npx vitest run tests/auth/attempts.test.ts → 2 passed` and `record(PA-61, done, …)` as `- [ ] q3 | done | PA-61 | …` (behind its own q1)
- The end report lists the queued states: PA-61's started, PA-60's done and PA-61's done are queued, not recorded in Jira
- No further Rovo call is made after the first UNREACHABLE: no retry within one event, and nothing is written to the Tracker after it
- No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`.
