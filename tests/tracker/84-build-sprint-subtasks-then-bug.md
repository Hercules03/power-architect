# 84: a Sprint holding Sub-tasks and a Bug builds the Sub-tasks first in "blocks" order, then the Bug; the spec's final review leaves the Bug's commit out

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
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: [{key: "PA-70", type: "Bug", status: "To Do"}, {key: "PA-61", type: "Sub-task", status: "To Do"}, {key: "PA-60", type: "Sub-task", status: "To Do"}, {key: "PA-50", type: "Story", status: "To Do"}]} |
  | getConfluenceContent | page 6001 | the Spec Page "Login lockout" of scenario 60: Scope Tier Small, a `## Plan` section (Global Constraints "Five failures within 10 minutes lock the account.", "The lock lasts 15 minutes." and "A locked login returns 423."; Review Focus "Failures for different accounts never share a counter (test `counts failures per account`, Task 1)."), and the key table `spec`, `1 \| Story \| PA-50`, `1 \| Sub-task \| PA-60`, `2 \| Sub-task \| PA-61` |
  | getJiraIssue | PA-60 | {key: "PA-60", type: Sub-task, summary: "Failed-login counter", status: To Do (after a transition by this dry run, the new status), parent: PA-50, links: PA-60 blocks PA-61, description as scenario 60 PA-60, ending `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`} |
  | getJiraIssue | PA-61 | {key: "PA-61", type: Sub-task, summary: "Login handler enforces the lockout", status: To Do (as above), parent: PA-50, links: PA-61 is blocked by PA-60, description as scenario 60 PA-61, ending with the same Spec Page line} |
  | getJiraIssue | PA-50 | {key: "PA-50", type: Story, summary: "Lock out repeated failed logins", status: To Do, parent: PA-5, description and `## Acceptance Criteria` as scenario 60} |
  | getJiraIssue | PA-70 | {key: "PA-70", type: Bug, summary: "Reset email says Hello, undefined", status: To Do (after a transition by this dry run, the new status), description: "Symptom: the reset email says `Hello, undefined`.\nRepro: a user named Zoë requests a reset.\nRoot cause: the template reads `user.name`, the field is `displayName`.\nFound while working on no tracked item"; no parent, no links} |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to`. Live input schema: `cloudId`, `issueIdOrKey`, `transitionId`, `transitionName`, `fields`, `sprintId`, `assignToBacklog`, `boardId` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | createJiraIssue | any | {key: "PA-<n>"} (n increments from 70) |
  | searchJiraIssuesUsingJql | any | the issues in this table that match the JQL, with this dry run's own creations (none at the start) |
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table with PA-50, PA-60, PA-61, and no `Task` line. There is no `.power-architect/bugs/` directory.
  - The agent is in a linked worktree on branch `feat/login-lockout`; the baseline suite passes.
- Execution outcomes (take as given): every implementer reports DONE, every review is clean. PA-60: commit `a1b2c3d feat: count failed logins`, `npx vitest run tests/auth/attempts.test.ts` → `2 passed`. PA-61: commit `b2c3d4e feat: lock out repeated failed logins`, `… → 3 passed`. PA-70 (Bug "Reset email says Hello, undefined", Backlog item placed in the Sprint): regression test fails first; fix commit `e5f6a7b fix: reset email uses displayName`; `npx vitest run tests/mail/reset.test.ts` → `1 passed`. The final review of the spec finds nothing Critical or Important.
- Trace: report dispatches, ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build` with no argument. If asked which execution method to use, they reply "subagent-driven".

## Then
- `pull(sprint, subtask)` returns PA-60, PA-61 and then PA-70, in that order, even though the Sprint lists the Bug first. PA-50 (a Story) is not in the list and nothing is reported blocked
- The chronological trace shows `record(PA-60, done, …)` before `record(PA-61, started)`, and `record(PA-61, done, …)` before `record(PA-70, started)`. Nothing for PA-70 happens before PA-61's `record(done)`
- PA-60 and PA-61 are built by the Small-tier method with their ledger lines in `.power-architect/2026-11-24-login-lockout/progress.md`; PA-70's line `Task PA-70: complete (…)` is in `.power-architect/bugs/progress.md` (first line `# Ledger — bugs`), and not in the spec's ledger
- The spec's final review is given only the commits `a1b2c3d` and `b2c3d4e`; `e5f6a7b` is not among them and the Bug has no spec axis
- PA-70's regression test is run and fails before its fix, and each of the three has `record(<key>, started)` (transition `21`) and `record(<key>, done, …)` with a `Done` comment and transition `41`
- No write of any kind on PA-50; no Sprint or board write; no `createJiraIssue`
