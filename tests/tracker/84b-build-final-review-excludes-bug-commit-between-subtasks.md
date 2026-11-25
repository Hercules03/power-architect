# 84b: a spec's final review diff is the union of its ledger's Task ranges, so a Bug commit lying between two Sub-task commits is excluded

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
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: [{key: "PA-62", type: "Sub-task", status: "To Do"}, {key: "PA-61", type: "Sub-task", status: "To Do"}, {key: "PA-50", type: "Story", status: "To Do"}]} |
  | getConfluenceContent | page 6001 | the Spec Page "Login lockout" of scenario 60: Scope Tier Small, a `## Plan` section (Global Constraints "Five failures within 10 minutes lock the account.", "The lock lasts 15 minutes." and "A locked login returns 423."; Review Focus "Failures for different accounts never share a counter (test `counts failures per account`, Task 1)."), and the key table `spec`, `1 \| Story \| PA-50`, `1 \| Sub-task \| PA-60`, `2 \| Sub-task \| PA-61`, `3 \| Sub-task \| PA-62` |
  | getJiraIssue | PA-60 | {key: "PA-60", type: Sub-task, summary: "Failed-login counter", status: Done, parent: PA-50, links: PA-60 blocks PA-61, description as scenario 60 PA-60, ending `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`} |
  | getJiraIssue | PA-61 | {key: "PA-61", type: Sub-task, summary: "Login handler enforces the lockout", status: To Do (as above), parent: PA-50, links: PA-61 is blocked by PA-60, description as scenario 60 PA-61, ending with the same Spec Page line} |
  | getJiraIssue | PA-50 | {key: "PA-50", type: Story, summary: "Lock out repeated failed logins", status: To Do, parent: PA-5, description and `## Acceptance Criteria` as scenario 60} |
  | getJiraIssue | PA-62 | {key: "PA-62", type: Sub-task, summary: "Lock expires after 15 minutes", status: To Do (as above), parent: PA-50, links: PA-62 is blocked by PA-61, description as scenario 60 PA-61 but for the unlock rule, ending with the same Spec Page line} |
  | getJiraIssue | PA-70 | {key: "PA-70", type: Bug, summary: "Reset email says Hello, undefined", status: Done, description: "Symptom: the reset email says `Hello, undefined`.\nRepro: a user named Zoë requests a reset.\nRoot cause: the template reads `user.name`, the field is `displayName`.\nFound while working on no tracked item"; no parent, no links} |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to`. Live input schema: `cloudId`, `issueIdOrKey`, `transitionId`, `transitionName`, `fields`, `sprintId`, `assignToBacklog`, `boardId` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | createJiraIssue | any | {key: "PA-<n>"} (n increments from 70) |
  | searchJiraIssuesUsingJql | any | the issues in this table that match the JQL, with this dry run's own creations (none at the start) |
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` (in the main checkout) exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table with PA-50, PA-60, PA-61, PA-62, and `Task PA-60: complete (commits a1b2c3d..a1b2c3d, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)`. `.power-architect/bugs/progress.md` (first line `# Ledger — bugs`) holds `Task PA-70: complete (commits e5f6a7b..e5f6a7b, tests: npx vitest run tests/mail/reset.test.ts → 1 passed)`. These were built in an earlier run; PA-60 and PA-70 are Done in Jira.
  - The agent is in a linked worktree on branch `feat/login-lockout`. The branch history is `a1b2c3d` (PA-60), then `e5f6a7b` (the Bug PA-70), then the commits built in this run. The baseline suite passes.
- Execution outcomes (take as given): every implementer reports DONE and every review is clean. PA-61: commit `b2c3d4e feat: lock out repeated failed logins`, `… → 3 passed`. PA-62: commit `c3d4e5f feat: unlock after 15 minutes`, `… → 2 passed`. The spec's final review finds nothing Critical or Important.
- Trace: report dispatches, ledger writes, Tracker operations and the final-review diff command in one chronological list.

## When
The user runs `/power-architect:build` with no argument. If asked which execution method to use, they reply "subagent-driven".

## Then
- The spec's final review diff is built from the union of the ledger's `Task` ranges `a1b2c3d..a1b2c3d`, `b2c3d4e..b2c3d4e` and `c3d4e5f..c3d4e5f`; the trace shows the reviewer told these three commits
- It is not one span from `a1b2c3d` to `c3d4e5f`: `e5f6a7b` (the Bug's commit, lying between `a1b2c3d` and `b2c3d4e`) is not in the diff and not in the commit list given to the reviewer
- The final review runs (this spec had new work this run)
