# 70: When Jira goes down mid-build, the remaining started and done events are queued in the ledger and the build completes

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
  | * | any, once PA-60's implementer has reported DONE (every call from then on, for the rest of this run) | UNREACHABLE |
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: [{key: "PA-50", type: "Story", status: "In Progress"}, {key: "PA-60", type: "Sub-task", status: "To Do"}, {key: "PA-61", type: "Sub-task", status: "To Do"}]} (each status is the issue's current status) |
  | getConfluenceContent | page 6001 | {id: "6001", title: "Login lockout", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): shared context (Scope Tier `Small`), a `## Plan` section, then the key table `spec`, `1 | Story | PA-50`, `1 | Sub-task | PA-60`, `2 | Sub-task | PA-61`} |
  | getJiraIssue | PA-50 | {key: "PA-50", type: Story, status: In Progress, parent: PA-5, description: story sentence, `## Acceptance Criteria` with `- [ ] The sixth login attempt within 10 minutes after five failures returns 423.`, `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`} |
  | getJiraIssue | PA-60, PA-61 | that item's row of the Items table, with its current status |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} (n increments from 1) |

  Items (each Sub-task's parent is PA-50; each description ends with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`): PA-60 "Failed-login counter" (PA-60 blocks PA-61); PA-61 "Login handler enforces the lockout" (blocked by PA-60).
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table (Spec Page, Story PA-50, Sub-tasks PA-60, PA-61), `Pre-flight: no shared interfaces`, no `Task` line and no `## Tracker queue` section.
  - The agent is already in a linked worktree on branch `feat/login-lockout`. The baseline suite passes.
- Execution outcomes (take as given; dispatching a subagent is described, not performed): every implementer reports DONE and every review is clean. PA-60: commit `a1b2c3d feat: count failed logins`, `npx vitest run tests/auth/attempts.test.ts` → `2 passed`. PA-61: commit `b2c3d4e feat: lock out repeated failed logins`, `npx vitest run tests/auth/login.test.ts` → `3 passed`.
- Trace: report dispatches, ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build` with no argument. If asked which execution method to use, they reply "subagent-driven".

## Then
- `pull(sprint, subtask)` returns PA-60 then PA-61; `record(PA-60, started)` is sent (`getJiraIssue`, then `transitionJiraIssue` with transition `21`) before PA-60's implementer is dispatched
- After PA-60's implementer reports DONE and review is clean, the ledger line `Task PA-60: complete (commits a1b2c3d..a1b2c3d, …)` is written, then `record(PA-60, done, …)` is attempted: its first Rovo call returns UNREACHABLE, so no comment and no transition is made and the result is `queued`
- The ledger gains a `## Tracker queue` section holding `- [ ] q1 | done | PA-60 | a1b2c3d feat: count failed logins\ntests: npx vitest run tests/auth/attempts.test.ts → 2 passed` (evidence verbatim on one line, newlines as `\n`)
- The agent does not stop: PA-61 is built. `record(PA-61, started)` is tried, returns UNREACHABLE and is queued as `- [ ] q2 | started | PA-61 | …`; PA-61's implementer is still dispatched and its ledger line `Task PA-61: complete (…)` is written
- `record(PA-61, done, …)` is queued as `- [ ] q3 | done | PA-61 | b2c3d4e feat: lock out repeated failed logins\ntests: npx vitest run tests/auth/login.test.ts → 3 passed`. The ids are q1, q2, q3 in order
- The agent finishes the build, then tells the user PA-60's done, PA-61's started and PA-61's done are queued, not recorded in Jira, and that the next run replays them
- No further Rovo call is made after the first UNREACHABLE: never retried in a loop, and nothing is written to Jira after it
- Never stops the phase because of `record`, and never reports PA-60 or PA-61 as recorded in Jira
- No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`.
