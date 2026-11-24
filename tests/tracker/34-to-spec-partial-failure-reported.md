# 34: A failure partway through publish is reported item by item and the created Work Refs are ledgered

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
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name. Rows are matched top to bottom. One counter `n` is shared by every successful `createJiraIssue`, starting at 10.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | getAccessibleAtlassianResources | any | [{id: "11111111-2222-3333-4444-555555555555", url: "https://acme.atlassian.net", name: "acme"}] |
  | discover | any | the tools in this table whose names match the query |
  | getContentFormatGuide | any | "Markdown is accepted. Tables and task lists (`- [ ]`) are supported." |
  | createConfluenceContent | any | {id: "4001", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001"} |
  | createJiraIssue | parent=PA-11 | UNREACHABLE |
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
4. at the spec gate: "approved".

## Then
- The MCP calls, in order: connection check → `createConfluenceContent` (page 4001) → three Epic creates (PA-10, PA-11, PA-12) → Story creates for user stories 1, 2, 3 under PA-10 (PA-13, PA-14, PA-15) → the Story create for user story 4 under PA-11, which returns UNREACHABLE
- No MCP call follows the failed one: no retry, no further Story create, and no `updateConfluenceContent` (no key table)
- The agent tells the user the spec is only partly published, and lists exactly what was created (the Spec Page, PA-10, PA-11, PA-12, PA-13, PA-14, PA-15, each with its outline id) and what was not (user stories 4–8 and the key table)
- The ledger `.power-architect/2026-11-24-onboarding/progress.md` is written. Its first line is `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001`, and it lists the 7 created items with their Work Refs, and nothing for user stories 4–8
- `docs/specs/` is not written
