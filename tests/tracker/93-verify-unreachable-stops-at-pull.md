# 93: verify stops at pull and writes nothing when Jira can't be reached

**Phase:** /power-architect:verify

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
- Tracker state: stubbed Rovo table. Every tool, including `atlassianUserInfo`, returns UNREACHABLE.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | * | any | UNREACHABLE |
- Items:
  - PA-5 Epic "Account security" (To Do); PA-70 Bug "Lockout counter is off by one" (To Do, no parent, Backlog).
  - PA-50 Story "Lock out repeated failed logins" (In Progress, parent PA-5): `## Acceptance Criteria` has two lines: `- [ ] The sixth login attempt within 10 minutes after five failures returns 423.` and `- [ ] A locked account unlocks after 15 minutes.`.
  - PA-60 Sub-task "Failed-login counter" (Done, parent PA-50); PA-61 Sub-task "Login handler enforces the lockout" (Done, parent PA-50).
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists in the repo checkout: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table (Spec Page, Epic PA-5, the Stories and Sub-tasks of the Items list), `Task PA-60: complete (commits a1b2c3d..a1b2c3d, review clean, tests: npx vitest run tests/auth/attempts.test.ts → 2 passed)` and `Task PA-61: complete (commits b2c3d4e..b2c3d4e, review clean, tests: npx vitest run tests/auth/login.test.ts → 3 passed)`. No `## Tracker queue` section. No local spec file exists under `docs/`.
  - The agent is in the repo checkout on branch `feat/login-lockout`.
- Trace: report Tracker operations, MCP calls, shell commands and ledger writes in one chronological list.

## When
The user runs the phase.

## Then
- The first `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001, story)` Rovo call (`atlassianUserInfo`) returns UNREACHABLE, so `pull` stops and verify stops with it
- The agent tells the user Jira can't be reached, that nothing was verified, and that nothing was written to the Tracker, and recommends reconnecting (`/mcp`) and re-running `/power-architect:verify`
- No Rovo call is made after the first UNREACHABLE: no retry, no read, no write. No `addOrEditJiraIssueComment` or `transitionJiraIssue`
- No proving command, `npm test`, typecheck or lint is run, and no criterion is checked
- No ledger line and no `## Tracker queue` entry is written (a failed `pull` queues nothing)
- The agent never says any Story is verified or Done, and does not recommend `/power-architect:finish`
- It does not fall back to a local spec file or to reading the spec from `docs/`
