# 20: `setup-tracker` for a tracker with no adapter stops and writes nothing

**Phase:** /power-architect:setup-tracker linear

## Given
- Repo instructions file (AGENTS.md): exists, with no `## Tracker` section
- Tracker state: none. The skill has no `tracker-linear.md`; the only Tracker Adapter is `tracker-jira.md`
- Ledger / local files: none relevant

## When
The user runs `/power-architect:setup-tracker linear`.

## Then
- The agent opens the Tracker contract (`references/tracker.md`)
- The agent finds that no Tracker Adapter named `linear` exists (no `tracker-linear.md`)
- The agent stops and tells the user there is no adapter named `linear`, naming the adapters that do exist (`jira`)
- No Install section is run, and no MCP call is made
- No file is written: AGENTS.md is unchanged and no CLAUDE.md is created
