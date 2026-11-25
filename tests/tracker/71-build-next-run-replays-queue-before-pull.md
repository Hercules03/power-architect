# 71: The next run replays the queue in order before pulling, and each event lands exactly once

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
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: [{key: "PA-50", type: "Story", status: "In Progress"}, {key: "PA-60", type: "Sub-task", status: "In Progress"}, {key: "PA-61", type: "Sub-task", status: "To Do"}]} (each status is the issue's current status) |
  | getConfluenceContent | page 6001 | {id: "6001", title: "Login lockout", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): shared context (Scope Tier `Small`), a `## Plan` section, then the key table `spec`, `1 | Story | PA-50`, `1 | Sub-task | PA-60`, `2 | Sub-task | PA-61`} |
  | getJiraIssue | PA-50 | {key: "PA-50", type: Story, status: In Progress, parent: PA-5, description: story sentence, `## Acceptance Criteria` with `- [ ] The sixth login attempt within 10 minutes after five failures returns 423.`, `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`} |
  | getJiraIssue | PA-60, PA-61 | that item's row of the Items table, with its current status |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} (n increments from 1) |

  PA-70 (not in the Sprint and not in the table below): `getJiraIssue` PA-70 → {key: "PA-70", type: Sub-task, status: To Do}; its transitions are those of an issue in To Do.

  Items (each Sub-task's parent is PA-50; each description ends with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`): PA-60 "Failed-login counter" (PA-60 blocks PA-61); PA-61 "Login handler enforces the lockout" (blocked by PA-60).
- Ledger / local files:
  - Today is 2026-11-26, a new session. Jira is reachable. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table (Spec Page, Story PA-50, Sub-tasks PA-60, PA-61), `Task PA-60: complete (commits a1b2c3d..a1b2c3d, review clean, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)`, `Task PA-61: complete (commits b2c3d4e..b2c3d4e, review clean, tests: npx vitest run tests/auth/login.test.ts → 3 passed)`, and
    ```md
    ## Tracker queue
    - [ ] q1 | done | PA-60 | a1b2c3d feat: count failed logins\ntests: npx vitest run tests/auth/attempts.test.ts → 2 passed
    - [ ] q2 | started | PA-61 | 
    - [ ] q3 | done | PA-61 | b2c3d4e feat: lock out repeated failed logins\ntests: npx vitest run tests/auth/login.test.ts → 3 passed
    ```
  - `.power-architect/2026-11-20-profile-page/progress.md` exists (older directory name): first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001`, and `## Tracker queue` holding `- [ ] q1 | started | PA-70 | `. PA-70 is a Sub-task in To Do whose description names that Spec Page.
  - The agent is in a linked worktree. The baseline suite passes.

## When
The user runs `/power-architect:build` with no argument.

## Then
- `pull(sprint, subtask)` first checks the connection (`atlassianUserInfo`), then replays before any read: no `getJiraBoardSprintData` or `getConfluenceContent` call comes before the last replayed entry
- Replay order is the older ledger's q1 (PA-70 started: `transitionJiraIssue` transition `21`), then this ledger's q1, q2, q3: PA-60 done, PA-61 started, PA-61 done
- PA-60 done: one `addOrEditJiraIssueComment` on PA-60 starting with the line `Done` and holding `a1b2c3d feat: count failed logins` and `tests: npx vitest run tests/auth/attempts.test.ts → 2 passed`, then one `transitionJiraIssue` on PA-60 with transition `41`. PA-61 done: the same, with PA-61's commit and test lines
- PA-61 started: one `transitionJiraIssue` with transition `21`, made before PA-61's `done` comment
- Each replayed entry is rewritten `- [x] qN …` in its ledger, and no entry is still `- [ ]`
- Each event lands exactly once: across the run, one `Done` comment and one `Done` transition per Sub-task, one transition to In Progress for PA-61 and PA-70, and no second comment on either
- After replay, the Sprint read shows PA-60 and PA-61 Done, so nothing is left to build: no `record(PA-60, done)` from the resume rule, no brief, no implementer. The agent tells the user the queued events were sent and that no work remains
- No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`.
