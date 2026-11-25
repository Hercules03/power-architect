# 68: When the work list can't be pulled, build stops before any setup and builds nothing

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
  - Today is 2026-11-25. `.power-architect/2026-11-24-login-lockout/progress.md` exists: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, the `## Work Refs` table (Spec Page, Story PA-50, Sub-tasks PA-60, PA-61, PA-62), and no `Task` line.
  - `docs/plans/2026-10-01-login-lockout.md` exists: an older local plan written before the repo entered Jira Mode.
  - The agent is on branch `main` in the main checkout (not a linked worktree).

## When
The user runs `/power-architect:build` with no argument.

## Then
- The agent reads the `## Tracker` section, opens `references/tracker.md`, then `references/tracker-jira.md`, and the config check passes
- The agent calls `pull(sprint, subtask)`. Its MCP calls: only the connection check (`atlassianUserInfo`, possibly through `discover`), which returns UNREACHABLE. No further MCP call
- The agent stops the phase and tells the user the Tracker (Jira) can't be reached, so nothing was built, and to re-run `/power-architect:build` once it is reachable (`/mcp` reconnects)
- No workspace setup: no worktree is created, no dependency install and no baseline test run
- Nothing is built: no task brief, no implementer dispatched, no `record` call, and the ledger is unchanged
- The agent never opens `docs/plans/2026-10-01-login-lockout.md` and never falls back to Local Files
- No Sprint or board call of any kind
