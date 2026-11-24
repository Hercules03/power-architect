# 54b: With no Spec Page to read, plan stops and recommends to-spec instead of planning from a local file

**Phase:** /power-architect:plan

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
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |

- Ledger / local files:
  - Today is 2026-11-24. There is no `.power-architect/` directory.
  - `docs/specs/2026-10-01-onboarding.md` exists: a local spec written before the repo entered Jira Mode. It was never published.
  - Conversation so far: none. The user asks to plan the onboarding work.

## When
The user runs `/power-architect:plan` and replies in order:
1. if asked for the Spec Page's Work Ref or URL: "I don't have one."

## Then
- The agent reads the `## Tracker` section, opens `references/tracker.md`, then `references/tracker-jira.md`, and the config check passes
- No ledger names a Spec Page, so the agent asks the user for the Spec Page's Work Ref or URL (or stops at once)
- The agent stops the phase and tells the user there is no published spec to plan from, and recommends `/power-architect:to-spec`
- No Tracker operation is made (no `pull`, no `publish`) and no MCP write call; the agent makes no `searchConfluence` or other spec lookup of its own
- The agent never opens `docs/specs/2026-10-01-onboarding.md`, never plans from it, and never falls back to Local Files
- Nothing is written: nothing under `.power-architect/` and nothing under `docs/plans/`
