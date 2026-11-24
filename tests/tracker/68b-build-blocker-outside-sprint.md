# 68b: A Sub-task whose unfinished blocker is outside the Sprint is reported "blocked by <ref> outside scope" and not built; its ready sibling is built

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
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: [{key: "PA-50", type: "Story", status: "To Do"}, {key: "PA-61", type: "Sub-task", status: "To Do"}, {key: "PA-62", type: "Sub-task", status: "To Do"}]} |
  | getConfluenceContent | page 6001 | {id: "6001", title: "Login lockout", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): the shared context of "Login lockout" (Scope Tier `Small`), a `## Plan` section with Global Constraints and Review Focus, then the key table: `spec`, `1 \| Story \| PA-50`, `1 \| Sub-task \| PA-60`, `2 \| Sub-task \| PA-61`, `3 \| Sub-task \| PA-62`} |
  | getJiraIssue | PA-50 | {key: "PA-50", type: Story, summary: "Lock out repeated failed logins", status: To Do, description: the user-story sentence, `## Acceptance Criteria` with one `- [ ]` line, the Spec Page line} |
  | getJiraIssue | PA-60 | {key: "PA-60", type: Sub-task, summary: "Failed-login counter", status: To Do, parent: PA-50, links: PA-60 blocks PA-61, description ending with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`} |
  | getJiraIssue | PA-61 | {key: "PA-61", type: Sub-task, summary: "Login handler enforces the lockout", status: To Do, parent: PA-50, links: PA-61 is blocked by PA-60, description: Task 2's files and steps, then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`} |
  | getJiraIssue | PA-62 | {key: "PA-62", type: Sub-task, summary: "Lockout message names the wait", status: To Do (after a transition by this dry run, the new status), parent: PA-50, no links, description: Task 3's files and steps (test `npx vitest run tests/auth/message.test.ts`), then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`} |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to`. Live input schema: `cloudId`, `issueIdOrKey`, `transitionId`, `transitionName`, `fields`, `sprintId`, `assignToBacklog`, `boardId` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |

  PA-60 is not in the Sprint.
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, then the `## Work Refs` table. No `Task` line.
  - The agent is already in a linked worktree on branch `feat/login-lockout`. The baseline suite passes.
- Execution outcomes (take as given; dispatching a subagent is described, not performed): every implementer reports DONE and every review is clean. PA-62: commit `e5f6a7b feat: lockout message names the wait`, `npx vitest run tests/auth/message.test.ts` → `1 passed`.
- Trace: report dispatches, ledger writes, Tracker operations, MCP calls and what is said to the user in one chronological list.

## When
The user runs `/power-architect:build` with no argument. If asked which execution method to use, they reply "subagent-driven".

## Then
- `pull(sprint, subtask)` returns PA-62 as ready, and lists PA-61 separately as blocked by PA-60 outside scope (PA-60 is To Do and not in the Sprint)
- The agent tells the user PA-61 is blocked by PA-60, which is outside the Sprint, so PA-61 is not built
- PA-62 is built: `record(PA-62, started)` (transition `21` on PA-62) → implementer → review → ledger line `Task PA-62: complete (…)` → `record(PA-62, done, …)` (one `Done` comment and transition `41` on PA-62)
- Nothing is done for PA-61 or PA-60: no brief, no implementer dispatch, no `record` call, no MCP write, and no ledger line
- No MCP write on PA-50. No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`
