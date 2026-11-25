# 06: build runs the Sprint

**What to build:** In Jira Mode, `/power-architect:build` with no argument pulls the active Sprint's unfinished Sub-tasks in "blocks" order. `/build <key>` builds a single Story or Sub-task.
- For each item, `record(started)` moves it to In Progress before an implementer is dispatched.
- After its review passes, the ledger completion line is written first, then `record(done, evidence)` moves it to Done with a comment giving the commits or PR and the test evidence.
- The ledger is keyed by the spec's slug, and its first line names the Spec Page's Work Ref.
- Reviewers read the spec and plan through `pull(spec, outline)`.
- This holds for the S1, S2, L1 and L2 paths.
- The agent never creates, starts, closes or edits a Sprint.

**Blocked by:** 05

**Status:** done

- [x] Scenario: three Sub-tasks with "blocks" links are built in the right order, each with started, then review, then the ledger line, then done
- [x] Scenario: `/build <key>` builds only that item
- [x] Scenario: resuming after a crash between the ledger line and `done` fires `done` once and does not rebuild
- [x] Scenario: no Sprint operation appears in any build trace
- [x] The done comment carries the commits or PR and the test evidence
- [x] Local-mode regression and the locality grep check pass
