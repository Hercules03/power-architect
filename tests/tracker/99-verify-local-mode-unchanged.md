# 99: With no `## Tracker` section, verify behaves exactly as before and never opens a Tracker file

**Phase:** /power-architect:verify

## Given
- Repo instructions file (AGENTS.md or CLAUDE.md): no `## Tracker` section
- Tracker state: none
- Ledger / local files:
  - Today is 2026-11-25. The spec is `docs/specs/2026-11-24-login-lockout.md` and the plan is `docs/plans/2026-11-24-login-lockout.md` (Small tier, two tasks). `.power-architect/2026-11-24-login-lockout/progress.md` has first line `# Ledger — plan: docs/plans/2026-11-24-login-lockout.md` and `Task 1: complete (…)`, `Task 2: complete (…)`.
  - The agent is in the repo checkout on branch `feat/login-lockout`.
- Execution outcomes (take as given): `npm test` → `14 passed`; `npx tsc --noEmit` exits 0; `npm run lint` → `0 problems`; no build script. Every requirement in the spec has a proving command that passes.
- Trace: report each file opened, each shell command and what is said to the user in one chronological list.

## When
The user runs the phase.

## Then
- SKILL.md step 1 finds no `## Tracker` section, so `tracker.md` and `tracker-jira.md` are never opened
- `verify.md` is followed in Local Files mode: the spec and plan are read from `docs/specs/2026-11-24-login-lockout.md` and `docs/plans/2026-11-24-login-lockout.md`
- A line-by-line checklist of every spec requirement is built and each item is verified with fresh evidence; `npm test`, `npx tsc --noEmit` and `npm run lint` are run
- No `pull`, no `record`, no Story step, no Rovo or MCP call, no `## Tracker queue`, and no mention of Stories, Jira or a Tracker to the user
- The agent reports the evidence and recommends `/power-architect:finish`
