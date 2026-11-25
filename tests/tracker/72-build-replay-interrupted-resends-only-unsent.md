# 72: When replay is interrupted partway, a later run sends only the unsent entries

> The cutoff sits after q1's transition so q1 is sent and `[x]` and the failure lands on q2: "interrupted after some entries were sent" is what this scenario tests.

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
  | * | any, in run 1 after `transitionJiraIssue` on PA-60 (transition `21`) has returned once (every call from then on, for the rest of run 1); in run 2 every row answers normally | UNREACHABLE |
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
  - Today is 2026-11-26. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table (Spec Page, Story PA-50, Sub-tasks PA-60, PA-61), `Task PA-60: complete (commits a1b2c3d..a1b2c3d, review clean, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)`, `Task PA-61: complete (commits b2c3d4e..b2c3d4e, review clean, tests: npx vitest run tests/auth/login.test.ts → 3 passed)`, and
    ```md
    ## Tracker queue
    - [ ] q1 | started | PA-60 | 
    - [ ] q2 | done | PA-60 | a1b2c3d feat: count failed logins\ntests: npx vitest run tests/auth/attempts.test.ts → 2 passed
    - [ ] q3 | started | PA-61 | 
    - [ ] q4 | done | PA-61 | b2c3d4e feat: lock out repeated failed logins\ntests: npx vitest run tests/auth/login.test.ts → 3 passed
    ```
  - The agent is in a linked worktree. The baseline suite passes.

## When
The user runs `/power-architect:build` (run 1). Replay is cut off as the stub says, so the build stops. The user then runs `/power-architect:build` again (run 2), with Jira reachable; the stub state left by run 1 carries over.

## Then
- Run 1: replay applies q1 (`transitionJiraIssue` on PA-60, transition `21`) and rewrites it `- [x] q1`. q2's first call returns UNREACHABLE, so replay stops: q2, q3 and q4 stay `- [ ]` and nothing else is sent
- Run 1: because replay hit UNREACHABLE, `pull` stops: no `getJiraBoardSprintData` or `getConfluenceContent` call. The agent says Jira can't be reached, nothing was built, and to re-run once reachable. No worktree setup, no new queue entry
- Run 2: replay sends only q2, q3, q4, in that order: no second transition of PA-60 to In Progress for q1, and `q1` stays `- [x]`
- Run 2: PA-60 gets one `Done` comment and one `Done` transition; PA-61 gets one transition to In Progress, then one `Done` comment and one `Done` transition. Across both runs there is no duplicate comment and no duplicate transition
- Run 2: all four entries are `- [x]`, then `pull` reads the Sprint, finds PA-60 and PA-61 Done and nothing to build
- No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`.
