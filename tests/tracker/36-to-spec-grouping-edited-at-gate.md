# 36: An edit to the Epic grouping at the gate shapes the published Epics

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
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name. One counter `n` is shared by every successful `createJiraIssue`, starting at 10.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | getAccessibleAtlassianResources | any | [{id: "11111111-2222-3333-4444-555555555555", url: "https://acme.atlassian.net", name: "acme"}] |
  | discover | any | the tools in this table whose names match the query |
  | getContentFormatGuide | any | "Markdown is accepted. Tables and task lists (`- [ ]`) are supported." |
  | createConfluenceContent | any | {id: "4001", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001"} |
  | createJiraIssue | any | {key: "PA-<n>"} |
  | updateConfluenceContent | any | {id: "4001", version: 2} |

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
4. at the spec gate: "Move story 5 (inviting teammates) into Identity & SSO.";
5. when shown the revised grouping: "approved".

## Then
- The first grouping shown is Identity & SSO (1, 2, 3), Organization Setup (4, 5), Subscription & Billing (6, 7, 8)
- After the edit, the agent shows the grouping again: Identity & SSO (1, 2, 3, 5), Organization Setup (4), Subscription & Billing (6, 7, 8), and asks for approval again
- No MCP call of any kind is made before the final "approved"
- No search call is made on this first publish
- `publish(outline)` is called once, with three Epics: Identity & SSO holding stories 1, 2, 3, 5; Organization Setup holding story 4; Subscription & Billing holding 6, 7, 8
- The Story creates run in user-story order 1–8 (PA-13 … PA-20), and the Story for user story 5 (PA-17) has parent PA-10 (Identity & SSO), while the Story for user story 4 (PA-16) has parent PA-11
- The key table and the ledger record story 5 as PA-17
