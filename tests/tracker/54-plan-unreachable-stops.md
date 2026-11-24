# 54: When the Tracker can't be reached, plan stops before drafting and writes nothing

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
  | * | any | UNREACHABLE |

- Ledger / local files:
  - Today is 2026-11-24. `.power-architect/2026-11-24-onboarding/progress.md` exists. Its first line is `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001`, followed by a `## Work Refs` table with 12 rows (the Spec Page, Epics E1–E3 as PA-10 … PA-12, Stories 1–8 as PA-13 … PA-20).
  - `docs/specs/2026-10-01-onboarding.md` exists: an older local spec written before the repo entered Jira Mode.
  - Conversation so far: none. The user asks to plan the onboarding spec.

## When
The user runs `/power-architect:plan`.

## Then
- The agent reads the `## Tracker` section, opens `references/tracker.md`, then `references/tracker-jira.md`, and the config check passes
- The agent finds the Spec Page from the ledger's first line and calls `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001, outline)` before drafting anything
- The MCP calls: only the connection check (`atlassianUserInfo`, possibly through `discover`), which returns UNREACHABLE. No further MCP call
- The agent stops the phase and tells the user the Tracker (Jira) can't be reached, so no plan was made or published, and to re-run `/power-architect:plan` once it is reachable (`/mcp` reconnects)
- No quiz or plan is shown. Nothing is written: no `tickets-draft.md` or `plan-draft.md`, nothing under `docs/plans/`, and the ledger is unchanged
- The agent never opens `docs/specs/2026-10-01-onboarding.md` and never falls back to Local Files
- No `publish` call; no Sprint or board call
