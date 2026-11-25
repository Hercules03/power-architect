# 83: a Bug in the active Sprint is built with the debug method, test first, with started, ledger line in the bugs ledger, then done with the Done template only after the Bug review passes

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
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: [{key: "PA-70", type: "Bug", status: "To Do"}]} |
  | getJiraIssue | PA-70 | {key: "PA-70", type: Bug, summary: "Reset email says Hello, undefined", status: To Do (after a transition by this dry run, the new status), description: "Symptom: the reset email says `Hello, undefined`.\nRepro: a user named Zoë requests a reset.\nRoot cause: the template reads `user.name`, the field is `displayName`.\nFound while working on no tracked item"; no parent, no links} |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to`. Live input schema: `cloudId`, `issueIdOrKey`, `transitionId`, `transitionName`, `fields`, `sprintId`, `assignToBacklog`, `boardId` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | createJiraIssue | any | {key: "PA-<n>"} (n increments from 70) |
  | searchJiraIssuesUsingJql | any | the issues in this table that match the JQL, with this dry run's own creations (none at the start) |
- Ledger / local files:
  - Today is 2026-11-25. There is no `.power-architect/bugs/` directory. The agent is in a linked worktree on branch `fix/reset-email`; the baseline suite `npx vitest run` passes (40 passed).
- Execution outcomes (take as given): the Bug review of the Bug's commits finds nothing Critical or Important. The feedback loop and regression test is `tests/mail/reset.test.ts` test `greets the user by name`; run before the fix it fails (`1 failed`). The fix is one commit `e5f6a7b fix: reset email uses displayName`; after it `npx vitest run tests/mail/reset.test.ts` → `1 passed` and the full suite passes.
- Trace: report files read and written, Tracker operations, MCP calls and test runs in one chronological list.

## When
The user runs `/power-architect:build` with no argument.

## Then
- Before Setup, `pull(sprint, subtask)` returns PA-70 as a ready item of kind Bug, with no Spec Page Work Ref, no Story, no Scope Tier and no blockers. No `getConfluenceContent` call and no `pull(…, outline)` is made
- In order: `record(PA-70, started)` (one `transitionJiraIssue` on PA-70 with transition `21`) → the regression test is written and run, and the trace shows it failing (`1 failed`) → the fix → the test passing → commit `e5f6a7b` → the ledger line `Task PA-70: complete (commits e5f6a7b..e5f6a7b, tests: npx vitest run tests/mail/reset.test.ts → 1 passed)` → the Bug review of `e5f6a7b` (it finds nothing Critical or Important) → the ledger line `Bug review: passed (PA-70)` in the bugs ledger → `record(PA-70, done, …)`. No `record(PA-70, done, …)`, no `Done` comment and no transition `41` comes before the Bug review. The failing run precedes any change to non-test code
- The ledger written is `.power-architect/bugs/progress.md`, whose first line is `# Ledger — bugs`; no `# Ledger — spec:` ledger is written
- `record(PA-70, done, …)` makes one `addOrEditJiraIssueComment` on PA-70 starting with the line `Done`, then a fenced block holding `e5f6a7b fix: reset email uses displayName` and `tests: npx vitest run tests/mail/reset.test.ts → 1 passed`, with no `commentId`, and one `transitionJiraIssue` on PA-70 with transition `41`
- No `record(defect)` and no comment starting `Defect fixed in this item` on PA-70, and no `createJiraIssue` call (fixing the Bug is not a new defect)
- No spec final review is run; no `docs/specs/` or `docs/plans/` file is read
- No Sprint or board write, no transition `31` or `11`, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`
- The agent tells the user PA-70 was built and moved to Done
