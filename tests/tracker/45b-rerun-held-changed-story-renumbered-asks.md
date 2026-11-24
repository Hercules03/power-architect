<!--
Why this can fail: round 2's re-run step 3 pairs Stories by user-story sentence, then by outline id among the
still-unpaired, and turns every leftover into "new" (created) or "removed from spec" without asking. Here story 3
(was 2) has a changed sentence, and PA-43 is Done, so Jira still holds the old sentence: it never pairs by text.
The inserted story 1 shifts every id, so recorded id 2 (PA-43) meets no outline id 2 that is still unpaired
(new story 2 already paired with PA-42 by text). Round 2 therefore creates a duplicate Story for story 3 and
comments "Removed from spec" on the Done PA-43, with no question to the user. The fix asks, before any write,
"same as <Work Ref>" or "new" for each unpaired new Story while an unpaired recorded Story of the same kind remains.
-->
# 45b: A started Story whose sentence changed, renumbered by an inserted story, is not duplicated: the user is asked

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

  PA-43 is Done, and its description still starts with its old sentence (as published): "As an invitee, I want to accept an invite from the email link, so that I join the organization."

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
  - Spec now (what the agent must write from today's settled design): a new user story is inserted first, so the others are renumbered, and the story that was 2 has a changed sentence. Invitations: 1. "Request an invite": As a visitor, I want to request an invite from an org admin, so that I can ask to join. Criterion: POST /invite-requests notifies every org admin. 2. (was 1, unchanged) "Invite a teammate by email": As an org admin, I want to invite a teammate by email, so that they can join my organization. 3. (was 2, sentence changed) As an invitee, I want to accept an invite from the email link before it expires, so that I join the organization. Membership: 4. (was 3, unchanged) "Remove a member". 5. (was 4, unchanged) "Leave an organization". Both Epic slices are unchanged in meaning.
  - Conversation so far: the user re-ran `/power-architect:grill`, which changed the spec as described, and now re-runs to-spec.

## When
The user runs `/power-architect:to-spec` and replies in order:
1. confirms the proposed test seam;
2. accepts the Large tier;
3. to any builder-check questions: "your call on all of them";
4. at the spec gate: "approved" (Invitations (1, 2, 3), Membership (4, 5));
5. when asked about unpaired Stories: story 1 "new"; story 3 "same as PA-43";
6. when shown the change summary and asked to go ahead: "go ahead".
7. Variant: a separate dry run from the same Given (not after steps 1–6), with the same replies except step 5: story 1 "new"; story 3 "new".

## Then
- No MCP call of any kind is made before the user's "approved"
- Before any write call, the change summary lists the unpaired new Stories (story 1 "Request an invite" and story 3 with its new sentence) and the unpaired recorded PA-43 with its old sentence, as candidate pairs (`new: <sentence> / recorded: PA-43 <old sentence>`), and asks, for each of stories 1 and 3, "same as <Work Ref>" or "new". No write call is made before the user answers
- Stories 2, 4 and 5 pair with PA-42, PA-44 and PA-45 by sentence and are not asked about
- Main run, after "same as PA-43" and "go ahead": PA-43 is listed as `held` because it is Done and its user-story sentence changed
- Main run: PA-43 gets exactly one `addOrEditJiraIssueComment`, with no comment id, first line `Spec change not applied (item started)`, whose fenced code block holds only `- As an invitee, I want to accept an invite from the email link, so that I join the organization.` and `+ As an invitee, I want to accept an invite from the email link before it expires, so that I join the organization.`
- Main run: exactly one `createJiraIssue` (issue type `Story`, parent PA-40, "Request an invite") returning PA-50; no Story is created for story 3; no comment says "Removed from spec"; no `editJiraIssue` names PA-43
- Main run: the key table written has 8 rows: spec, E1 PA-40, E2 PA-41, 1 PA-50, 2 PA-42, 3 PA-43, 4 PA-44, 5 PA-45; `publish` returns `held` with PA-43 and its reason; the ledger lists the same 8 Work Refs
- Variant, after "new" for both: two `createJiraIssue` calls (Stories under PA-40, story 1 then story 3, returning PA-50 and PA-51), and PA-43 gets exactly one `addOrEditJiraIssueComment` whose first line is `Removed from spec`; PA-43 is listed `held` ("removed from spec"), keeps its key table row with outline id `—`, and is never edited
- No `createConfluenceContent` call, no Sprint or board call, no transition, and no `executeDestructive` call
