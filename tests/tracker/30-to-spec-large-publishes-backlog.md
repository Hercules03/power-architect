# 30: A Large spec shows an Epic grouping at the gate, then publishes the Spec Page, Epics and Stories with a key table

**Phase:** /power-architect:to-spec

## Given
- Repo instructions file (AGENTS.md):
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
4. at the spec gate: "approved" (the spec and the grouping as shown).

## Then
- The agent reads the `## Tracker` section, opens `references/tracker.md`, then `references/tracker-jira.md`, and the config check passes
- The draft spec is written to `.power-architect/2026-11-24-onboarding/spec-draft.md`; `docs/specs/` is not written
- The builder check reads `.power-architect/2026-11-24-onboarding/spec-draft.md`
- At the spec gate the agent shows a table with the columns Epic, user stories and why they belong together, with three rows: Identity & SSO (1, 2, 3), Organization Setup (4, 5), Subscription & Billing (6, 7, 8). Every user story appears in exactly one row
- No MCP call of any kind is made before the user's "approved"
- After approval, `publish(outline)` is called once, with Scope Tier Large, a Spec Page, three Epics and eight Stories, each Story carrying its user-story sentence and a checklist of Acceptance Criteria
- The MCP calls, in order: a connection check (`atlassianUserInfo`) → `createConfluenceContent` (space id `98765`, Markdown body, no key table) → three `createJiraIssue` calls with issue type `Epic` (PA-10 Identity & SSO, PA-11 Organization Setup, PA-12 Subscription & Billing) → eight `createJiraIssue` calls with issue type `Story`, user stories 1–8 in order (PA-13 … PA-20), parents PA-10, PA-10, PA-10, PA-11, PA-11, PA-12, PA-12, PA-12 → one `updateConfluenceContent` on page `4001`. (A `discover` or `getContentFormatGuide` read may appear after the connection check)
- No search call is made on this first publish
- Every Jira and Confluence call passes cloudId `11111111-2222-3333-4444-555555555555`, and every work-item create uses project `PA`
- Each Epic's description holds its own slice of the spec and a link to the Spec Page (`https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001`). The Identity & SSO Epic links ADR-0003 by title, path `docs/adr/0003-saml-for-enterprise-sso.md` and URL `https://github.com/acme/onboard/blob/main/docs/adr/0003-saml-for-enterprise-sso.md`. The Subscription & Billing Epic links ADR-0004 the same way
- Each Story's description holds its user-story sentence, its Acceptance Criteria as a `- [ ]` checklist, and the Spec Page link
- The `updateConfluenceContent` body is the Spec Page body followed by a key table with columns `outline id | kind | Work Ref | title` and 12 rows: the Spec Page (its URL), E1–E3 (PA-10 … PA-12), and stories 1–8 (PA-13 … PA-20)
- The ledger `.power-architect/2026-11-24-onboarding/progress.md` is written. Its first line is `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001`, and it lists the same 12 Work Refs
- The agent tells the user what was created: the Spec Page link, 3 Epics and 8 Stories with their keys
- No Sprint or board call (`manageJiraSprint`, `createJiraBoard`); no create call passes a sprint, backlog, priority, story-point or estimate field
