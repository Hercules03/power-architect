# 40b: An unchanged re-run makes no writes even when the Tracker's text is worded and formatted differently from a fresh draft

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
  | getJiraIssue | PA-40 … PA-43 | that item's row of the Items table below, with `description` the matching Descriptions block below |
  | listJiraIssueComments | any | none |
  | editJiraIssue | any | {ok: true} |
  | addOrEditJiraIssueComment | any | {id: "c-1"} |
  | createJiraIssue | any | {key: "PA-<n>"} (n starts at 50) |
  | updateConfluenceContent | any | {id: "5001", version: 3} |

  Items:

  | Key | Kind | summary | status | parent |
  |---|---|---|---|---|
  | PA-40 | Epic | invitations | To Do | — |
  | PA-41 | Epic | MEMBERSHIP | To Do | — |
  | PA-42 | Story | invite a teammate by email | To Do | PA-40 |
  | PA-43 | Story | Accept an invite | Done | PA-40 |
  | PA-44 | Story | Remove a member | To Do | PA-41 |

  Descriptions (as a person tidied them in Jira after the first publish: other list markers, other casing, wrapped links, escapes):

  - PA-40:
    ```md
    * invite teammates by email, and let invitees accept from the link.

    Spec Page: [Team invites](https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001)
    ```
  - PA-41:
    ```md
    + Manage who belongs to an organization.

    Spec Page: <https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001>
    ```
  - PA-42:
    ```md
    as an org admin, I want to invite a teammate by email,   so that they can join my organization.

    ## acceptance criteria
    1. [ ] POST /invites with an email returns 201 and sends one invite email.

    Spec Page: [link](https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001)
    ```
  - PA-43:
    ```md
    As an invitee, I want to accept an invite from the email link, so that I join the organization.

    ## Acceptance Criteria
    * [x] Accepting a valid invite adds the invitee as a member.

    Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001
    ```
  - PA-44:
    ```md
    As an org admin, I want to remove a member, so that ex\-employees lose access.

    ## ACCEPTANCE CRITERIA
    + [ ] removing a member revokes their sessions.

    Spec Page: [Team invites](https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001)
    ```

  Page body on page 5001 (before the key table): the same content as the spec now, section by section, but with every heading in lower case (`## problem statement`, `## solution`, …), every list item marked `*` instead of `-`, and the one URL in it wrapped as `[the public HTTP API](https://api.acme.test)` where the spec writes the bare URL `https://api.acme.test`.

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
  - `.power-architect/2026-11-24-team-invites/progress.md` exists (written in an earlier session). Its first line is `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001`, followed by a `## Work Refs` table with the same 6 rows as the key table.
  - Spec as published (yesterday), and spec now: **the same content**. Title "Team invites". Settled test seam: the public HTTP API at `https://api.acme.test`. The user stories, with each Story's title, sentence and its one acceptance criterion, and each Epic's slice:
    - **Invitations** (slice: "Invite teammates by email, and let invitees accept from the link."):
      1. "Invite a teammate by email": As an org admin, I want to invite a teammate by email, so that they can join my organization. Criterion: POST /invites with an email returns 201 and sends one invite email.
      2. "Accept an invite": As an invitee, I want to accept an invite from the email link, so that I join the organization. Criterion: Accepting a valid invite adds the invitee as a member.
    - **Membership** (slice: "Manage who belongs to an organization."):
      3. "Remove a member": As an org admin, I want to remove a member, so that ex-employees lose access. Criterion: Removing a member revokes their sessions.
  - A fresh draft of this spec, as the adapter's create steps would write it, differs textually from every Descriptions block above and from the page body (list markers, casing, link wrapping, the `\-` escape). Only the content is the same.
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
- The MCP calls are reads only: a connection check, `getConfluenceContent` on page 5001, and `getJiraIssue` on PA-40 … PA-44 (a `discover`, `getContentFormatGuide` or `listJiraIssueComments` read may also appear). There is no `searchConfluence` call
- Zero write calls: no `createConfluenceContent`, `createJiraIssue`, `editJiraIssue`, `addOrEditJiraIssueComment` or `updateConfluenceContent`
- No item is listed as updated, re-parented or held because of wording or formatting: PA-42 and PA-44 (To Do) are not rewritten, and PA-43 (Done) gets no comment
- The agent tells the user nothing changed and the Tracker is already up to date; `held` is empty
- The ledger still has its first line and the same 6 Work Refs
- No Sprint or board call, no transition, and no `executeDestructive` call
