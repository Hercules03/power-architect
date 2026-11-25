# 114: A re-run with two specs whose Done was withheld, and one user fix commit for each, asks which spec each uncovered commit belongs to before any write

**Phase:** /power-architect:build

## Given
- Repo instructions file (AGENTS.md), Tracker state and sprint: as in scenario 113, except that PA-81 is not in the sprint: the work list is PA-60, PA-61 (spec A, page 6001) and PA-82 (spec B, page 7001), all In Progress.
- Ledger / local files:
  - Today is 2026-11-26. Spec A's ledger `.power-architect/2026-11-24-login-lockout/progress.md`: `Task PA-60` (`a1b2c3d..a1b2c3d`, S2), `Task PA-61` (`b2c3d4e..b2c3d4e`, S2), no `Fix` line, no `Final review: passed` line. Spec B's ledger `.power-architect/2026-11-20-password-reset/progress.md`: `Task PA-82` (`9a8b7c6..9a8b7c6`, S2), no `Fix` line, no `Final review: passed` line.
  - Branch `feat/sprint-7` history: `a1b2c3d`, `b2c3d4e` (spec A), `9a8b7c6` (spec B), then `d5e6f7a fix: reset the counter when the lockout expires` and `e6f7a8b fix: expire reset tokens` (the user's fixes, named by no ledger, no Bug commits).
- Execution outcomes (take as given): the user, asked which spec each uncovered commit belongs to, answers: `d5e6f7a` is spec A's, `e6f7a8b` is spec B's. Both final reviews find nothing Critical or Important.
- Trace: report ledger writes, questions to the user, later-commit computation, final-review diff commands and Tracker operations in one chronological list.

## When
The user runs `/power-architect:build` with no argument.

## Then
- Both specs lack a `Final review: passed` line and uncovered commits exist, so the agent lists `d5e6f7a` and `e6f7a8b` and asks the user which spec each belongs to. The question comes before any ledger write, any `record` call and any review diff; it does not give both commits to spec A on its own
- After the answer no further question is asked about them. Spec A's ledger gets `Fix (spec https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001): commits d5e6f7a..d5e6f7a` and spec B's ledger gets `Fix (spec https://acme.atlassian.net/wiki/spaces/PASPEC/pages/7001): commits e6f7a8b..e6f7a8b`; neither ledger holds the other's commit
- Spec A's review diff is the union of `a1b2c3d`, `b2c3d4e` and `d5e6f7a` only; spec B's is the union of `9a8b7c6` and `e6f7a8b` only
- `record(PA-60, done, …)` and `record(PA-61, done, …)` list `a1b2c3d` / `b2c3d4e` respectively, then `d5e6f7a`, and not `e6f7a8b`; `record(PA-82, done, …)` lists `9a8b7c6`, then `e6f7a8b`, and not `d5e6f7a`
- No MCP write on PA-50 or PA-80. No Sprint or board write: no `manageJiraSprint` or `createJiraBoard` call.
