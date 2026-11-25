# 58: A to-spec re-run that changes the shared context keeps the Plan section exactly as read and leaves the Sub-tasks alone

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
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name. Rows are matched top to bottom.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getContentFormatGuide | any | "Markdown is accepted. Tables and task lists (`- [ ]`) are supported." |
  | getConfluenceContent | page 5001 | {id: "5001", title: "Team invites", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001", body (Markdown): exactly the Spec Page body the agent builds from the spec **as published** (without the new Out of Scope line), then the Plan section below, then the key table below} |
  | getJiraIssue | PA-60 … PA-62 | a Sub-task (To Do), parent as in the key table |
  | getJiraIssue | PA-40 … PA-45 | that item's row of the Items table below, with `description` exactly what the adapter's create step writes for it from the spec as published |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | editJiraIssue | any | {ok: true} |
  | addOrEditJiraIssueComment | any | {id: "c-1"} |
  | createJiraIssue | any | {key: "PA-<n>"} (n starts at 50) |
  | updateConfluenceContent | any | {id: "5001", version: 3} |

  Items:

  | Key | Kind | summary | status | parent |
  |---|---|---|---|---|
  | PA-40 | Epic | Invitations | To Do | — |
  | PA-41 | Epic | Membership | To Do | — |
  | PA-42 | Story | Invite a teammate by email | To Do | PA-40 |
  | PA-43 | Story | Accept an invite | Done | PA-40 |
  | PA-44 | Story | Remove a member | In Progress | PA-41 |
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
  | 01 | Sub-task | PA-60 | Invite endpoint sends an email |
  | 02 | Sub-task | PA-61 | Accepting an invite adds a member |
  | 03 | Sub-task | PA-62 | Removing a member revokes sessions |
  ```

  Plan section on page 5001 (between the shared context and the key table):

  ```md
  ## Plan

  | ticket | title | Blocked by |
  |---|---|---|
  | 01 | Invite endpoint sends an email | None |
  | 02 | Accepting an invite adds a member | 01 |
  | 03 | Removing a member revokes sessions | 02 |
  ```
- Ledger / local files:
  - Today is 2026-11-24. The feature's slug is `team-invites`. There are no ADRs. `GLOSSARY.md` exists.
  - `.power-architect/2026-11-24-team-invites/progress.md` exists. Its first line is `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001`, followed by a `## Work Refs` table with the same 10 rows as the key table.
  - Spec as published (earlier today), and spec now: identical except one shared-context change: the spec now has one more Out of Scope line, "Invites across organizations." The user stories and the grouping are unchanged. Title "Team invites". Settled test seam: the public HTTP API. The user stories, in two product areas, with each Story's title, sentence and its one acceptance criterion, and each Epic's slice of the goals, exactly as the agent must write them:
    - **Invitations** (slice: "Invite teammates by email, and let invitees accept from the link."):
      1. "Invite a teammate by email": As an org admin, I want to invite a teammate by email, so that they can join my organization. Criterion: POST /invites with an email returns 201 and sends one invite email.
      2. "Accept an invite": As an invitee, I want to accept an invite from the email link, so that I join the organization. Criterion: Accepting a valid invite adds the invitee as a member.
    - **Membership** (slice: "Manage who belongs to an organization."):
      3. "Remove a member": As an org admin, I want to remove a member, so that ex-employees lose access. Criterion: Removing a member revokes their sessions.
      4. "Leave an organization": As a member, I want to leave an organization, so that I stop seeing its work. Criterion: Leaving removes the member and keeps their past comments.
  - Conversation so far: plan has run and published Sub-tasks 01–03. The user then re-ran `/power-architect:grill`, which added the Out of Scope line "Invites across organizations." in this session, and now re-runs to-spec.

## When
The user runs `/power-architect:to-spec` and replies in order:
1. confirms the proposed test seam;
2. accepts the Large tier;
3. to any builder-check questions: "your call on all of them";
4. at the spec gate: "approved" (grouping Invitations (1, 2), Membership (3, 4));
5. if asked to go ahead with a change summary: "go ahead".

## Then
- No MCP call of any kind is made before the user's "approved"
- Reads after "approved": a connection check, `getConfluenceContent` on page 5001, and `getJiraIssue` on PA-40 … PA-45 only. There is no `getJiraIssue` on PA-60, PA-61 or PA-62 (`discover`, `getContentFormatGuide` and `listJiraIssueComments` reads may also appear)
- A change summary is shown before any write, with nothing created, updated, re-parented, held or removed among the Epics and Stories. No write before "go ahead"
- The only write: one `updateConfluenceContent` on page 5001. Its body is the shared context with the new Out of Scope line "Invites across organizations.", then the `## Plan` section exactly as read (the same three rows), then the key table last, with the same 10 rows as read, including the three Sub-task rows unchanged
- The `## Plan` section appears once, after the shared context and before the key table
- No write names PA-60, PA-61 or PA-62: no `editJiraIssue`, no `addOrEditJiraIssueComment`, and none of them is marked removed from spec
- No `createJiraIssue`, `createJiraIssueLink`, `createConfluenceContent`, Sprint or board call, transition, or `executeDestructive` call
- The ledger keeps its first line and the same 10 rows
