# 55: Nothing reaches the Tracker while the user is still changing the ticket breakdown; publish runs once, after approval, with the edited breakdown

**Phase:** /power-architect:plan

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
  status-in-progress: In Progress, In Review
  status-done: Done
  link-blocks: Blocks
  link-relates: Relates
  ```
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name. Rows are matched top to bottom. The stub keeps state within this dry run: a read returns what this dry run's own earlier writes left behind.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getContentFormatGuide | any | "Markdown is accepted. Tables and task lists (`- [ ]`) are supported." |
  | getConfluenceContent | page 4001 | {id: "4001", title: "Self-serve onboarding", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001", body (Markdown): the shared context below, then the key table below (after an update by this dry run, that update's body)} |
  | getJiraIssue | PA-10 … PA-20 | that item's row of the Items table below. A Story's description is its user-story sentence, then `## Acceptance Criteria` with its one `- [ ]` line, then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001`. No links |
  | getJiraIssue | a key this dry run created | what this dry run created, status To Do, with the links this dry run made |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | listJiraIssueLinkTypes | any | [{name: "Blocks", outward: "blocks", inward: "is blocked by"}, {name: "Relates", outward: "relates to", inward: "relates to"}] |
  | createJiraIssue | any | {key: "PA-<n>"} (n starts at 30) |
  | createJiraIssueLink | any | {ok: true}. Its live input schema: `type` (the link type's name); `outwardIssue` (the issue the type's outward text describes: `<outwardIssue> blocks <inwardIssue>`); `inwardIssue` (the issue the inward text describes: `<inwardIssue> is blocked by <outwardIssue>`) |
  | editJiraIssue | any | {ok: true} |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | updateConfluenceContent | any | {id: "4001", version: 3} |

  Items:

  | Key | Kind | summary | status | parent | user-story sentence and criterion |
  |---|---|---|---|---|---|
  | PA-10 | Epic | Identity & SSO | To Do | — | |
  | PA-11 | Epic | Organization Setup | To Do | — | |
  | PA-12 | Epic | Subscription & Billing | To Do | — | |
  | PA-13 | Story | Sign up with email | To Do | PA-10 | As a new user, I want to sign up with email and password, so that I can start a trial. / POST /signup with a new email returns 201. |
  | PA-14 | Story | Sign in with Google | To Do | PA-10 | As a user, I want to sign in with Google, so that I don't manage another password. / Google sign-in returns a session. |
  | PA-15 | Story | Require SAML SSO | To Do | PA-10 | As an enterprise admin, I want to require SAML SSO for my domain, so that access follows our identity provider. / Password sign-in is refused for an SSO domain. |
  | PA-16 | Story | Create an organization at sign-up | To Do | PA-11 | As a new user, I want to create an organization during sign-up, so that my team shares one workspace. / Sign-up with an org name creates the org with the user as admin. |
  | PA-17 | Story | Invite teammates | To Do | PA-11 | As an org admin, I want to invite teammates by email, so that they join my organization. / POST /invites returns 201 and sends one email. |
  | PA-18 | Story | Start a trial without a card | To Do | PA-12 | As an org admin, I want to start a 14-day trial without a card, so that I can evaluate first. / A new org has a 14-day trial and no payment method. |
  | PA-19 | Story | Pay by card | To Do | PA-12 | As an org admin, I want to pick a plan and pay by card, so that we keep access after the trial. / A paid org keeps access after the trial. |
  | PA-20 | Story | Download invoices | To Do | PA-12 | As an org admin, I want to download invoices, so that finance can reconcile them. / GET /invoices/:id returns a PDF. |

  Spec Page shared context: the sections Problem Statement, Solution, Goals / Non-goals / Anti-goals, Approaches considered, Implementation Decisions, Testing Decisions (seams: the public HTTP API, and the billing webhook handler), Out of Scope, Scope Tier (`Large`) and Further Notes of the spec "Self-serve onboarding". There is no `## Plan` section.

  Key table on page 4001:

  ```md
  ## Work Refs

  | outline id | kind | Work Ref | title |
  |---|---|---|---|
  | spec | Spec Page | https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001 | Self-serve onboarding |
  | E1 | Epic | PA-10 | Identity & SSO |
  | E2 | Epic | PA-11 | Organization Setup |
  | E3 | Epic | PA-12 | Subscription & Billing |
  | 1 | Story | PA-13 | Sign up with email |
  | 2 | Story | PA-14 | Sign in with Google |
  | 3 | Story | PA-15 | Require SAML SSO |
  | 4 | Story | PA-16 | Create an organization at sign-up |
  | 5 | Story | PA-17 | Invite teammates |
  | 6 | Story | PA-18 | Start a trial without a card |
  | 7 | Story | PA-19 | Pay by card |
  | 8 | Story | PA-20 | Download invoices |
  ```
- Ledger / local files:
  - Today is 2026-11-24. `.power-architect/2026-11-24-onboarding/progress.md` exists. Its first line is `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001`, followed by a `## Work Refs` table with the same 12 rows as the key table. There is no `docs/specs/` file for this spec. `GLOSSARY.md` exists.
  - The ticket breakdown the agent drafts first (take it as given: exploring the codebase finds nothing that changes it). Each ticket's Story, What to build and one acceptance criterion:
    - 01 "Email sign-up creates an account": Story 1. Blocked by: none. A visitor signs up with email and password through the public API and gets an account. Criterion: POST /signup with a new email returns 201 and creates one user.
    - 02 "Sign-up rejects a duplicate email": Story 1. Blocked by: 01. Signing up twice with one email is refused. Criterion: a second POST /signup with the same email returns 409.
    - 03 "Create an organization at sign-up": Story 4. Blocked by: 01. Sign-up with an org name creates the org. Criterion: the new user is the org's admin.
    - 04 "Start a trial without a card": Story 6. Blocked by: 03. A new org starts a trial with no card. Criterion: the org has a 14-day trial and no payment method.
    - 05 "Trial expiry locks the workspace": Story 6. Blocked by: 04. An expired trial locks the API. Criterion: an org whose trial ended gets 402 on API calls.

## When
The user runs `/power-architect:plan` and replies in order:
1. at the quiz: "Merge 04 and 05 into one ticket, 'Trial starts and expires', blocked by 03.";
2. when the quiz is shown again: "approved";
3. if shown a change summary and asked to go ahead: "go ahead".

## Then
- Before "approved", the only MCP calls are the reads of `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001, outline)`: a connection check, `getConfluenceContent` on page 4001 and `getJiraIssue` on PA-10 … PA-20 (`discover` and `getContentFormatGuide` reads may also appear). No `createJiraIssue`, `createJiraIssueLink`, `editJiraIssue`, `addOrEditJiraIssueComment` or `updateConfluenceContent` happens before "approved"
- After the merge request, the agent updates `.power-architect/2026-11-24-onboarding/tickets-draft.md` and shows the quiz again with 4 tickets, the last being "Trial starts and expires" under Story 6, blocked by 03. Nothing is written under `docs/plans/`
- `publish(outline)` is called exactly once, after "approved", with 4 Sub-tasks
- The MCP writes: four `createJiraIssue` calls with issue type `Sub-task` (PA-30 … PA-33), the last one "Trial starts and expires" under PA-18 → three `Blocks` links (`outwardIssue` → `inwardIssue`): PA-30 → PA-31, PA-30 → PA-32, PA-32 → PA-33 → one `updateConfluenceContent` on page 4001, the last call, whose key table ends with 4 Sub-task rows
- No Sub-task is created for "Start a trial without a card" or "Trial expiry locks the workspace"
