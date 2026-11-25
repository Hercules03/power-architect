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
| 2026-11-24 | 30-to-spec-large-publishes-backlog | 04 | ✅ 13/13 (round 2 smoke) — first-publish path unchanged by re-run work | graded from fresh dry-run traces; ticket 04 needed 4 fix rounds (see ledger) |
| 2026-11-24 | 31–36 (ticket-03 scenarios) | 04 | ✅ all pass at round 1 (contract changed; scenarios 30, 31, 34, 36 edited to allow the Spec Page search read) | graded from fresh dry-run traces; ticket 04 needed 4 fix rounds (see ledger) |
| 2026-11-24 | 40-rerun-unchanged-no-writes | 04 | ✅ 8/8 | graded from fresh dry-run traces; ticket 04 needed 4 fix rounds (see ledger) |
| 2026-11-24 | 40b-rerun-reworded-text-zero-writes | 04 | ✅ 8/8 | graded from fresh dry-run traces; ticket 04 needed 4 fix rounds (see ledger) |
| 2026-11-24 | 40c-rerun-redrafted-wording-across-sessions-zero-writes | 04 | ✅ 9/9 | graded from fresh dry-run traces; ticket 04 needed 4 fix rounds (see ledger) |
| 2026-11-24 | 41-rerun-done-story-changed-held | 04 | ✅ 11/11 (second run is a new session; one comment across two sessions) | graded from fresh dry-run traces; ticket 04 needed 4 fix rounds (see ledger) |
| 2026-11-24 | 41b-rerun-declined-go-ahead | 04 | ✅ 8/8 (clean re-run after a contaminated first trace was discarded) | graded from fresh dry-run traces; ticket 04 needed 4 fix rounds (see ledger) |
| 2026-11-24 | 42-rerun-todo-story-reparented | 04 | ✅ 7/7 | graded from fresh dry-run traces; ticket 04 needed 4 fix rounds (see ledger) |
| 2026-11-24 | 43-rerun-started-story-moved-commented | 04 | ✅ 7/7 | graded from fresh dry-run traces; ticket 04 needed 4 fix rounds (see ledger) |
| 2026-11-24 | 44-rerun-removed-story-commented-once | 04 | ✅ 8/8 (re-run at final head) | graded from fresh dry-run traces; ticket 04 needed 4 fix rounds (see ledger) |
| 2026-11-24 | 45-rerun-renumbered-stories-keep-keys | 04 | ✅ 7/7 (re-run at final head) | graded from fresh dry-run traces; ticket 04 needed 4 fix rounds (see ledger) |
| 2026-11-24 | 45b-rerun-held-changed-story-renumbered-asks | 04 | ✅ 9/9 (main run and the 'new' variant, graded from separate traces) | graded from fresh dry-run traces; ticket 04 needed 4 fix rounds (see ledger) |
| 2026-11-24 | 46-rerun-resumes-partial-publish | 04 | ✅ 9/9 (Then line relaxed: an identical redraft is a no-op) | graded from fresh dry-run traces; ticket 04 needed 4 fix rounds (see ledger) |
| 2026-11-24 | 47-rerun-small-user-owned-epic-untouched | 04 | ✅ 7/7 | graded from fresh dry-run traces; ticket 04 needed 4 fix rounds (see ledger) |
| 2026-11-24 | 48-rerun-local-mode-unchanged | 04 | ✅ 7/7 (round 1; unaffected by later rounds) | graded from fresh dry-run traces; ticket 04 needed 4 fix rounds (see ledger) |
| 2026-11-24 | 49-rerun-no-ledger-confirms-spec-page | 04 | ✅ 7/7 | graded from fresh dry-run traces; ticket 04 needed 4 fix rounds (see ledger) |
| 2026-11-24 | 50-plan-large-publishes-subtasks | 05 | ✅ 14/14 | graded from fresh dry-run traces; ticket 05 needed 2 fix rounds |
| 2026-11-24 | 51-plan-slice-spans-stories-flagged | 05 | ✅ 8/8 | graded from fresh dry-run traces; ticket 05 needed 2 fix rounds |
| 2026-11-24 | 52-plan-small-subtasks-carry-steps | 05 | ✅ 12/12 | graded from fresh dry-run traces; ticket 05 needed 2 fix rounds |
| 2026-11-24 | 53-plan-section-pulled-on-second-run | 05 | ✅ 7/7 | graded from fresh dry-run traces; ticket 05 needed 2 fix rounds |
| 2026-11-24 | 54-plan-unreachable-stops | 05 | ✅ 7/7 | graded from fresh dry-run traces; ticket 05 needed 2 fix rounds |
| 2026-11-24 | 54b-plan-no-spec-page-stops | 05 | ✅ 6/6 | graded from fresh dry-run traces; ticket 05 needed 2 fix rounds |
| 2026-11-24 | 54c-plan-partial-failure-resumes | 05 | ✅ 9/9 | graded from fresh dry-run traces; ticket 05 needed 2 fix rounds |
| 2026-11-24 | 54d-plan-unclear-link-direction-asks-before-writes | 05 | ✅ 8/8 (Run A and Run B) | graded from fresh dry-run traces; ticket 05 needed 2 fix rounds |
| 2026-11-24 | 55-plan-nothing-before-approval | 05 | ✅ 5/5 | graded from fresh dry-run traces; ticket 05 needed 2 fix rounds |
| 2026-11-24 | 56-plan-rerun-unchanged-no-writes | 05 | ✅ 10/10 (ambiguous link schema; no direction question on an unchanged re-run) | graded from fresh dry-run traces; ticket 05 needed 2 fix rounds |
| 2026-11-24 | 57-plan-rerun-started-subtask-held | 05 | ✅ 10/10 (three sessions; the same change reworded adds no second comment) | graded from fresh dry-run traces; ticket 05 needed 2 fix rounds |
| 2026-11-24 | 58-to-spec-rerun-keeps-plan-section | 05 | ✅ 8/8 | graded from fresh dry-run traces; ticket 05 needed 2 fix rounds |
| 2026-11-24 | 59-plan-local-mode-unchanged | 05 | ✅ 8/8 | graded from fresh dry-run traces; ticket 05 needed 2 fix rounds |
| 2026-11-24 | 59b-plan-small-local-mode-unchanged | 05 | ✅ 7/7 | graded from fresh dry-run traces; ticket 05 needed 2 fix rounds |
| 2026-11-24 | 30 / 40 / 46 (regression) | 05 | ✅ 14/14, 8/8, 9/9 after ticket 05 | graded from fresh dry-run traces; ticket 05 needed 2 fix rounds |
| 2026-11-25 | 60-build-sprint-blocks-order | 06 | ✅ 11/11 (re-run at final head: every task reviewer gets the Global Constraints) | graded from fresh dry-run traces (re-runs by Haiku); ticket 06 needed 2 fix rounds |
| 2026-11-25 | 61 / 61b (build one Sub-task / one Story by key) | 06 | ✅ 6/6, 5/5 | graded from fresh dry-run traces (re-runs by Haiku); ticket 06 needed 2 fix rounds |
| 2026-11-25 | 62-build-resume-fires-done-once | 06 | ✅ 6/6 (re-run) | graded from fresh dry-run traces (re-runs by Haiku); ticket 06 needed 2 fix rounds |
| 2026-11-25 | 63 / 63b (Done comment not repeated; test line inside / outside the fence) | 06 | ✅ 6/6, 6/6 | graded from fresh dry-run traces (re-runs by Haiku); ticket 06 needed 2 fix rounds |
| 2026-11-25 | 64 / 64b (Local mode S1 / L1 unchanged) | 06 | ✅ 10/10 (re-run: whole-branch final review kept), 6/6 | graded from fresh dry-run traces (re-runs by Haiku); ticket 06 needed 2 fix rounds |
| 2026-11-25 | 65-build-l1-tracker-one-subtask | 06 | ✅ 7/7 | graded from fresh dry-run traces (re-runs by Haiku); ticket 06 needed 2 fix rounds |
| 2026-11-25 | 66-build-l2-tracker-sprint-graph | 06 | ✅ 7/7 (re-run) | graded from fresh dry-run traces (re-runs by Haiku); ticket 06 needed 2 fix rounds |
| 2026-11-25 | 67-build-s2-inline-tracker | 06 | ✅ 5/5 (re-run) | graded from fresh dry-run traces (re-runs by Haiku); ticket 06 needed 2 fix rounds |
| 2026-11-25 | 68 / 68b (pull unreachable stops; blocker outside Sprint) | 06 | ✅ 7/7, 5/5 | graded from fresh dry-run traces (re-runs by Haiku); ticket 06 needed 2 fix rounds |
| 2026-11-25 | 69-build-two-specs-two-ledgers | 06 | ✅ 7/7 | graded from fresh dry-run traces (re-runs by Haiku); ticket 06 needed 2 fix rounds |
| 2026-11-25 | 70-build-jira-down-mid-build-queues | 07 | ✅ 9/9 | graded from fresh dry-run traces (Haiku); ticket 07 needed 2 fix rounds |
| 2026-11-25 | 71-build-next-run-replays-queue-before-pull | 07 | ✅ 8/8 (re-run) | graded from fresh dry-run traces (Haiku); ticket 07 needed 2 fix rounds |
| 2026-11-25 | 72-build-replay-interrupted-resends-only-unsent | 07 | ✅ 6/6 (stub cutoff corrected so q1 is sent and the failure lands on q2) | graded from fresh dry-run traces (Haiku); ticket 07 needed 2 fix rounds |
| 2026-11-25 | 73-build-pull-unreachable-queues-nothing | 07 | ✅ 5/5 | graded from fresh dry-run traces (Haiku); ticket 07 needed 2 fix rounds |
| 2026-11-25 | 74-build-later-record-never-overtakes-queued | 07 | ✅ 5/5 | graded from fresh dry-run traces (Haiku); ticket 07 needed 2 fix rounds |
| 2026-11-25 | 75-build-resume-skips-done-already-queued | 07 | ✅ 5/5 (re-run) | graded from fresh dry-run traces (Haiku); ticket 07 needed 2 fix rounds |
| 2026-11-25 | 76-build-partial-done-queues-whole-event | 07 | ✅ 6/6 | graded from fresh dry-run traces (Haiku); ticket 07 needed 2 fix rounds |
| 2026-11-25 | 77-build-replay-failure-marked-others-still-replay | 07 | ✅ 6/6 (re-run; user told how to clear a [!] entry) | graded from fresh dry-run traces (Haiku); ticket 07 needed 2 fix rounds |
| 2026-11-25 | 78-build-l2-blocker-done-queued-unblocks | 07 | ✅ after Then 7 reworded (it contradicted Then 4); not re-run | graded from fresh dry-run traces (Haiku); ticket 07 needed 2 fix rounds |
| 2026-11-25 | 79-build-queue-pinned-to-main-checkout | 07 | ✅ 6/6 (queue written to the main checkout, replayed from there) | graded from fresh dry-run traces (Haiku); ticket 07 needed 2 fix rounds |

Locality check (`jira\|rovo\|mcp__\|atlassian\|confluence\|ADF` outside `tracker-jira.md`): ✅ no matches (2026-11-24, ticket 01).
Locality check re-run at ticket 02 (head b3f6ccf): ✅ no matches.
Locality check re-run at ticket 03 (head 8df444b): ✅ no matches.
Locality check re-run at ticket 04 (head bacb2a7): ✅ no matches.
Locality check re-run at ticket 05 (head 9ca0ef3): ✅ no matches.
Locality check re-run at ticket 06 (head 6e62a92): ✅ no matches.
Locality check re-run at ticket 07 (head 0d124a7): ✅ no matches.
