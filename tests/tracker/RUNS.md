# Scenario runs

Each row is one dry run, graded against the scenario's **Then**. A run counts only if every line is ✅.

| Date | Scenario | Ticket | Result | Notes |
|---|---|---|---|---|
| 2026-11-24 | 01-unknown-adapter-stops | 01 | ✅ 6/6 | Stopped at selection before build.md was opened; recommended `/power-architect:setup-tracker linear`; no fallback; no Tracker operations |
| 2026-11-24 | 02-no-tracker-section-unchanged | 01 | ✅ 4/4 | tracker.md never opened; worktree setup and then ticket 03 read, as today; no Tracker operations |

Locality check (`jira\|rovo\|mcp__\|atlassian\|confluence\|ADF` outside `tracker-jira.md`): ✅ no matches (2026-11-24, ticket 01).
