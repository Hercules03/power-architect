# 32: Nothing reaches the Tracker before the spec gate is approved

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
4. at the spec gate: "Not yet. Add a story: as an org admin, I want to remove a teammate, so that ex-employees lose access."

The user gives no further reply.

## Then
- The draft spec is written to `.power-architect/2026-11-24-onboarding/spec-draft.md`
- The grouping table is shown at the spec gate
- After the user's change request, the agent updates the draft (adding the new user story) and shows the spec and grouping again, with the new story in exactly one Epic, and asks for approval
- `publish` is never called
- No MCP call of any kind is made: no connection check, no `createConfluenceContent`, `createJiraIssue`, `updateConfluenceContent` or any other create, edit, transition, comment or link call
- No ledger (`.power-architect/2026-11-24-onboarding/progress.md`) is written, and `docs/specs/` is not written
