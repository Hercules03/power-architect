# 65: `/build <Large Sub-task key>` runs L1 on that one Sub-task: started before the work, ledger line then done after review and commit

**Phase:** /power-architect:build PA-31

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
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, state: "active"}, issues: [{key: "PA-13", type: "Story"}, {key: "PA-30", type: "Sub-task", status: "Done"}, {key: "PA-31", type: "Sub-task", status: "To Do"}, {key: "PA-32", type: "Sub-task", status: "To Do"}]} |
  | getConfluenceContent | page 4001 | {id: "4001", title: "Self-serve onboarding", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001", body (Markdown): the shared context of "Self-serve onboarding" (a Scope Tier section reading `Large`; Testing Decisions with the seam "the public HTTP API"), then a `## Plan` section with the table `\| ticket \| title \| Blocked by \|` and rows `01 \| Email sign-up creates an account \| None`, `02 \| Sign-up rejects a duplicate email \| 01`, `03 \| Create an organization at sign-up \| 01`, then the key table: `spec`, `E1 \| Epic \| PA-10`, `1 \| Story \| PA-13`, `4 \| Story \| PA-16`, `01 \| Sub-task \| PA-30`, `02 \| Sub-task \| PA-31`, `03 \| Sub-task \| PA-32`} |
  | getJiraIssue | PA-10 | {key: "PA-10", type: Epic, summary: "Identity & SSO", status: To Do} |
  | getJiraIssue | PA-13 | {key: "PA-13", type: Story, summary: "Sign up with email", status: In Progress, parent: PA-10, description: "As a new user, I want to sign up with email and password, so that I can start a trial.", then `## Acceptance Criteria` with `- [ ] POST /signup with a new email returns 201.`, then the Spec Page line} |
  | getJiraIssue | PA-16 | {key: "PA-16", type: Story, summary: "Create an organization at sign-up", status: To Do, parent: PA-11} |
  | getJiraIssue | PA-30 | {key: "PA-30", type: Sub-task, summary: "Email sign-up creates an account", status: Done, parent: PA-13, links: PA-30 blocks PA-31, PA-30 blocks PA-32} |
  | getJiraIssue | PA-31 | {key: "PA-31", type: Sub-task, summary: "Sign-up rejects a duplicate email", status: To Do (after a transition by this dry run, the new status), parent: PA-13, links: PA-31 is blocked by PA-30, description: "Signing up twice with one email is refused.", `## Acceptance criteria` with `- [ ] A second POST /signup with the same email returns 409.`, `Blocked by: Email sign-up creates an account`, `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001`} |
  | getJiraIssue | PA-32 | {key: "PA-32", type: Sub-task, summary: "Create an organization at sign-up", status: To Do, parent: PA-16, links: PA-32 is blocked by PA-30} |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to`. Live input schema: `cloudId`, `issueIdOrKey`, `transitionId`, `transitionName`, `fields`, `sprintId`, `assignToBacklog`, `boardId` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-onboarding/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001`, the `## Work Refs` table with the key table's rows, and `Task PA-30: complete (commits e0e0e0e..e0e0e0e, tests: npm test → 40 passed)`. There is no `docs/specs/` or `docs/plans/` file for this spec.
  - The agent is already in a linked worktree on branch `feat/onboarding`. The baseline suite `npm test` passes.
- Execution outcomes (take as given): the work for PA-31 is one commit `d4e5f6a feat: reject duplicate sign-up emails`; `npm test` → `42 passed`; the review method finds nothing to fix. `git log --oneline` over the work's range shows that one commit.
- Trace: report files read and written, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build PA-31`.

## Then
- The agent calls `pull(PA-31, subtask)`. It returns only PA-31 (ready: its blocker PA-30 is Done), with tier Large and the Spec Page `https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001`
- The agent follows L1 (one ticket) and calls `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001, outline)`. It states the title "Sign-up rejects a duplicate email" before starting. Nothing under `docs/specs/` or `docs/plans/` is read
- In order: `record(PA-31, started)` (a `transitionJiraIssue` on PA-31 with transition `21`) → the TDD work and the review method → the commit `d4e5f6a` → a ledger line `Task PA-31: complete (…)` naming `d4e5f6a` in `.power-architect/2026-11-24-onboarding/progress.md` → `record(PA-31, done, …)`
- `record(PA-31, done, …)` makes one `addOrEditJiraIssueComment` on PA-31 starting with the line `Done`, holding `d4e5f6a feat: reject duplicate sign-up emails` and `npm test` → `42 passed`, and one `transitionJiraIssue` on PA-31 with transition `41`
- No `record` call and no MCP write on PA-30, PA-32 or any Story or Epic (PA-10, PA-13, PA-16)
- No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`
- The agent shows the passing output and a diff summary, and names PA-32 as the next ready Sub-task
