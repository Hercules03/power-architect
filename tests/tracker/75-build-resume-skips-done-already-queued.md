# 75: Resume does not fire `record(done)` again when the queue already holds an unsent `done` for that item

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
  | transitionJiraIssue | PA-60, transition `21` | {ok: false, error: "no such transition"} (every other transition answers normally) |
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: [{key: "PA-50", type: "Story", status: "In Progress"}, {key: "PA-60", type: "Sub-task", status: "To Do"}]} (each status is the issue's current status) |
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
  - Today is 2026-11-26, a new session. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table (Spec Page, Story PA-50, Sub-tasks PA-60, PA-61), `Task PA-60: complete (commits a1b2c3d..a1b2c3d, review clean, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)`, and
    ```md
    ## Tracker queue
    - [ ] q1 | started | PA-60 | 
    - [ ] q2 | done | PA-60 | a1b2c3d feat: count failed logins\ntests: npx vitest run tests/auth/attempts.test.ts → 2 passed
    ```
  - The agent is in a linked worktree. The baseline suite passes.

## When
The user runs `/power-architect:build` with no argument.

## Then
- Replay marks q1 `- [!] q1 | started | PA-60 | | failed: …` (the transition is refused: not an unreachable Tracker) and reports it to the user. q2 is for the same item, so it is not sent and stays `- [ ]`
- `pull` then reads the Sprint and returns PA-60 (To Do), because replay did not hit UNREACHABLE
- The agent sees `Task PA-60: complete` and does not rebuild PA-60. The queue already holds an unsent `done` for PA-60, so the Resume rule does **not** call `record(PA-60, done, …)`: no `addOrEditJiraIssueComment` and no transition `41` on PA-60, and no new queue entry (the ledger has no q3)
- The agent tells the user PA-60's done is held in the queue behind the failed q1
- No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`.
