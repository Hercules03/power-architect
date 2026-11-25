# 111: In L2, when the spec cannot be pulled for the final review, the build stops before the review: items stay In Progress, no marker, no Done

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
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: the Sub-tasks, Story and Bugs of the Items list with their current statuses} |
  | getConfluenceContent | page 4001 | {id: "4001", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001", body (Markdown): the shared context (Scope Tier `Large`), a `## Plan` section (a Small plan: Goal, Architecture, Tech Stack, `### Global Constraints`, `### Review Focus` with "Failures for different accounts never share a counter (test `counts failures per account`, Task 1)."; a Large plan: the ticket-graph table), then the key table of the Items list as `<outline id> \| <kind> \| <key>`} |
  | getJiraIssue | a key in the Items list | that item's row with its current status (after a transition by this dry run, the new status), parent, links and description; a Sub-task's description ends with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001` |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
- Items: PA-13 Story (parent PA-10); PA-30 Sub-task "Email sign-up creates an account" (blocks PA-31); PA-31 Sub-task "Sign-up rejects a duplicate email" (blocked by PA-30). Both Sub-tasks have status In Progress; each description ends with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001`.
- Ledger / local files:
  - Today is 2026-11-26, a new session. `.power-architect/2026-11-24-onboarding/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001`, then the `## Work Refs` table, `Task PA-30: complete (commits f0f0f01..f0f0f01, L2, tests: npm test → 45 passed)` and `Task PA-31: complete (commits f0f0f02..f0f0f02, L2, tests: npm test → 45 passed)`. No `Final review: passed` line. The previous session ended after the last merge.
  - The agent is in a linked worktree on branch `feat/onboarding`; both commits are on the integration branch. The baseline suite `npm test` passes.
- Execution outcomes: every Tracker call up to and including the `pull(sprint, subtask)` that returns the work list succeeds (it returns PA-30 and PA-31, both In Progress). Every Tracker call after that returns UNREACHABLE (the stub row `* | any, once the work list has been returned | UNREACHABLE`). If the review ran, it would find nothing Critical or Important.
- Trace: report dispatches, ledger writes, Tracker operations, MCP calls and any review diff command in one chronological list.

## When
The user runs `/power-architect:build` with no argument.

## Then
- `pull(sprint, subtask)` returns PA-30 and PA-31. Both `Task` lines carry the token `L2` and no `Final review: passed` line follows them, so they are deferred items whose review is missing: neither is rebuilt (no implementer or merger dispatch, no `record(started)`), and no `record(done)` fires
- The agent goes to L2 step 6 and calls `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001, outline)` for the spec; it stops with the Tracker unreachable. The build stops BEFORE the final review: no review diff is written, and no reviewer or fix implementer is dispatched
- No `Final review: passed` line is written, and no `Fix` line. No `record(PA-30, done, …)` and no `record(PA-31, done, …)` is called (no comment, no transition `41`); both stay In Progress and ledger-complete, with exactly one `Task` line each
- No draft PR is marked ready, and the agent does not recommend `/power-architect:verify` or `/power-architect:finish`
- The agent tells the user the final review did not run because the Tracker was unreachable, that PA-30 and PA-31 stay In Progress, and to re-run `/power-architect:build` once the Tracker is reachable
- No Rovo call is made after the first UNREACHABLE (no retry). No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call.
