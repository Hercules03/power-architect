# 106: When Jira goes down after the final review, the deferred done events queue and a later run replays them once each

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
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name. Rows are matched top to bottom. The stub keeps state within this dry run.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | * | any, once the final review of this run has passed (every call from then on, for the rest of this run) | UNREACHABLE |
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: the Sub-tasks, Story and Bugs of the Items list with their current statuses} |
  | getConfluenceContent | page 6001 | {id: "6001", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): the shared context (Scope Tier `Small`), a `## Plan` section (a Small plan: Goal, Architecture, Tech Stack, `### Global Constraints`, `### Review Focus` with "Failures for different accounts never share a counter (test `counts failures per account`, Task 1)."; a Large plan: the ticket-graph table), then the key table of the Items list as `<outline id> \| <kind> \| <key>`} |
  | getJiraIssue | a key in the Items list | that item's row with its current status (after a transition by this dry run, the new status), parent, links and description; a Sub-task's description ends with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001` |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
- Items: PA-50 Story "Lock out repeated failed logins" (parent PA-5, Acceptance Criteria `- [ ] The sixth login attempt within 10 minutes after five failures returns 423.`); PA-60 Sub-task "Failed-login counter" (blocks PA-61); PA-61 Sub-task "Login handler enforces the lockout" (blocked by PA-60). Both Sub-tasks have status To Do.
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, then the `## Work Refs` table. No `Task` line, no `## Tracker queue` section.
  - The agent is already in a linked worktree on branch `feat/login-lockout`. The baseline suite passes.
- Execution outcomes (take as given): PA-60: commit `a1b2c3d feat: count failed logins`, `npx vitest run tests/auth/attempts.test.ts` → `2 passed`. PA-61: commit `b2c3d4e feat: lock out repeated failed logins`, `npx vitest run tests/auth/login.test.ts` → `3 passed`. The final review finds nothing Critical or Important.
- Trace: report steps worked, ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build` (run 1), replying "inline" if asked. Jira goes down as the stub says. The user then runs `/power-architect:build` again (run 2) with Jira reachable; the stub state left by run 1 carries over.

## Then
- Run 1: both tasks are started online (transition `21` on each) and their ledger lines are written; no `done` is sent before the final review
- Run 1: after the final review the line `Final review: passed (spec https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001)` is written, then `record(PA-60, done, …)` returns `queued` and `record(PA-61, done, …)` returns `queued`: the ledger's `## Tracker queue` holds `- [ ] q1 | done | PA-60 | a1b2c3d feat: count failed logins\ntests: npx vitest run tests/auth/attempts.test.ts → 2 passed` and `- [ ] q2 | done | PA-61 | b2c3d4e feat: lock out repeated failed logins\ntests: npx vitest run tests/auth/login.test.ts → 3 passed`
- Run 1: the build does not stop; it ends by telling the user the dones of PA-60 and PA-61 are queued, not recorded in Jira. No retry within an event and no Rovo write after the first UNREACHABLE
- Run 2: `pull` replays before it reads: q1 then q2 each send one `Done` comment and one transition `41` and are rewritten `- [x]`. After the replay PA-60 and PA-61 read Done, so nothing is built: no brief, no implementer, no final review, and no `record(done)` from the resume rule
- Each of PA-60 and PA-61 ends with exactly one `Done` comment and one transition `41`. No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`.
