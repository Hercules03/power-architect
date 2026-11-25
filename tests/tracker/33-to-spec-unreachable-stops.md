# 33: When the Tracker can't be reached, to-spec stops and publishes nothing

**Phase:** /power-architect:to-spec

## Given
- Repo instructions file (AGENTS.md): `## Tracker` section:
  ```md
  ## Tracker
  adapter: jira
  site: https://acme.atlassian.net
  cloud-id: 11111111-2222-3333-4444-555555555555
  project: PA
  board: 12
  confluence-space: PASPEC
  confluence-space-id: 98765
  type-epic: Epic
  type-story: Story
  type-subtask: Sub-task
  type-bug: Bug
  status-todo: To Do
  status-in-progress: In Progress
  status-done: Done
  link-blocks: Blocks
  link-relates: Relates
  ```
- Tracker state: stubbed Rovo table:

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | * | any | UNREACHABLE |

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
- The draft spec is written to `.power-architect/2026-11-24-onboarding/spec-draft.md`, and the grouping table is shown at the gate
- After approval, `publish(outline)` is called, and its first MCP call is a connection check, which returns UNREACHABLE
- No further MCP call follows: no `createConfluenceContent`, `createJiraIssue`, `updateConfluenceContent` or retry
- `publish` stops, and the agent tells the user that Jira can't be reached and nothing was published, and that the draft is still at `.power-architect/2026-11-24-onboarding/spec-draft.md`
- No ledger (`.power-architect/2026-11-24-onboarding/progress.md`) is written
- The agent does not fall back to Local Files: `docs/specs/` is not written
