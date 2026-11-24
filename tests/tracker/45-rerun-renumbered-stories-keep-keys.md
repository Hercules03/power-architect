# 45: Renumbered user stories keep their existing keys; only the new story is created

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
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name. Rows are matched top to bottom. The stub keeps state within this dry run: a read returns what this dry run's own earlier writes left behind.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getContentFormatGuide | any | "Markdown is accepted. Tables and task lists (`- [ ]`) are supported." |
  | getConfluenceContent | page 5001 | {id: "5001", title: "Team invites", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001", body (Markdown): exactly the Spec Page body the agent builds from the spec now, followed by the key table below} |
  | getJiraIssue | PA-40 … PA-45 | that item's row of the Items table below, with `description` exactly what the adapter's create step writes for it from the spec as published (after any edit this dry run made, the edited values) |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | editJiraIssue | any | {ok: true} |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | createJiraIssue | any | {key: "PA-<n>"} (n starts at 50) |
  | updateConfluenceContent | any | {id: "5001", version: 3} |

  Items:

  | Key | Kind | summary | status | parent |
  |---|---|---|---|---|
  | PA-40 | Epic | Invitations | To Do | — |
  | PA-41 | Epic | Membership | To Do | — |
  | PA-42 | Story | Invite a teammate by email | To Do | PA-40 |
  | PA-43 | Story | Accept an invite | To Do | PA-40 |
  | PA-44 | Story | Remove a member | To Do | PA-41 |
  | PA-45 | Story | Leave an organization | To Do | PA-41 |

  Key table on page 5001:

  ```md
  ## Work Refs

  | outline id | kind | Work Ref | title |
  |---|---|---|---|
  | spec | Spec Page | https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001 | Team invites |
  | E1 | Epic | PA-40 | Invitations |
  | E2 | Epic | PA-41 | Membership |
  | 1 | Story | PA-42 | Invite a teammate by email |
  | 2 | Story | PA-43 | Accept an invite |
  | 3 | Story | PA-44 | Remove a member |
  | 4 | Story | PA-45 | Leave an organization |
  ```
- Ledger / local files:
  - Today is 2026-11-24. The feature's slug is `team-invites`. There are no ADRs. `GLOSSARY.md` exists.
  - `.power-architect/2026-11-24-team-invites/progress.md` exists. Its first line is `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001`, followed by a `## Work Refs` table with the same 7 rows as the key table.
  - Spec as published earlier today. Title "Team invites". Settled test seam: the public HTTP API. The user stories, in two product areas, with each Story's title, sentence and its one acceptance criterion, and each Epic's slice of the goals, exactly as the agent wrote them:
    - **Invitations** (slice: "Invite teammates by email, and let invitees accept from the link."):
      1. "Invite a teammate by email": As an org admin, I want to invite a teammate by email, so that they can join my organization. Criterion: POST /invites with an email returns 201 and sends one invite email.
      2. "Accept an invite": As an invitee, I want to accept an invite from the email link, so that I join the organization. Criterion: Accepting a valid invite adds the invitee as a member.
    - **Membership** (slice: "Manage who belongs to an organization."):
      3. "Remove a member": As an org admin, I want to remove a member, so that ex-employees lose access. Criterion: Removing a member revokes their sessions.
      4. "Leave an organization": As a member, I want to leave an organization, so that I stop seeing its work. Criterion: Leaving removes the member and keeps their past comments.
  - Spec now (what the agent must write from today's settled design): a new user story is inserted first, so the others are renumbered. Invitations: 1. "Request an invite": As a visitor, I want to request an invite from an org admin, so that I can ask to join. Criterion: POST /invite-requests notifies every org admin. 2. (was 1) "Invite a teammate by email": As an org admin, I want to invite a teammate by email, so that they can join my organization. Criterion: POST /invites with an email returns 201 and sends one invite email. 3. (was 2) "Accept an invite": As an invitee, I want to accept an invite from the email link, so that I join the organization. Criterion: Accepting a valid invite adds the invitee as a member.. Membership: 4. (was 3) "Remove a member": As an org admin, I want to remove a member, so that ex-employees lose access. Criterion: Removing a member revokes their sessions. 5. (was 4) "Leave an organization": As a member, I want to leave an organization, so that I stop seeing its work. Criterion: Leaving removes the member and keeps their past comments. Both Epic slices are unchanged.
  - Conversation so far: the user re-ran `/power-architect:grill`, which changed the spec as described, and now re-runs to-spec.

## When
The user runs `/power-architect:to-spec` and replies in order:
1. confirms the proposed test seam;
2. accepts the Large tier;
3. to any builder-check questions: "your call on all of them";
4. at the spec gate: "approved" (Invitations (1, 2, 3), Membership (4, 5));
5. when shown the change summary and asked to go ahead: "go ahead".

## Then
- No MCP call of any kind is made before the user's "approved"
- The change summary, shown before any write, lists one Story to create (story 1, "Request an invite"), PA-40 as updated with a redrafted slice (its membership changed), and nothing else updated, re-parented, held or removed
- The writes in order: at most one `editJiraIssue` on PA-40 that changes only its slice line(s) → one `createJiraIssue` (issue type `Story`, parent PA-40, "Request an invite") returning PA-50 → one `updateConfluenceContent` on page 5001
- No `editJiraIssue` on PA-41 or on any Story, and no `addOrEditJiraIssueComment`: nothing is marked "removed from spec"
- The key table written has 8 rows: spec, E1 PA-40, E2 PA-41, 1 PA-50, 2 PA-42, 3 PA-43, 4 PA-44, 5 PA-45
- The ledger lists the same 8 Work Refs; `held` is empty
- No `createConfluenceContent` call, no Sprint or board call, no transition, and no `executeDestructive` call
