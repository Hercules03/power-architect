# 69: A Sprint holding Sub-tasks of two specs is built one spec at a time, each spec with its own ledger

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
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: [{key: "PA-50", type: "Story", status: "To Do"}, {key: "PA-80", type: "Story", status: "To Do"}, {key: "PA-81", type: "Sub-task", status: "To Do"}, {key: "PA-60", type: "Sub-task", status: "To Do"}, {key: "PA-82", type: "Sub-task", status: "To Do"}]} |
  | getConfluenceContent | page 6001 | {id: "6001", title: "Login lockout", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): the shared context of "Login lockout" (Scope Tier `Small`), a `## Plan` section whose `### Review Focus` is "Failures for different accounts never share a counter.", then the key table: `spec`, `1 \| Story \| PA-50`, `1 \| Sub-task \| PA-60`} |
  | getConfluenceContent | page 7001 | {id: "7001", title: "Password reset", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/7001", body (Markdown): the shared context of "Password reset" (Scope Tier `Small`), a `## Plan` section whose `### Review Focus` is "A reset link works once and expires after 30 minutes.", then the key table: `spec`, `1 \| Story \| PA-80`, `1 \| Sub-task \| PA-81`, `2 \| Sub-task \| PA-82`} |
  | getJiraIssue | PA-50 | {key: "PA-50", type: Story, summary: "Lock out repeated failed logins", status: To Do, description: its user-story sentence, `## Acceptance Criteria` with one `- [ ]` line, `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`} |
  | getJiraIssue | PA-80 | {key: "PA-80", type: Story, summary: "Reset a forgotten password", status: To Do, description: its user-story sentence, `## Acceptance Criteria` with one `- [ ]` line, `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/7001`} |
  | getJiraIssue | PA-60 | {key: "PA-60", type: Sub-task, summary: "Failed-login counter", status: To Do (after a transition by this dry run, the new status), parent: PA-50, no links, description: its files and steps, then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`} |
  | getJiraIssue | PA-81 | {key: "PA-81", type: Sub-task, summary: "Reset token store", status: To Do (after a transition by this dry run, the new status), parent: PA-80, links: PA-81 blocks PA-82, description: its files and steps, then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/7001`} |
  | getJiraIssue | PA-82 | {key: "PA-82", type: Sub-task, summary: "Reset endpoint", status: To Do (after a transition by this dry run, the new status), parent: PA-80, links: PA-82 is blocked by PA-81, description: its files and steps, then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/7001`} |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to`. Live input schema: `cloudId`, `issueIdOrKey`, `transitionId`, `transitionName`, `fields`, `sprintId`, `assignToBacklog`, `boardId` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
- Ledger / local files:
  - Today is 2026-11-25. Two ledgers exist, each with its `## Work Refs` table and no `Task` line:
    - `.power-architect/2026-11-24-login-lockout/progress.md`, first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`
    - `.power-architect/2026-11-20-password-reset/progress.md`, first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/7001`
  - The agent is already in a linked worktree on branch `feat/sprint-7`. The baseline suite passes.
- Execution outcomes (take as given; dispatching a subagent is described, not performed): every implementer reports DONE and every review is clean. PA-60: commit `a1b2c3d feat: count failed logins`, `npx vitest run tests/auth/attempts.test.ts` → `2 passed`. PA-81: commit `9a8b7c6 feat: reset token store`, `npx vitest run tests/reset/token.test.ts` → `2 passed`. PA-82: commit `8b7c6d5 feat: reset endpoint`, `npx vitest run tests/reset/endpoint.test.ts` → `3 passed`.
- Trace: report dispatches, ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build` with no argument. If asked which execution method to use, they reply "subagent-driven" (for both specs).

## Then
- `pull(sprint, subtask)` returns PA-60 with the Spec Page `…/pages/6001`, and PA-81 then PA-82 with the Spec Page `…/pages/7001`, each with tier Small
- The work is grouped by spec: every Sub-task of one spec is built and recorded done before the first `record(started)` of the other spec's Sub-tasks. Within Password reset, PA-81 comes before PA-82
- `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001, outline)` and `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/7001, outline)` are each called once
- `Task PA-60: complete (…)` is written only to `.power-architect/2026-11-24-login-lockout/progress.md`. `Task PA-81: complete (…)` and `Task PA-82: complete (…)` are written only to `.power-architect/2026-11-20-password-reset/progress.md`. Both first lines are unchanged, and no other ledger is created
- Each Sub-task has `record(<key>, started)` before its implementer dispatch and `record(<key>, done, …)` after its ledger line
- Each spec's final review gets that spec's own Review Focus: "Failures for different accounts never share a counter." for Login lockout, "A reset link works once and expires after 30 minutes." for Password reset
- No MCP write on PA-50 or PA-80. No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`
