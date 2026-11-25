# 02: With no `## Tracker` section, a phase reads nothing new

**Phase:** /power-architect:build 03

## Given
- Repo instructions file (AGENTS.md): exists, with no `## Tracker` section
- Tracker state: none
- Ledger / local files: an approved Large-tier spec in `docs/specs/2026-01-01-demo.md` and tickets `01`–`05` under `docs/plans/2026-01-01-demo/`; tickets 01 and 02 are done; ticket 03's title is "Sign-up rejects a duplicate email"
- Git state: a clean linked worktree on a feature branch

## When
The user runs `/power-architect:build 03`.

## Then
- The agent checks for a `## Tracker` section, finds none, and uses Local Files
- The agent never opens the Tracker contract (`references/tracker.md`) or any Tracker Adapter (`references/tracker-*.md`)
- The agent proceeds as the build phase does today: worktree setup, then reads ticket `03` from `docs/plans/2026-01-01-demo/` and states its title
- No Tracker operation (publish / pull / record) is attempted
