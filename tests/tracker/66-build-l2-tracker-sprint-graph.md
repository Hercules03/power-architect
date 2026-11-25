# 66: `/build` on a Sprint of Large Sub-tasks runs L2: the frontier comes from "blocks" links, started before each dispatch, ledger line after each merge, done only after the final review

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
  | getJiraBoardSprintData | boardId 12 | {board: {id: 12}, sprint: {id: 7, name: "Sprint 7", state: "active"}, issues: [{key: "PA-13", type: "Story"}, {key: "PA-16", type: "Story"}, {key: "PA-18", type: "Story"}, {key: "PA-34", type: "Sub-task", status: "To Do"}, {key: "PA-33", type: "Sub-task", status: "To Do"}, {key: "PA-32", type: "Sub-task", status: "To Do"}, {key: "PA-31", type: "Sub-task", status: "To Do"}, {key: "PA-30", type: "Sub-task", status: "To Do"}]} |
  | getConfluenceContent | page 4001 | {id: "4001", title: "Self-serve onboarding", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001", body (Markdown): the shared context of "Self-serve onboarding" (a Scope Tier section reading `Large`), then a `## Plan` section with the table `\| ticket \| title \| Blocked by \|` (01 None; 02 01; 03 01; 04 03; 05 04), then the key table: `spec`, `E1 \| Epic \| PA-10`, `E2 \| Epic \| PA-11`, `E3 \| Epic \| PA-12`, `1 \| Story \| PA-13`, `4 \| Story \| PA-16`, `6 \| Story \| PA-18`, `01 \| Sub-task \| PA-30`, `02 \| Sub-task \| PA-31`, `03 \| Sub-task \| PA-32`, `04 \| Sub-task \| PA-33`, `05 \| Sub-task \| PA-34`} |
  | getJiraIssue | PA-10, PA-11, PA-12 | an Epic, status To Do |
  | getJiraIssue | PA-13, PA-16, PA-18 | a Story, status To Do, with its user-story sentence, `## Acceptance Criteria` with one `- [ ]` line, and the Spec Page line |
  | getJiraIssue | PA-30 … PA-34 | that item's row of the Items table below, with its current status (after a transition by this dry run, the new status); each description holds its What to build, `## Acceptance criteria`, a `Blocked by:` line and `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001` |
  | listJiraIssueTransitions | an issue in To Do | [{id: "21", name: "Start work", to: "In Progress"}, {id: "41", name: "Close", to: "Done"}] |
  | listJiraIssueTransitions | an issue in In Progress | [{id: "31", name: "Send to review", to: "In Review"}, {id: "41", name: "Close", to: "Done"}, {id: "11", name: "Stop work", to: "To Do"}] |
  | transitionJiraIssue | any | {ok: true}; the issue's status becomes the transition's `to`. Live input schema: `cloudId`, `issueIdOrKey`, `transitionId`, `transitionName`, `fields`, `sprintId`, `assignToBacklog`, `boardId` |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |

  Items:

  | Key | summary | status | parent | links |
  |---|---|---|---|---|
  | PA-30 | Email sign-up creates an account | To Do | PA-13 | blocks PA-31, blocks PA-32 |
  | PA-31 | Sign-up rejects a duplicate email | To Do | PA-13 | is blocked by PA-30 |
  | PA-32 | Create an organization at sign-up | To Do | PA-16 | is blocked by PA-30; blocks PA-33 |
  | PA-33 | Start a trial without a card | To Do | PA-18 | is blocked by PA-32; blocks PA-34 |
  | PA-34 | Trial expiry locks the workspace | To Do | PA-18 | is blocked by PA-33 |
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-onboarding/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001`, then the `## Work Refs` table. No `Task` line. There is no `docs/specs/` or `docs/plans/` file for this spec.
  - The agent is already in a linked worktree on branch `feat/onboarding`. The baseline suite `npm test` passes.
- Execution outcomes (take as given; dispatching a subagent is described, not performed; run implementers one finish at a time in the trace, in the order they are started): every implementer reports DONE; every merger merges cleanly into the integration branch; the final review method's single fix implementer finds nothing to fix. Each ticket's work merges as one commit, with `npm test` → `45 passed`: PA-30 `f0f0f01 feat: email sign-up`, PA-31 `f0f0f02 feat: reject duplicate emails`, PA-32 `f0f0f03 feat: org at sign-up`, PA-33 `f0f0f04 feat: trial without a card`, PA-34 `f0f0f05 feat: trial expiry lock`.
- Trace: report dispatches, merges, ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:build` with no argument.

## Then
- `pull(sprint, subtask)` returns PA-30, PA-31, PA-32, PA-33, PA-34 in that order, each with tier Large and the Spec Page `https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001`; nothing is reported blocked
- The agent follows L2 (the whole graph) and calls `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001, outline)` before the first dispatch. Nothing under `docs/specs/` or `docs/plans/` is read
- The first frontier is PA-30 alone. `record(PA-30, started)` (transition `21` on PA-30) comes before PA-30's implementer dispatch, and no other Sub-task is started before PA-30's merge
- Each Sub-task's `record(<key>, started)` comes just before its own implementer dispatch, and only after every one of its blockers has been merged and has its ledger line (the blocker is still In Progress, since no `done` is sent yet): PA-31 and PA-32 after PA-30's merge and ledger line, PA-33 after PA-32's, PA-34 after PA-33's
- For each Sub-task, after the merger merges it into the integration branch: a ledger line `Task <key>: complete (…)` naming its commit, with no `record(done)` yet. After every Sub-task is merged, the integration-branch review runs and its one fix pass; then the ledger line `Final review: passed (spec https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001)` is written, then `record(<key>, done, …)` for each of the five, each with one `addOrEditJiraIssueComment` on it (first line `Done`, its commit and `npm test` → `45 passed` in a fenced code block) and one `transitionJiraIssue` with transition `41`. No transition `41` and no `Done` comment comes before that review
- After those five `record(done)` calls, no further Tracker write: no transition, comment or edit on any Story or Epic (PA-10 … PA-18)
- No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call, and no `transitionJiraIssue` passes `sprintId`, `assignToBacklog`, `boardId` or `fields`
