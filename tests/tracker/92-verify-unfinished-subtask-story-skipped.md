# 92: verify skips a Story with an unfinished Sub-task, even when its criteria would pass

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
  - PA-50 Story "Lock out repeated failed logins" (Done, parent PA-5), with Sub-tasks PA-60 and PA-61 (both Done).
  - PA-51 Story "Admins see lockouts" (In Progress, parent PA-5): `## Acceptance Criteria` has one line: `- [ ] The admin audit log lists each lockout.`
  - PA-62 Sub-task "Audit log entry on lockout" (Done, parent PA-51); PA-63 Sub-task "Audit log page" (In Progress, parent PA-51).
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists in the repo checkout: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table (Spec Page, Epic PA-5, the Stories and Sub-tasks of the Items list), `Task PA-60: complete (commits a1b2c3d..a1b2c3d, review clean, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)` `Task PA-61: complete (commits b2c3d4e..b2c3d4e, review clean, tests: npx vitest run tests/auth/login.test.ts → 3 passed)` and `Task PA-62: complete (commits c3d4e5f..c3d4e5f, review clean, tests: npx vitest run tests/admin/audit.test.ts → 1 passed)`. PA-63 has no `Task` line. No `## Tracker queue` section. No local spec file exists under `docs/`.
  - The agent is in the repo checkout on branch `feat/login-lockout`.
- Execution outcomes (take as given): `npm test` → `14 passed`; `npx tsc --noEmit` exits 0; `npm run lint` → `0 problems`; the project has no build script.

  If anyone runs `npx vitest run tests/admin/audit.test.ts -t "lists each lockout"` it returns `1 passed`.
- Trace: report Tracker operations, MCP calls, shell commands and ledger writes in one chronological list.

## When
The user runs the phase.

## Then
- `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001, story)` returns exactly one Story, PA-51 (PA-50 is Done and not returned), flagged as having an unfinished Sub-task: PA-63
- The agent reports that the Story has unfinished Sub-task(s) PA-63 and is not verified, and says it was skipped
- PA-51's criterion `The admin audit log lists each lockout.` is never marked passed or verified, even though its command would pass
- `record` is never called for PA-51 or any item. There is no `addOrEditJiraIssueComment` and no `transitionJiraIssue` call at all: PA-51 is not marked Done and nothing is written to the Tracker
- verify still runs the full suite, typecheck and lint, and the Local checklist against the spec read through `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001, outline)`; the checklist leaves out PA-51's criterion, so its command is not run
- The agent does not tell the user PA-51 is Done or complete, and tells them to finish PA-63 (for example with `/power-architect:build PA-63`) and run verify again
- No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`. No `addOrEditJiraIssueComment` passes `commentId`. No resolution, assignee or estimate is set
