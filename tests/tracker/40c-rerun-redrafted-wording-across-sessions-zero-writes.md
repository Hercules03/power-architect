<!--
Why this can fail: titles, Acceptance Criteria and Epic slices are drafted by the agent at to-spec step 7.
The spec keeps only the user-story sentences, and the earlier session's spec-draft.md is overwritten at the
reused slug path, so the Tracker text is the only record of the old drafts. Round 1's re-run step 4 compared
"an Epic's name, slice and ADR links; a Story's title, user-story sentence, each Acceptance Criteria check"
piece by piece against what it read. This session drafts them in different words that do not normalise equal
("returns 201 and sends one invite email" vs "responds 201 and sends exactly one invitation"), so round 1
updates PA-42, PA-44 and both Epics and comments on the Done PA-43. The fix compares only the approved
user-story sentences, grouping and (when the user changed it this session) shared context.
-->
# 40c: A re-run in a new session makes no writes when only the agent's drafted titles, criteria and slices are worded differently

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
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name. Rows are matched top to bottom. The stub returns **exactly** the text below; it never echoes back text the agent drafts in this run.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getContentFormatGuide | any | "Markdown is accepted. Tables and task lists (`- [ ]`) are supported." |
  | getConfluenceContent | page 5001 | {id: "5001", title: "Team invites", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001", body (Markdown): the Page body below, followed by the key table below} |
  | getJiraIssue | PA-40 … PA-44 | that item's row of the Items table below, with `description` the matching Descriptions block below |
  | listJiraIssueComments | any | none |
  | editJiraIssue | any | {ok: true} |
  | addOrEditJiraIssueComment | any | {id: "c-1"} |
  | createJiraIssue | any | {key: "PA-<n>"} (n starts at 50) |
  | updateConfluenceContent | any | {id: "5001", version: 3} |

  Items (as the earlier session drafted them):

  | Key | Kind | summary | status | parent |
  |---|---|---|---|---|
  | PA-40 | Epic | Invitations | To Do | — |
  | PA-41 | Epic | Membership | To Do | — |
  | PA-42 | Story | Invite a teammate by email | To Do | PA-40 |
  | PA-43 | Story | Accept an invite | Done | PA-40 |
  | PA-44 | Story | Remove a member | To Do | PA-41 |

  Descriptions:

  - PA-40:
    ```md
    - Invite teammates by email, and let invitees accept from the link.

    Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001
    ```
  - PA-41:
    ```md
    - Manage who belongs to an organization.

    Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001
    ```
  - PA-42:
    ```md
    As an org admin, I want to invite a teammate by email, so that they can join my organization.

    ## Acceptance Criteria
    - [ ] POST /invites with an email returns 201 and sends one invite email.

    Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001
    ```
  - PA-43:
    ```md
    As an invitee, I want to accept an invite from the email link, so that I join the organization.

    ## Acceptance Criteria
    - [x] Accepting a valid invite adds the invitee as a member.

    Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001
    ```
  - PA-44:
    ```md
    As an org admin, I want to remove a member, so that ex-employees lose access.

    ## Acceptance Criteria
    - [ ] Removing a member revokes their sessions.

    Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001
    ```

  Page body on page 5001 (before the key table): the shared context as the earlier session published it. Its Further Notes section reads "Invite emails are sent through the existing mailer."

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
  ```
- Ledger / local files:
  - Today is 2026-11-25. The feature's slug is `team-invites`. There are no ADRs. `GLOSSARY.md` exists.
  - `.power-architect/2026-11-24-team-invites/progress.md` exists (written in an earlier session). Its first line is `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001`, followed by a `## Work Refs` table with the same 6 rows as the key table. The earlier session's `spec-draft.md` is not kept; this session writes a new one at the same path.
  - The spec (the user-approved content), unchanged since the earlier session. Title "Team invites". Settled test seam: the public HTTP API. User stories, word for word as in the earlier session:
    1. As an org admin, I want to invite a teammate by email, so that they can join my organization.
    2. As an invitee, I want to accept an invite from the email link, so that I join the organization.
    3. As an org admin, I want to remove a member, so that ex-employees lose access.

    Grouping: Invitations (1, 2), Membership (3). The shared context (Problem Statement, Solution, Goals, and the rest) means the same as the page body; the user changed none of it in this session.
  - In this session the agent drafts the parts that are not spec content in its own words. The Work Outline it builds at step 7 has:
    - Epic slices: Invitations "Let admins invite teammates by email and let invitees join from the link."; Membership "Control who is a member of an organization."
    - Story 1: title "Invite a teammate via email", criterion "POST /invites with an email responds 201 and sends exactly one invitation."
    - Story 2: title "Accept an invitation", criterion "Accepting a valid invitation makes the invitee a member."
    - Story 3: title "Remove an organization member", criterion "Removing a member ends all of their sessions."
    - Further Notes in the new `spec-draft.md`: "Invitation emails go out through the existing mailer."
  - Conversation so far: this is a new session. The user says nothing in the spec changed and asks to re-run to-spec.

## When
The user runs `/power-architect:to-spec` and replies in order:
1. confirms the proposed test seam;
2. accepts the Large tier;
3. to any builder-check questions: "your call on all of them";
4. at the spec gate: "approved" (grouping Invitations (1, 2), Membership (3));
5. if asked to go ahead with a change summary: "go ahead".

## Then
- No MCP call of any kind is made before the user's "approved"
- `publish(outline)` is called once, and the outline names the Spec Page `https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001` and the 6 Work Refs recorded in the ledger
- Stories pair by their user-story sentences: 1 with PA-42, 2 with PA-43, 3 with PA-44
- The MCP calls are reads only: a connection check, `getConfluenceContent` on page 5001, and `getJiraIssue` on PA-40 … PA-44 (a `discover`, `getContentFormatGuide` or `listJiraIssueComments` read may also appear). There is no `searchConfluence` call
- Zero write calls: no `createConfluenceContent`, `createJiraIssue`, `editJiraIssue`, `addOrEditJiraIssueComment` or `updateConfluenceContent`
- No item is listed as updated, re-parented or held because a title, criterion, slice or Further Notes line is worded differently: PA-40, PA-41, PA-42 and PA-44 (To Do) are not rewritten, and PA-43 (Done) gets no comment
- The agent tells the user nothing changed and the Tracker is already up to date; `held` and `declined` are empty
- The ledger still has its first line and the same 6 Work Refs
- No Sprint or board call, no transition, and no `executeDestructive` call
