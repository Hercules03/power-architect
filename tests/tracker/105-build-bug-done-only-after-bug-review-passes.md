# 105: A Bug build records done only after the Bug review passes, even when that review first raises an Important finding that its fix resolves

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
  | createJiraIssue | any | {key: "PA-<n>"} (n increments from 70) |
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: the Sub-tasks, Story and Bugs of the Items list with their current statuses} |
  | getConfluenceContent | page 6001 | {id: "6001", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): the shared context (Scope Tier `Small`), a `## Plan` section (a Small plan: Goal, Architecture, Tech Stack, `### Global Constraints`, `### Review Focus` with "Failures for different accounts never share a counter (test `counts failures per account`, Task 1)."; a Large plan: the ticket-graph table), then the key table of the Items list as `<outline id> \| <kind> \| <key>`} |
  | getJiraIssue | a key in the Items list | that item's row with its current status (after a transition by this dry run, the new status), parent, links and description; a Sub-task's description ends with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001` |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
- Items: PA-70 Bug "Reset email says Hello, undefined" (status To Do, Backlog item placed in the Sprint). Its description holds the symptom, the repro and the root cause (the template reads `user.name`, the field is `displayName`).
- Ledger / local files:
  - Today is 2026-11-25. There is no `.power-architect/bugs/` directory. The agent is in a linked worktree on branch `fix/reset-email`; the baseline suite passes.
- Execution outcomes (take as given): the regression test `tests/mail/reset.test.ts` test `greets the user by name` fails before the fix (`1 failed`). The fix is one commit `e5f6a7b fix: reset email uses displayName`; afterwards `npx vitest run tests/mail/reset.test.ts` → `1 passed`. The Bug review of `e5f6a7b` raises one Important finding (the plain-text template still reads `user.name`); the fix it prompts is one commit `f6a7b8c fix: plain-text reset template uses displayName`, and the re-check leaves no Critical or Important finding open.
- Trace: report files read and written, Tracker operations, MCP calls and test runs in one chronological list.

## When
The user runs `/power-architect:build` with no argument.

## Then
- `record(PA-70, started)` (transition `21` on PA-70) comes before any work; the regression test is shown failing before the fix
- The ledger line `Task PA-70: complete (commits e5f6a7b..e5f6a7b, tests: npx vitest run tests/mail/reset.test.ts → 1 passed)` is written in `.power-architect/bugs/progress.md`, then the Bug review runs on `e5f6a7b` only, with no spec
- No `Done` comment (first line `Done`) and no transition `41` is made on PA-70 while the Bug review is raising or resolving its Important finding; the `Defect fixed in this item` comment that review requires for that finding is allowed
- After the fix pass, the ledger line `Fix (bug PA-70): commits f6a7b8c..f6a7b8c` is written in the bugs ledger, then (only after the finding is resolved) the ledger line `Bug review: passed (PA-70)` written in the bugs ledger, below the `Task PA-70` line. Then `record(PA-70, done, …)` makes one `Done` comment (the evidence from the ledger lines: `e5f6a7b fix: reset email uses displayName`, then once `f6a7b8c fix: plain-text reset template uses displayName`, and `tests: npx vitest run tests/mail/reset.test.ts → 1 passed`) and one transition `41`
- No `# Ledger — spec:` ledger is written, no spec final review is run, and no `createJiraIssue` call is made. No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`.
