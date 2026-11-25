# 115: A first publish whose Spec Page title is taken makes no search, writes nothing else, and asks one question

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
  status-in-progress: In Progress, In Review
  status-done: Done
  link-blocks: Blocks
  link-relates: Relates
  ```
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name. Rows are matched top to bottom. The stub keeps state within this dry run: a read returns what this dry run's own earlier writes left behind. There is no search tool in this table: a search call has no row to match.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getContentFormatGuide | any | "Markdown is accepted. Tables and task lists (`- [ ]`) are supported." |
  | createConfluenceContent | title "Team invites" | error: a page titled "Team invites" already exists in space PASPEC (a create rejected as a duplicate title) |
  | createConfluenceContent | title "Team invites v2" | {id: "6001", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001"} |
  | getConfluenceContent | page 5001 | {id: "5001", title: "Team invites", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001", body (Markdown): exactly the Spec Page body the agent builds from the spec now, followed by the key table below} |
  | getJiraIssue | PA-40 … PA-42 | that item's row of the Items table below, with `description` exactly what the adapter's create step writes for it from the spec as published |
  | listJiraIssueComments | any | none |
  | createJiraIssue | any | {key: "PA-<n>"} (n starts at 50) |
  | editJiraIssue | any | {ok: true} |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | updateConfluenceContent | any | {id: "5001" or "6001", version: 2} |

  Items (only used by the variant where the user names the existing page):

  | Key | Kind | summary | status | parent |
  |---|---|---|---|---|
  | PA-40 | Epic | Invitations | To Do | — |
  | PA-41 | Story | Invite a teammate by email | To Do | PA-40 |
  | PA-42 | Story | Accept an invite | To Do | PA-40 |

  Key table on page 5001:

  ```md
  ## Work Refs

  | outline id | kind | Work Ref | title |
  |---|---|---|---|
  | spec | Spec Page | https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001 | Team invites |
  | E1 | Epic | PA-40 | Invitations |
  | 1 | Story | PA-41 | Invite a teammate by email |
  | 2 | Story | PA-42 | Accept an invite |
  ```
- Ledger / local files:
  - Today is 2026-11-24. The feature's slug is `team-invites`. There are no ADRs. `GLOSSARY.md` exists.
  - There is no `.power-architect/` directory: no ledger, and the user gives no Work Ref and no page URL.
  - The spec is new (never published by this skill). Settled test seam: the public HTTP API. Tier: Large. One Epic, "Invitations" (slice: "Invite teammates by email, and let invitees accept from the link."), with two user stories:
    1. "Invite a teammate by email": As an org admin, I want to invite a teammate by email, so that they can join my organization. Criterion: POST /invites with an email returns 201 and sends one invite email.
    2. "Accept an invite": As an invitee, I want to accept an invite from the email link, so that I join the organization. Criterion: Accepting a valid invite adds the invitee as a member.
  - Conversation so far: the user asks to publish the spec to Jira and does not mention any earlier publish.

## When
The user runs `/power-architect:to-spec` and replies in order:
1. confirms the proposed test seam;
2. accepts the Large tier;
3. to any builder-check questions: "your call on all of them";
4. at the spec gate: "approved".

The Spec Page title is "Team invites", and its create is rejected as a duplicate title. The user then answers the duplicate-title question, in one of two variants that start from the same state:
- Variant A: the user answers with the existing page's URL, "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001".
- Variant B: the user answers with a new title, "Team invites v2".

## Then
- No MCP call of any kind is made before the user's "approved"
- No search call is made anywhere in the run: no `searchConfluence`, and no CQL or JQL query of any kind, for a Spec Page or for anything else
- The MCP calls, in order: a connection check (`atlassianUserInfo`) → `createConfluenceContent` with title "Team invites", which is rejected as a duplicate title. (A `discover` or `getContentFormatGuide` read may appear after the connection check.) Nothing else is called: no `createJiraIssue`, no `updateConfluenceContent`, no `getConfluenceContent`
- The Spec Page create is the first write, and it is the only write attempted: no Epic and no Story is created, and no `## Work Refs` table is written
- No ledger `.power-architect/2026-11-24-team-invites/progress.md` is written, and no Work Ref is recorded
- The agent asks the user exactly one question, word for word: "A page with this title already exists. If it is this spec's earlier Spec Page, give me its Work Ref or URL (this becomes a re-run); otherwise give a different title." It asks it before any other write
- The agent asks no other question about the Tracker: no "is this your Spec Page?" confirmation, and no list of matching pages
- The agent waits for the answer; no write call is made before it
- No Sprint or board call, and no transition

Variant A (the user answers with the existing page's URL):
- Variant A: The run is a re-run with page 5001 as the Spec Page: `getConfluenceContent` on page 5001 and `getJiraIssue` on PA-40 … PA-42
- Variant A: The agent says the Tracker is already up to date, writes nothing, and asks no go-ahead
- Variant A: No `createConfluenceContent` is retried, and no `createJiraIssue` or `updateConfluenceContent` is called (nothing changed)
- Variant A: The ledger `.power-architect/2026-11-24-team-invites/progress.md` is written: first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001`, then the 4 Work Refs from the key table (the Spec Page, PA-40, PA-41, PA-42)

Variant B (the user answers with a new title):
- Variant B: The Spec Page create is retried once, with title "Team invites v2", and returns page 6001
- Variant B: The agent does not ask the duplicate-title question again
- Variant B: Then, in order: `createJiraIssue` for the Epic "Invitations" (PA-50), `createJiraIssue` for Story 1 under PA-50 (PA-51), `createJiraIssue` for Story 2 under PA-50 (PA-52), then one `updateConfluenceContent` on page 6001 whose key table has the rows spec / Spec Page URL `https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, E1 PA-50, 1 PA-51, 2 PA-52
- Variant B: No `createConfluenceContent` is called with the title "Team invites" again, and no search call is made
