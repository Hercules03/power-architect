# 73: When build starts while Jira is unreachable, `pull` stops, nothing is built and nothing is queued

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
- Tracker state: stubbed Rovo table.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | * | any | UNREACHABLE |

- Ledger / local files:
  - Today is 2026-11-26. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table (Spec Page, Story PA-50, Sub-tasks PA-60, PA-61), and
    ```md
    ## Tracker queue
    - [ ] q1 | done | PA-60 | a1b2c3d feat: count failed logins\ntests: npx vitest run tests/auth/attempts.test.ts → 2 passed
    ```
  - `docs/plans/2026-10-01-login-lockout.md` exists: an older local plan. The agent is on branch `main` in the main checkout.

## When
The user runs `/power-architect:build` with no argument.

## Then
- The agent calls `pull(sprint, subtask)`. Its only MCP call is the connection check (`atlassianUserInfo`, possibly through `discover`), which returns UNREACHABLE. No further MCP call, and no replay write
- The agent stops the phase and tells the user Jira can't be reached, so nothing was built, and to re-run `/power-architect:build` once it is reachable
- Nothing is queued: the ledger is unchanged, with q1 still `- [ ]` and no q2. No `record` call of any kind
- No workspace setup (no worktree, no install, no baseline run), no brief, no implementer
- The agent never opens `docs/plans/2026-10-01-login-lockout.md` and never falls back to Local Files
