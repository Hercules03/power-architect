# 59b: With no `## Tracker` section, a Small plan is saved to a local plan file as today and never reads the Tracker files

**Phase:** /power-architect:plan

## Given
- Repo instructions file (AGENTS.md): exists, with no `## Tracker` section
- Tracker state: none
- Ledger / local files:
  - Today is 2026-11-24. There is no `.power-architect/` directory. `GLOSSARY.md` exists.
  - `docs/specs/2026-11-24-login-lockout.md` exists: the approved spec "Login lockout", Scope Tier Small, one user story: As a user, I want my account locked for 15 minutes after five failed logins in 10 minutes, so that my password can't be guessed.
  - The codebase is TypeScript with Express, Redis and Vitest. The plan the agent drafts (take it as given): Task 1 "Failed-login counter" (Create `src/auth/attempts.ts`, Test `tests/auth/attempts.test.ts`) and Task 2 "Login handler enforces the lockout" (Modify `src/auth/login.ts:40-62`, Test `tests/auth/login.test.ts`), each with five steps ending in a commit.

## When
The user runs `/power-architect:plan` and replies in order:
1. when asked to review the plan and pick an execution method: "approved, subagent-driven".

## Then
- The agent checks for a `## Tracker` section, finds none, and uses Local Files
- The agent never opens `references/tracker.md` or any `references/tracker-*.md`
- The agent reads `docs/specs/2026-11-24-login-lockout.md`
- The plan is saved to `docs/plans/2026-11-24-login-lockout.md`, with the plan header (its **Spec:** line is the path `docs/specs/2026-11-24-login-lockout.md`) and both tasks with their exact file paths and `- [ ]` steps
- No Tracker operation (publish / pull / record) is attempted and no MCP call is made
- Nothing is written under `.power-architect/` (no `plan-draft.md`, no ledger)
- The agent asks the user to review the plan and which execution method they want, with a recommendation, then recommends `/power-architect:build`
