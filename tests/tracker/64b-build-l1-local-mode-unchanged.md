# 64b: With no `## Tracker` section, `/build 02` builds one Large ticket from its local file as today, with no Tracker files

**Phase:** /power-architect:build 02

## Given
- Repo instructions file (AGENTS.md): exists, with no `## Tracker` section
- Tracker state: none
- Ledger / local files:
  - Today is 2026-11-25. There is no `.power-architect/` directory.
  - `docs/specs/2026-11-24-onboarding.md` exists: the approved spec "Self-serve onboarding", Scope Tier Large.
  - `docs/plans/2026-11-24-onboarding/` holds `01-email-sign-up.md` (**Status:** done), `02-duplicate-email-rejected.md` ("Sign-up rejects a duplicate email", **Blocked by:** 01, **Status:** ready-for-agent, criterion: a second POST /signup with the same email returns 409) and `03-org-at-sign-up.md` (**Blocked by:** 01, **Status:** ready-for-agent).
  - The agent is already in a linked worktree on branch `feat/onboarding`. The baseline suite `npm test` passes.
- Execution outcomes (take as given): the work for ticket 02 is one commit `d4e5f6a feat: reject duplicate sign-up emails`; `npm test` → `42 passed`; the review method finds nothing to fix.
- Trace: report files read and written, and any Tracker operation, in one chronological list.

## When
The user runs `/power-architect:build 02`.

## Then
- The agent checks for a `## Tracker` section, finds none, and uses Local Files
- The agent never opens `references/tracker.md` or any `references/tracker-*.md`
- No Tracker operation (publish / pull / record) is attempted and no MCP call is made
- The agent follows L1: it reads `docs/plans/2026-11-24-onboarding/02-duplicate-email-rejected.md` and states its title "Sign-up rejects a duplicate email" before starting
- After the review method and the commit, the agent marks ticket 02 done, shows the passing output and a diff summary, and recommends the next frontier ticket (03)
- Tickets 01 and 03 are not built
