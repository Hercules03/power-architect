# 41: A Done Story whose user-story sentence changed gets one comment, holding only the sentence change, across two sessions; a To Do Story is redrafted

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
  | PA-43 | Story | Accept an invite | Done | PA-40 |
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
  - Spec now (what the agent must write from today's settled design): the same as published, except two user-story sentences: story 1 is now "As an org admin, I want to invite a teammate by email or by a shareable link, so that they can join my organization." and story 2 is now "As an invitee, I want to accept an invite from the email link before it expires, so that I join the organization." The grouping and the shared context are unchanged.
  - In the first run the agent drafts story 2's criteria as "Accepting a valid invite adds the invitee as a member" and "Accepting an expired invite shows an error and adds no member". In the second run (a new session) it drafts them in other words: "A valid, unexpired invite makes the invitee a member" and "An expired invite is rejected with an error and no member is added". It also words story 1's title and criteria differently in the second run.
  - Conversation so far: the user re-ran `/power-architect:grill`, which changed the spec as described, and now re-runs to-spec.

## When
The user runs `/power-architect:to-spec` and replies in order:
1. confirms the proposed test seam;
2. accepts the Large tier;
3. to any builder-check questions: "your call on all of them";
4. at the spec gate: "approved" (Invitations (1, 2), Membership (3, 4));
5. when shown the change summary and asked to go ahead: "go ahead".
6. Then, in a new session, the user runs `/power-architect:to-spec` a second time with the same spec, and gives the same replies 1–5.

## Then
- No MCP call of any kind is made before the user's "approved"
- After "approved", only reads run before the change summary: a connection check, `getConfluenceContent` on page 5001, `getJiraIssue` on PA-40 … PA-45 (`discover`, `getContentFormatGuide` and `listJiraIssueComments` reads may also appear)
- The agent shows a change summary before any write: PA-42 updated, with its new sentence and its redrafted title and criteria shown; PA-43 held because it is Done and its user-story sentence changed; nothing created, re-parented or removed. No write call is made before "go ahead"
- First run, the writes in order: one `editJiraIssue` on PA-42 whose Markdown description starts with story 1's new sentence and has a redrafted `## Acceptance Criteria` list → one `addOrEditJiraIssueComment` on PA-43 with no comment id
- That comment's first line is `Spec change not applied (item started)`, and its fenced code block holds only `- As an invitee, I want to accept an invite from the email link, so that I join the organization.` and `+ As an invitee, I want to accept an invite from the email link before it expires, so that I join the organization.` It holds no Acceptance Criteria text (it may add the plain line that the item's Acceptance Criteria were not updated)
- PA-43 is never edited: no `editJiraIssue` names PA-43, and its status is not changed
- No `createJiraIssue`. No `updateConfluenceContent`, unless PA-42's redrafted title differs from "Invite a teammate by email"; then one, the last call, whose only change is PA-42's title cell in the key table (the page body is kept as read)
- `publish` returns `held` with PA-43 and its reason, and the agent tells the user PA-43 was held and why
- The ledger still lists the same 7 Work Refs
- Second run: only reads; no write call of any kind, even though the agent words the criteria differently. In particular no second comment on PA-43 (PA-43 has exactly one comment across both sessions), and no edit of PA-42 (its sentence now matches, and its first-run criteria are kept as read). PA-43 is still reported as held
- No `createConfluenceContent` call, no Sprint or board call, no transition, and no `executeDestructive` call
