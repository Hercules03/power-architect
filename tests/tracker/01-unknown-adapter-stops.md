# 01: A `## Tracker` section naming an unknown adapter stops the phase

**Phase:** /power-architect:build 03

## Given
- Repo instructions file (AGENTS.md):
  ```md
  ## Tracker
  adapter: linear
  ```
- Tracker state: none (no `tracker-linear.md` exists in the skill)
- Ledger / local files: an approved spec in `docs/specs/` and tickets `01`–`05` under `docs/plans/2026-01-01-demo/`

## When
The user runs `/power-architect:build 03`.

## Then
- The agent reads the `## Tracker` section before doing any work in the phase
- The agent opens the Tracker contract (`references/tracker.md`)
- The agent finds that no Tracker Adapter named `linear` exists, and stops the phase before reading the ticket or creating a worktree
- The agent tells the user that the `## Tracker` section names an unknown adapter (`linear`), and recommends `/power-architect:setup-tracker <name>`
- It does not fall back to Local Files on its own
- No Tracker operation (publish / pull / record) is attempted
