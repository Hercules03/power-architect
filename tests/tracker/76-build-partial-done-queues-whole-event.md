# 76: A `done` that fails partway queues the whole event, and replay finishes it without a second comment

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
- Tracker state: stubbed Rovo table (a tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name; rows match top to bottom; the stub keeps state within this dry run and across runs of this scenario).

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | * | any, once the `Done` comment on PA-60 has been added (every call from then on, in run 1); in run 2 every row answers normally | UNREACHABLE |
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: [{key: "PA-50", type: "Story", status: "In Progress"}, {key: "PA-60", type: "Sub-task", status: "To Do"}]} (each status is the issue's current status) |
  | getConfluenceContent | page 6001 | {id: "6001", title: "Login lockout", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): shared context (Scope Tier `Small`), a `## Plan` section, then the key table `spec`, `1 | Story | PA-50`, `1 | Sub-task | PA-60`, `2 | Sub-task | PA-61`} |
  | getJiraIssue | PA-50 | {key: "PA-50", type: Story, status: In Progress, parent: PA-5, description: story sentence, `## Acceptance Criteria` with `- [ ] The sixth login attempt within 10 minutes after five failures returns 423.`, `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`} |
  | getJiraIssue | PA-60, PA-61 | that item's row of the Items table, with its current status |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} (n increments from 1) |

  Items (each Sub-task's parent is PA-50; each description ends with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`): PA-60 "Failed-login counter".
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table (Spec Page, Story PA-50, Sub-task PA-60), `Pre-flight: no shared interfaces`, no `Task` line, no queue section. The agent is in a linked worktree; the baseline suite passes.
- Execution outcomes (as given): the implementer reports DONE and review is clean: commit `a1b2c3d feat: count failed logins`, `npx vitest run tests/auth/attempts.test.ts` → `2 passed`.
- Trace: report dispatches, ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build` (run 1), replying "subagent-driven" if asked. The task completes. Later the user runs `/power-architect:build` again (run 2) with Jira reachable; the stub state left by run 1 carries over.

## Then
- Run 1: `record(PA-60, done, …)` makes one `addOrEditJiraIssueComment` on PA-60 (a `Done` comment holding `a1b2c3d feat: count failed logins` and `tests: npx vitest run tests/auth/attempts.test.ts → 2 passed`), then its next call (`listJiraIssueTransitions`) returns UNREACHABLE. No transition `41` is made
- Run 1: the result is `queued` and the whole event is queued, `- [ ] q1 | done | PA-60 | a1b2c3d feat: count failed logins\ntests: npx vitest run tests/auth/attempts.test.ts → 2 passed`, even though the comment was written. The build ends normally; the user is told PA-60's done is queued
- Run 2: replay runs before the Sprint read. It reads PA-60's comments (`listJiraIssueComments`), finds the existing `Done` comment holding the evidence and adds none, then makes one `transitionJiraIssue` on PA-60 with transition `41`. q1 becomes `- [x] q1`
- Across both runs PA-60 has exactly one `Done` comment (one `addOrEditJiraIssueComment` call in total) and exactly one transition to Done
- Run 2: the Sprint read then shows PA-60 Done, nothing is built, and the Resume rule fires no `record(PA-60, done)`
- No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`.
