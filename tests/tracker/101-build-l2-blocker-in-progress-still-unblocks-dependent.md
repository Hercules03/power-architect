# 101: In L2 (Tracker) a dependent ticket is dispatched once its blocker is merged and ledger-complete although the blocker is still In Progress, and no done is sent until the final review has passed

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
- Items: PA-13 Story (parent PA-10); PA-30 Sub-task "Email sign-up creates an account" (blocks PA-31); PA-31 Sub-task "Sign-up rejects a duplicate email" (blocked by PA-30, blocks PA-32); PA-32 Sub-task "Create an organization at sign-up" (blocked by PA-31). All three Sub-tasks have status To Do; each description ends with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001`.
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-onboarding/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001`, then the `## Work Refs` table. No `Task` line.
  - The agent is already in a linked worktree on branch `feat/onboarding`. The baseline suite `npm test` passes.
- Execution outcomes (take as given; dispatching a subagent is described, not performed): every implementer reports DONE and every merger merges cleanly. Each ticket merges as one commit, with `npm test` → `45 passed`: PA-30 `f0f0f01 feat: email sign-up`, PA-31 `f0f0f02 feat: reject duplicate emails`, PA-32 `f0f0f03 feat: org at sign-up`. The integration-branch review finds nothing Critical or Important.
- Trace: report dispatches, merges, ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build` with no argument.

## Then
- The agent follows L2. The first frontier is PA-30 alone; `record(PA-30, started)` (transition `21`) comes before its dispatch
- After PA-30's merge, the ledger line `Task PA-30: complete (commits f0f0f01..f0f0f01, L2, tests: npm test → 45 passed)` is written and no `record(PA-30, done, …)` is called: PA-30's status is still In Progress when PA-31 is dispatched
- PA-31 joins the frontier at that point, although PA-30 is not Done in the Tracker, because PA-30 is merged and has its ledger line: `record(PA-31, started)` then PA-31's dispatch. The same for PA-32 after PA-31's merge and ledger line
- No `transitionJiraIssue` with transition `41` and no `Done` comment is made on any of PA-30, PA-31 and PA-32 until the integration-branch review and its one fix pass have finished
- Then the ledger line `Final review: passed (spec https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001)` is written, and `record(<key>, done, …)` is called for PA-30, PA-31 and PA-32, in that order, each making one `addOrEditJiraIssueComment` (first line `Done`; then a fenced block holding the commit `<sha> <subject>` and the line `tests: <cmd> → <result>`) and one `transitionJiraIssue` with transition `41`
- No `pull`, status read or wait for a `Done` status of a blocker holds back any dispatch: PA-31 is never reported `blocked by PA-30`
- No MCP write on PA-13. No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`.
