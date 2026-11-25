# 51: A Large slice that truly spans two Stories is flagged in the quiz, filed under its main Story, and "relates to" the other Story

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
  - The ticket breakdown the agent drafts (take it as given: exploring the codebase finds nothing that changes it). Each ticket's Story, What to build and one acceptance criterion:
    - 01 "Email sign-up creates an account": Story 1. Blocked by: none. A visitor signs up with email and password through the public API and gets an account. Criterion: POST /signup with a new email returns 201 and creates one user.
    - 02 "Invite a teammate by email": Story 5. Blocked by: 01. An org admin invites a teammate. Criterion: POST /invites returns 201 and sends one email.
    - 03 "An invited teammate signs up into the organization": Blocked by: 02. Following the invite link, the teammate signs up and lands in the inviter's organization. This slice cannot be cut inside one Story: it needs both the sign-up path (Story 1) and the invite acceptance (Story 5). Its main Story is 5. Criterion: signing up from an invite link makes the new user a member of the inviting org.

## When
The user runs `/power-architect:plan` and replies in order:
1. at the quiz: "approved";
2. if shown a change summary and asked to go ahead: "go ahead".

## Then
- The agent calls `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4001, outline)` before drafting, with reads only
- The quiz lists the 3 tickets with Title, Story, Blocked by and what each delivers, and its summary flags ticket 03 as the exception: it spans Stories 5 and 1, and is filed under its main Story 5
- No MCP write call of any kind is made before the user's "approved"
- The outline passed to `publish` gives Sub-task 03 one parent Story (5) and a relates-to edge to Story 1
- The MCP writes, in order: three `createJiraIssue` calls with issue type `Sub-task`: PA-30 (parent PA-13), PA-31 (parent PA-17), PA-32 (parent PA-17) → the `Blocks` links (`outwardIssue` PA-30, `inwardIssue` PA-31) and (`outwardIssue` PA-31, `inwardIssue` PA-32), and one `Relates` link between PA-32 and PA-13 (in either order among the link calls) → one `updateConfluenceContent` on page 4001, the last call
- There is exactly one `Relates` link, and none between PA-32 and PA-17. PA-32 is created once, with one parent
- The `updateConfluenceContent` body is the shared context as read, then a `## Plan` section, then the key table: the 12 rows as read, then `01 | Sub-task | PA-30 | …`, `02 | Sub-task | PA-31 | …`, `03 | Sub-task | PA-32 | An invited teammate signs up into the organization`
- No `editJiraIssue` or comment on any Epic or Story; no Sprint or board call, no transition, no `executeDestructive` call
