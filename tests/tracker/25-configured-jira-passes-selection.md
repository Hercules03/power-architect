# 25: The section setup writes passes the contract's selection check

**Phase:** /power-architect:build 03

## Given
- Repo instructions file (AGENTS.md): the section that scenario 24 writes, verbatim:
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
  status-done: Done
  link-blocks: Blocks
  link-relates: Relates
  ```
- Tracker state: stubbed Rovo table:

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | * | any | error: not stubbed |

- Ledger / local files: an approved Large-tier spec in `docs/specs/2026-01-01-demo.md` and tickets `01`–`05` under `docs/plans/2026-01-01-demo/`

## When
The user runs `/power-architect:build 03`.

## Then
- The agent reads the `## Tracker` section before doing any work in the phase
- The agent opens the Tracker contract (`references/tracker.md`), then the Jira Tracker Adapter (`references/tracker-jira.md`)
- The adapter's config check passes: the agent finds every required key present
- Selection does not stop the phase: the agent does not say the section is incomplete or names an unknown adapter, and does not recommend `/power-architect:setup-tracker`
- No MCP call is made as part of the selection or config check
- No Sprint or board is created or changed (no `manageJiraSprint`, no `createJiraBoard`)
