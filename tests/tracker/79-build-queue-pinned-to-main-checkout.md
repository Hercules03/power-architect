# 79: A build in a linked worktree writes its queue to the main checkout's `.power-architect/`, and a later run from the main checkout replays it

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
  | * | any, once PA-60's implementer has reported DONE (every call from then on, for the rest of run 1); in run 2 every row answers normally | UNREACHABLE |
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
  - Today is 2026-11-25. The main checkout is `/repo`. `/repo/.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table (Spec Page, Story PA-50, Sub-tasks PA-60, PA-61), no `Task` line and no `## Tracker queue` section. The worktree `/repo/.worktrees/x` has no `.power-architect/` directory of its own.
  - Run 1 runs in the linked worktree `/repo/.worktrees/x` on branch `feat/login-lockout`, where `git rev-parse --git-common-dir` prints `/repo/.git`. Run 2 runs from `/repo`. The baseline suite passes.
- Execution outcomes (take as given; dispatching a subagent is described, not performed): every implementer reports DONE and every review is clean. PA-60: commit `a1b2c3d feat: count failed logins`, `npx vitest run tests/auth/attempts.test.ts` → `2 passed`. PA-61 is not built in run 1 (set aside).
- Trace: report dispatches, merges, ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build PA-60` in the worktree (run 1). Jira goes down as the stub says. The user then runs `/power-architect:build` from `/repo` (run 2) with Jira reachable; the stub state left by run 1 carries over.

## Then
- Run 1: the ledger root is `/repo`, the parent directory of `git rev-parse --git-common-dir` resolved to an absolute path; the agent uses `/repo/.power-architect/2026-11-24-login-lockout/progress.md`
- Run 1: `record(PA-60, done, …)` returns `queued`, and the line `- [ ] q1 | done | PA-60 | a1b2c3d feat: count failed logins\ntests: npx vitest run tests/auth/attempts.test.ts → 2 passed` is written under `## Tracker queue` in `/repo/.power-architect/2026-11-24-login-lockout/progress.md`
- Run 1: nothing is written under `/repo/.worktrees/x/.power-architect/`
- Run 2: replay scans the ledgers under `/repo/.power-architect/` only, sends q1 (one `Done` comment, one transition `41` on PA-60) and rewrites it `- [x] q1`
- Run 2: no duplicate comment and no duplicate transition on PA-60
- No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`.
