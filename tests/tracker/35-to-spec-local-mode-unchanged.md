# 35: With no `## Tracker` section, to-spec writes the spec file as today and never reads the Tracker files

**Phase:** /power-architect:to-spec

## Given
- Repo instructions file (AGENTS.md): exists, with no `## Tracker` section
- Tracker state: none
- Ledger / local files:
  - Today is 2026-11-24. The feature's slug is `onboarding`.
  - `origin` is `git@github.com:acme/onboard.git`; the current branch is `main`.
  - `docs/adr/0003-saml-for-enterprise-sso.md` ("SAML for enterprise SSO") and `docs/adr/0004-stripe-owns-billing-state.md` ("Stripe owns billing state") exist. `GLOSSARY.md` exists.
  - Conversation so far: a finished `/power-architect:grill` session settled the design of self-serve onboarding for a B2B SaaS app. Nothing is left open. It settled these user stories, in three product areas:
    - **Identity & SSO**: 1. As a new user, I want to sign up with email and password, so that I can start a trial. 2. As a user, I want to sign in with Google, so that I don't manage another password. 3. As an enterprise admin, I want to require SAML SSO for my domain, so that access follows our identity provider (ADR-0003).
    - **Organization Setup**: 4. As a new user, I want to create an organization during sign-up, so that my team shares one workspace. 5. As an org admin, I want to invite teammates by email, so that they join my organization.
    - **Subscription & Billing**: 6. As an org admin, I want to start a 14-day trial without a card, so that I can evaluate first. 7. As an org admin, I want to pick a plan and pay by card, so that we keep access after the trial. 8. As an org admin, I want to download invoices, so that finance can reconcile them (ADR-0004).
  - Settled test seams: the public HTTP API, and the billing webhook handler.

## When
The user runs `/power-architect:to-spec` and replies in order:
1. confirms the proposed test seams;
2. accepts the Large tier;
3. to any builder-check questions: "your call on all of them";
4. at the spec gate: "approved".

## Then
- The agent checks for a `## Tracker` section, finds none, and uses Local Files
- The agent never opens `references/tracker.md` or any `references/tracker-*.md`
- The spec is written to `docs/specs/2026-11-24-onboarding.md` using the spec template, with user stories 1–8 and the Scope Tier Large
- The builder check reads `docs/specs/2026-11-24-onboarding.md`
- The agent asks the user to approve the spec, with no Epic grouping table and no question about Epics
- No Tracker operation (publish / pull / record) is attempted, and no MCP call is made
- Nothing is written under `.power-architect/` (no `spec-draft.md`, no ledger)
- After approval, the agent recommends `/power-architect:plan`
