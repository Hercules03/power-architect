# 59: With no `## Tracker` section, plan reads the local spec and writes local ticket files as today, and never reads the Tracker files

**Phase:** /power-architect:plan

## Given
- Repo instructions file (AGENTS.md): exists, with no `## Tracker` section
- Tracker state: none
- Ledger / local files:
  - Today is 2026-11-24. There is no `.power-architect/` directory. `GLOSSARY.md` exists.
  - `docs/specs/2026-11-24-onboarding.md` exists: the approved spec "Self-serve onboarding", Scope Tier Large, user stories 1–8 (sign up with email, sign in with Google, require SAML SSO, create an organization at sign-up, invite teammates, start a trial without a card, pay by card, download invoices).
  - The ticket breakdown the agent drafts (take it as given: exploring the codebase finds nothing that changes it):
    - 01 "Email sign-up creates an account". Blocked by: none. Criterion: POST /signup with a new email returns 201 and creates one user.
    - 02 "Sign-up rejects a duplicate email". Blocked by: 01. Criterion: a second POST /signup with the same email returns 409.
    - 03 "Create an organization at sign-up". Blocked by: 01. Criterion: the new user is the org's admin.

## When
The user runs `/power-architect:plan` and replies in order:
1. at the quiz: "approved".

## Then
- The agent checks for a `## Tracker` section, finds none, and uses Local Files
- The agent never opens `references/tracker.md` or any `references/tracker-*.md`
- The agent reads `docs/specs/2026-11-24-onboarding.md`
- The quiz lists each ticket's Title, Blocked by and What it delivers, as today. It asks no question about Stories and flags no ticket as spanning Stories
- After "approved", the agent writes `docs/plans/2026-11-24-onboarding/01-….md`, `02-….md` and `03-….md`, one per ticket, numbered in dependency order, each with the ticket template (title, What to build, Blocked by, Status `ready-for-agent`, acceptance criteria checklist)
- No Tracker operation (publish / pull / record) is attempted and no MCP call is made
- Nothing is written under `.power-architect/` (no `tickets-draft.md`, no ledger)
- The agent recommends `/power-architect:build 01` or `/power-architect:build all`
