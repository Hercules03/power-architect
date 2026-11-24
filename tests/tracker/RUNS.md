# Scenario runs

Each row is one dry run, graded against the scenario's **Then**. A run counts only if every line is ✅.

| Date | Scenario | Ticket | Result | Notes |
|---|---|---|---|---|
| 2026-11-24 | 01-unknown-adapter-stops | 01 | ✅ 6/6 | Stopped at selection before build.md was opened; recommended `/power-architect:setup-tracker linear`; no fallback; no Tracker operations |
| 2026-11-24 | 02-no-tracker-section-unchanged | 01 | ✅ 4/4 | tracker.md never opened; worktree setup and then ticket 03 read, as today; no Tracker operations |
| 2026-11-24 | 20-setup-unknown-tracker-stops | 02 | ✅ 5/5 | graded by the ticket-02 task reviewer from a fresh dry-run trace |
| 2026-11-24 | 21-setup-rovo-not-connected | 02 | ✅ 5/5 | graded by the ticket-02 task reviewer from a fresh dry-run trace |
| 2026-11-24 | 22-setup-team-managed-issue-types | 02 | ✅ 6/6 | graded by the ticket-02 task reviewer from a fresh dry-run trace |
| 2026-11-24 | 23-setup-custom-workflow-mapping-confirmed | 02 | ✅ 5/5 | graded by the ticket-02 task reviewer from a fresh dry-run trace |
| 2026-11-24 | 24-setup-happy-path-writes-section | 02 | ✅ 7/7 | graded by the ticket-02 task reviewer from a fresh dry-run trace |
| 2026-11-24 | 25-configured-jira-passes-selection | 02 | ✅ 6/6 | graded by the ticket-02 task reviewer from a fresh dry-run trace |
| 2026-11-24 | 26-setup-rerun-updates-in-place | 02 | ✅ 5/5 | graded by the ticket-02 task reviewer from a fresh dry-run trace |
| 2026-11-24 | 30-to-spec-large-publishes-backlog | 03 | ✅ 14/14 | graded by the ticket-03 task reviewer from a fresh dry-run trace |
| 2026-11-24 | 31-to-spec-small-one-story | 03 | ✅ 10/10 | graded by the ticket-03 task reviewer from a fresh dry-run trace |
| 2026-11-24 | 32-to-spec-nothing-before-gate | 03 | ✅ 6/6 | graded by the ticket-03 task reviewer from a fresh dry-run trace |
| 2026-11-24 | 33-to-spec-unreachable-stops | 03 | ✅ 6/6 | graded by the ticket-03 task reviewer from a fresh dry-run trace |
| 2026-11-24 | 34-to-spec-partial-failure-reported | 03 | ✅ 5/5 (after fixing the scenario's own call-sequence line; behaviour was right) | graded by the ticket-03 task reviewer from a fresh dry-run trace |
| 2026-11-24 | 35-to-spec-local-mode-unchanged | 03 | ✅ 8/8 | graded by the ticket-03 task reviewer from a fresh dry-run trace |
| 2026-11-24 | 36-to-spec-grouping-edited-at-gate | 03 | ✅ 6/6 | graded by the ticket-03 task reviewer from a fresh dry-run trace |

Locality check (`jira\|rovo\|mcp__\|atlassian\|confluence\|ADF` outside `tracker-jira.md`): ✅ no matches (2026-11-24, ticket 01).
Locality check re-run at ticket 02 (head b3f6ccf): ✅ no matches.
Locality check re-run at ticket 03 (head 8df444b): ✅ no matches.
