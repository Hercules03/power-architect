# 91: verify leaves a Story open and writes nothing when one Acceptance Criterion fails

**Phase:** /power-architect:verify

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
- Tracker state: stubbed Rovo table (a tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name; rows match top to bottom; the stub keeps state within this dry run).

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getConfluenceContent | page 6001 | {id: "6001", title: "Login lockout", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): the shared context of "Login lockout" (Scope Tier `Small`), a `## Plan` section, then the key table: the `spec` row and one row per Epic, Story and Sub-task of the Items list, as `<outline id> \| <kind> \| <key>`} |
  | getJiraIssue | a key in the Items list | that item's row: key, type, summary, status, parent, and description. A Story's description is its user-story sentence, `## Acceptance Criteria` with its `- [ ]` lines, then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`. A Sub-task's description is one line then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001` |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to`. Live input schema: `cloudId`, `issueIdOrKey`, `transitionId`, `transitionName`, `fields`, `sprintId`, `assignToBacklog`, `boardId` |
  | listJiraIssueComments | any | the comments listed for that issue in this Given, plus the comments this dry run has added to it |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} (n increments from 10). Live input schema: `cloudId`, `issueIdOrKey`, `commentBody`, `commentId` |
- Items:
  - PA-5 Epic "Account security" (To Do); PA-70 Bug "Lockout counter is off by one" (To Do, no parent, Backlog).
  - PA-50 Story "Lock out repeated failed logins" (In Progress, parent PA-5): `## Acceptance Criteria` has two lines: `- [ ] The sixth login attempt within 10 minutes after five failures returns 423.` and `- [ ] A locked account unlocks after 15 minutes.`.
  - PA-60 Sub-task "Failed-login counter" (Done, parent PA-50); PA-61 Sub-task "Login handler enforces the lockout" (Done, parent PA-50).
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists in the repo checkout: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table (Spec Page, Epic PA-5, the Stories and Sub-tasks of the Items list), `Task PA-60: complete (commits a1b2c3d..a1b2c3d, review clean, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)` and `Task PA-61: complete (commits b2c3d4e..b2c3d4e, review clean, tests: npx vitest run tests/auth/login.test.ts → 3 passed)`. No `## Tracker queue` section. No local spec file exists under `docs/`.
  - The agent is in the repo checkout on branch `feat/login-lockout`.
- Trace: report Tracker operations, MCP calls, shell commands and ledger writes in one chronological list.
- Execution outcomes (take as given): `npm test` → `14 passed`; `npx tsc --noEmit` exits 0; `npm run lint` → `0 problems`; the project has no build script.

  Proving commands: for "The sixth login attempt within 10 minutes after five failures returns 423." `npx vitest run tests/auth/lockout.test.ts -t "sixth attempt"` → `1 passed`; for "A locked account unlocks after 15 minutes." `npx vitest run tests/auth/lockout.test.ts -t "unlock after 15 minutes"` → `1 failed` (`expected the account to be unlocked, got 423`; exit code 1).

## When
The user runs the phase.

## Then
- `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001, story)` returns PA-50 with both Sub-tasks Done, before any proving command is run
- Both criteria are run fresh, and each output is read before it is judged: `The sixth login attempt within 10 minutes after five failures returns 423.` passes, and `A locked account unlocks after 15 minutes.` fails with `1 failed`
- `record` is never called for PA-50. There is no `addOrEditJiraIssueComment` and no `transitionJiraIssue` call at all in the run, on PA-50 or any other issue: nothing is written to the Tracker
- The agent reports the gap: PA-50 is not Done, the failing criterion is `A locked account unlocks after 15 minutes.`, with the command `npx vitest run tests/auth/lockout.test.ts -t "unlock after 15 minutes"` and its output (`1 failed`, `expected the account to be unlocked, got 423`)
- The agent never says PA-50 is verified, complete or Done, and does not mark the failing criterion passed (no `✅` line for it anywhere)
- It does not recommend `/power-architect:finish` as the next step: it reports that the Story needs work first
- No ledger line is written
- No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`. No `addOrEditJiraIssueComment` passes `commentId`. No resolution, assignee or estimate is set
