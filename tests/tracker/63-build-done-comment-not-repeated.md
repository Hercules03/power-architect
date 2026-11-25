# 63: When the done comment is already on a Sub-task (a crash after the comment, before the move to Done), resuming moves it to Done and adds no second comment

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
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: [{key: "PA-50", type: "Story", status: "In Progress"}, {key: "PA-60", type: "Sub-task", status: "In Progress"}]} |
  | getConfluenceContent | page 6001 | {id: "6001", title: "Login lockout", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): the shared context of "Login lockout" (Scope Tier `Small`), a `## Plan` section with Global Constraints and Review Focus, then the key table: `spec`, `1 \| Story \| PA-50`, `1 \| Sub-task \| PA-60`, `2 \| Sub-task \| PA-61`, `3 \| Sub-task \| PA-62`} |
  | getJiraIssue | PA-50 | {key: "PA-50", type: Story, summary: "Lock out repeated failed logins", status: In Progress, description: the user-story sentence, `## Acceptance Criteria` with one `- [ ]` line, `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`} |
  | getJiraIssue | PA-60 | {key: "PA-60", type: Sub-task, summary: "Failed-login counter", status: In Progress (after a transition by this dry run, the new status), parent: PA-50, links: PA-60 blocks PA-61, description ending with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`} |
  | getJiraIssue | PA-61 | {key: "PA-61", type: Sub-task, summary: "Login handler enforces the lockout", status: To Do, parent: PA-50, links: PA-61 is blocked by PA-60} |
  | getJiraIssue | PA-62 | {key: "PA-62", type: Sub-task, summary: "Unlock after 15 minutes", status: To Do, parent: PA-50, links: PA-62 is blocked by PA-61} |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to`. Live input schema: `cloudId`, `issueIdOrKey`, `transitionId`, `transitionName`, `fields`, `sprintId`, `assignToBacklog`, `boardId` |
  | listJiraIssueComments | PA-60 | one comment, c-7, whose body is the line `Done`, then a fenced code block holding the two lines `a1b2c3d feat: count failed logins` and `tests: npx vitest run tests/auth/attempts.test.ts → 2 passed` |
  | listJiraIssueComments | any other | none |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | git log for the ledger line's range a1b2c3d..a1b2c3d (both included) | (shell) | `a1b2c3d feat: count failed logins` |

- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table, and `Task PA-60: complete (commits a1b2c3d..a1b2c3d, review clean, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)`. The previous session crashed after adding comment c-7 and before moving PA-60 to Done.
  - The agent is already in a linked worktree on branch `feat/login-lockout`, where commit `a1b2c3d` is in `git log`. The baseline suite passes.
- Trace: report dispatches, ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build` with no argument. If asked which execution method to use, they reply "subagent-driven".

## Then
- `pull(sprint, subtask)` returns only PA-60 (status In Progress)
- PA-60 is not rebuilt: no brief, no implementer or reviewer dispatch
- `record(PA-60, done, …)` is called exactly once. Its MCP calls include `listJiraIssueComments` on PA-60 and exactly one `transitionJiraIssue` on PA-60, with transition `41`
- No `addOrEditJiraIssueComment` call at all: PA-60 keeps exactly one `Done` comment (c-7)
- The ledger still holds exactly one `Task PA-60` line
- No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`. No MCP write on PA-50, PA-61 or PA-62
