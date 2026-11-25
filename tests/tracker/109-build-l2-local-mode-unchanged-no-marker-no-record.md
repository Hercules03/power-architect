# 109: With no `## Tracker` section, `/build all` runs L2 as before: no ledger line, no review marker, no Tracker call, and the review then one fix pass

**Phase:** /power-architect:build all

## Given
- Repo instructions file (AGENTS.md): exists, with no `## Tracker` section
- Tracker state: none
- Ledger / local files:
  - Today is 2026-11-25. There is no `.power-architect/` directory. `docs/specs/2026-11-24-onboarding.md` exists: the approved spec "Self-serve onboarding", Scope Tier Large. `docs/plans/2026-11-24-onboarding/` holds tickets `01-email-sign-up.md` (no blocker), `02-duplicate-email-rejected.md` (**Blocked by:** 01) and `03-org-at-sign-up.md` (**Blocked by:** 02), each **Status:** ready-for-agent.
  - The agent is already in a linked worktree on branch `feat/onboarding`. The baseline suite `npm test` passes.
- Execution outcomes (take as given; dispatching a subagent is described, not performed): every implementer reports DONE and every merger merges cleanly. The review method on the integration branch raises one Important finding, fixed by one fresh implementer.
- Trace: report dispatches, merges, files written and any Tracker operation in one chronological list.

## When
The user runs `/power-architect:build all`.

## Then
- The agent never opens `references/tracker.md` or any `references/tracker-*.md`, and no Tracker operation and no MCP call is made
- The agent follows L2: it reads the spec and the tickets under `docs/plans/2026-11-24-onboarding/`. The first frontier is ticket 01; ticket 02 starts after 01 is merged and 03 after 02 is merged
- No `.power-architect/` directory or ledger is written: no `Task … complete` line, no `L2` token, no `Final review: passed` line and no queue
- When every ticket is done, the review method runs on the integration branch and its findings are fixed in one fresh implementer subagent; the draft PR is marked ready (or the tickets resolved) and the worktrees are cleaned up
- The agent recommends `/power-architect:verify`, then `/power-architect:finish`
