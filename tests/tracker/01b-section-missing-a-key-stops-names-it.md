# 01b: A `## Tracker` section for `jira` that is missing `status-done` stops the phase, names the key, and recommends setup

**Phase:** /power-architect:build 03

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
  status-in-progress: In Progress
  link-blocks: Blocks
  link-relates: Relates
  ```
  (no `status-done` line)
- Tracker state: none needed. The config check makes no MCP call, so no Rovo row is ever reached.
- Ledger / local files: an approved spec in `docs/specs/` and tickets `01`–`05` under `docs/plans/2026-01-01-demo/`

## When
The user runs `/power-architect:build 03`.

## Then
- The agent reads the `## Tracker` section before doing any work in the phase
- The agent opens the Tracker contract (`references/tracker.md`) and the adapter it names (`references/tracker-jira.md`), and runs that adapter's config check
- The config check finds that `status-done` is missing (every other key is present, and `adapter` is `jira`), so the agent stops the phase before reading the ticket or creating a worktree
- The agent tells the user that the `## Tracker` section is missing `status-done`, names that key, and recommends `/power-architect:setup-tracker jira`
- The agent does not run the adapter's Install section or any Setup step, and writes no file
- It does not fall back to Local Files on its own
- No MCP call of any kind is made, and no Tracker operation (publish / pull / record) is attempted
