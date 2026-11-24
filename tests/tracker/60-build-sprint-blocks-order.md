# 60: `/build` with no argument builds the active Sprint's three Small Sub-tasks in "blocks" order, each with started → implementer → review → ledger line → done

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
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name. Rows are matched top to bottom. The stub keeps state within this dry run: a read returns what this dry run's own earlier writes left behind.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: [{key: "PA-50", type: "Story", status: "To Do"}, {key: "PA-62", type: "Sub-task", status: "To Do"}, {key: "PA-61", type: "Sub-task", status: "To Do"}, {key: "PA-60", type: "Sub-task", status: "To Do"}]}. Live input schema: `cloudId`, `boardId`, `sprintId` and `sprintName` (optional; the active Sprint by default), `includeIssues` |
  | getConfluenceContent | page 6001 | {id: "6001", title: "Login lockout", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): the shared context, Plan section and key table below} |
  | getJiraIssue | PA-50 | {key: "PA-50", type: Story, summary: "Lock out repeated failed logins", status: To Do, parent: PA-5, description: "As a user, I want my account locked for 15 minutes after five failed logins in 10 minutes, so that my password can't be guessed.", then `## Acceptance Criteria` with `- [ ] The sixth login attempt within 10 minutes after five failures returns 423.`, then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`; no links} |
  | getJiraIssue | PA-60, PA-61, PA-62 | that item's row of the Items table below, with its current status (after a transition by this dry run, the new status) |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to`. Live input schema: `cloudId`, `issueIdOrKey`, `transitionId`, `transitionName`, `fields`, `sprintId`, `assignToBacklog`, `boardId` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | manageJiraSprint | any | {ok: true} |

  Items (each Sub-task's parent is PA-50; each description ends with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`):

  | Key | Kind | summary | status | links | description (before the Spec Page line) |
  |---|---|---|---|---|---|
  | PA-60 | Sub-task | Failed-login counter | To Do | PA-60 blocks PA-61 | Files: Create `src/auth/attempts.ts`; Test `tests/auth/attempts.test.ts`. Interfaces: Produces `recordFailure(accountId: string): Promise<number>` and `isLocked(accountId: string): Promise<boolean>`. Steps as `- [ ]` lines: write the failing test `counts failures per account`; run `npx vitest run tests/auth/attempts.test.ts` (Expected: FAIL); implement; run it again (Expected: PASS); commit |
  | PA-61 | Sub-task | Login handler enforces the lockout | To Do | PA-61 is blocked by PA-60; PA-61 blocks PA-62 | Files: Modify `src/auth/login.ts:40-62`; Test `tests/auth/login.test.ts`. Interfaces: Consumes `recordFailure` and `isLocked`. Steps as `- [ ]` lines: write the failing test `returns 423 after five failures`; run `npx vitest run tests/auth/login.test.ts` (Expected: FAIL); implement; run it again (Expected: PASS); commit |
  | PA-62 | Sub-task | Unlock after 15 minutes | To Do | PA-62 is blocked by PA-61 | Files: Modify `src/auth/attempts.ts`; Test `tests/auth/unlock.test.ts`. Steps as `- [ ]` lines: write the failing test `unlocks after 15 minutes`; run `npx vitest run tests/auth/unlock.test.ts` (Expected: FAIL); implement; run it again (Expected: PASS); commit |

  Spec Page body on page 6001: the shared context of the spec "Login lockout" (Problem Statement, Solution, Goals, Implementation Decisions, Testing Decisions with the seam "the login HTTP endpoint", Out of Scope, and a Scope Tier section reading `Small`), then:

  ```md
  ## Plan

  **Goal:** Lock an account for 15 minutes after five failed logins within 10 minutes.
  **Architecture:** A counter module records failed logins per account in the existing Redis store. The login handler asks it before checking the password and records each failure.
  **Tech Stack:** TypeScript, Express, Redis, Vitest.

  ### Global Constraints
  - Five failures within 10 minutes lock the account.
  - The lock lasts 15 minutes.
  - A locked login returns 423.

  ### Review Focus
  - Failures for different accounts never share a counter (test `counts failures per account`, Task 1).

  ## Work Refs

  | outline id | kind | Work Ref | title |
  |---|---|---|---|
  | spec | Spec Page | https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001 | Login lockout |
  | 1 | Story | PA-50 | Lock out repeated failed logins |
  | 1 | Sub-task | PA-60 | Failed-login counter |
  | 2 | Sub-task | PA-61 | Login handler enforces the lockout |
  | 3 | Sub-task | PA-62 | Unlock after 15 minutes |
  ```
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists. Its first line is `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, followed by a `## Work Refs` table with the same 5 rows as the key table. It has no `Task` line. There is no `docs/specs/` or `docs/plans/` file for this spec.
  - The agent is already in a linked worktree on branch `feat/login-lockout`. The baseline suite `npx vitest run` passes (40 passed).
- Execution outcomes (take as given; dispatching a subagent is described, not performed):
  - Every implementer reports DONE. Every task review reports spec compliance ✅ and no Critical or Important finding. The final review finds nothing Critical or Important.
  - PA-60's work is one commit `a1b2c3d feat: count failed logins`; its test run `npx vitest run tests/auth/attempts.test.ts` → `2 passed`.
  - PA-61's work is one commit `b2c3d4e feat: lock out repeated failed logins`; `npx vitest run tests/auth/login.test.ts` → `3 passed`.
  - PA-62's work is one commit `c3d4e5f feat: unlock after 15 minutes`; `npx vitest run tests/auth/unlock.test.ts` → `1 passed`.
  - `git log --oneline` over each task's range shows exactly that task's one commit.
- Trace: report implementer and reviewer dispatches, brief and ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build` with no argument. If asked which execution method to use, they reply "subagent-driven".

## Then
- The agent reads the `## Tracker` section, opens `references/tracker.md`, then `references/tracker-jira.md`, and the config check passes
- Before any workspace setup step, the agent calls `pull(sprint, subtask)`. Its MCP calls are reads only, among them `getJiraBoardSprintData` with boardId `12` and no `sprintId` or `sprintName`, and `getJiraIssue` on PA-60, PA-61 and PA-62. It returns PA-60, PA-61, PA-62 in that order, each with the Spec Page `https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001` and tier Small; PA-50 (a Story) is not in the work list, and nothing is reported blocked
- `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001, outline)` is called before the first implementer dispatch. Nothing under `docs/specs/` or `docs/plans/` is read
- For each of PA-60, PA-61, PA-62, in that order, the chronological trace shows: `record(<key>, started)` with a `transitionJiraIssue` on that key with transition `21` → the task brief written, holding that Sub-task's description and PA-50's Acceptance Criteria → the implementer dispatch → the task reviewer dispatch → a ledger line `Task <key>: complete (…)` naming its commit → `record(<key>, done, …)` with one `addOrEditJiraIssueComment` and one `transitionJiraIssue` with transition `41` on that key. Nothing for the next Sub-task happens before the previous one's `record(done)`
- Each task reviewer is given the Plan section's three Global Constraints verbatim
- Each done comment starts with the line `Done`, followed by a fenced code block holding that Sub-task's commit short SHA and subject and its test command with its result (PA-60: `a1b2c3d feat: count failed logins` and `npx vitest run tests/auth/attempts.test.ts` → `2 passed`; PA-61: `b2c3d4e …` and `… → 3 passed`; PA-62: `c3d4e5f …` and `… → 1 passed`). No comment call passes a `commentId`
- All three `Task` lines are added to `.power-architect/2026-11-24-login-lockout/progress.md`, whose first line is unchanged. No other ledger is written
- The final reviewer is given the Review Focus line "Failures for different accounts never share a counter (test `counts failures per account`, Task 1)." verbatim and the spec as read by `pull` (not a `docs/specs/` path)
- No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`. No transition `31` (to In Review) or `11`
- No write of any kind on PA-50 (no transition, comment or edit), and no `createJiraIssue`, `editJiraIssue`, `createJiraIssueLink`, `updateConfluenceContent` or `executeDestructive` call
- The agent tells the user PA-60, PA-61 and PA-62 were built and moved to Done, and recommends `/power-architect:verify`
