# 118: A to-spec re-run with nothing changed still offers the redraft question; naming an Epic and the shared context writes exactly those two, a started Epic is held, and "no" writes nothing

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
  | getConfluenceContent | page 5001 | {id: "5001", title: "Team invites", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001", body (Markdown): the Page body below, followed by the key table below (after an update by this dry run, that update's body)} |
  | getJiraIssue | PA-40 … PA-43 | that item's row of the Items table below, with `description` exactly what the adapter's create step wrote for it from the spec as published (after any edit this dry run made, the edited values) |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | editJiraIssue | any | {ok: true} |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | createJiraIssue | any | {key: "PA-<n>"} (n starts at 50) |
  | updateConfluenceContent | any | {id: "5001", version: 3} |

  Items:

  | Key | Kind | summary | status | parent |
  |---|---|---|---|---|
  | PA-40 | Epic | Invitations | To Do | — |
  | PA-41 | Epic | Membership | In Progress | — |
  | PA-42 | Story | Invite a teammate by email | To Do | PA-40 |
  | PA-43 | Story | Remove a member | In Progress | PA-41 |

  Key table on page 5001:

  ```md
  ## Work Refs

  | outline id | kind | Work Ref | title |
  |---|---|---|---|
  | spec | Spec Page | https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001 | Team invites |
  | E1 | Epic | PA-40 | Invitations |
  | E2 | Epic | PA-41 | Membership |
  | 1 | Story | PA-42 | Invite a teammate by email |
  | 2 | Story | PA-43 | Remove a member |
  ```
- Ledger / local files:
  - Today is 2026-11-25. The feature's slug is `team-invites`. There are no ADRs. `GLOSSARY.md` exists.
  - `.power-architect/2026-11-24-team-invites/progress.md` exists. Its first line is `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001`, followed by a `## Work Refs` table with the same 5 rows as the key table.
  - Spec as published, and spec now: **identical** in content. Title "Team invites". Settled test seam: the public HTTP API. Tier: Large. Two Epics: "Invitations" (slice: "Invite teammates by email."), with story 1 "Invite a teammate by email" (As an org admin, I want to invite a teammate by email, so that they can join my organization; criterion: POST /invites with an email returns 201 and sends one invite email); and "Membership" (slice: "Manage who belongs to an organization."), with story 2 "Remove a member" (As an org admin, I want to remove a member, so that ex-employees lose access; criterion: Removing a member revokes their sessions).
  - The page body on page 5001 (shared context) is the same as the spec now. The user named it in this session only because a grill session in an earlier session changed its Further Notes and that change was never published.
  - Conversation so far: the user says nothing in the spec changed and asks to re-run to-spec.

## When
The user runs `/power-architect:to-spec` and replies in order:
1. confirms the proposed test seam;
2. accepts the Large tier;
3. to any builder-check questions: "your call on all of them";
4. at the spec gate: "approved" (grouping Invitations (1), Membership (2));
5. at the change summary and the redraft question ("Redraft any item? ..."): "Redraft: Invitations and the Spec Page shared context. Go ahead."

Variant A (the user names a started Epic): the same replies, except at step 5: "Redraft: Membership. Go ahead."

Variant B (the user declines): the same replies, except at step 5: "no".

## Then
- No MCP call of any kind is made before the user's "approved"
- The change summary says the Tracker is already up to date (nothing created, updated, re-parented, held or removed), and the agent then asks the redraft question, word for word: "Redraft any item? Name items (Epic slice, Story criteria, Spec Page shared context) or say no." It asks it before any write
- Main (step 5 names Invitations and the shared context): exactly two writes, in order: one `editJiraIssue` on PA-40 with `fields` `summary` and `description`, where the description keeps its `Spec Page:` line and its slice is redrafted from the approved spec, and then one `updateConfluenceContent` on page 5001, the last call, whose body is the approved shared context followed by the key table as read. The shared context is published although no change was detected this session
- Main: no write on PA-41, PA-42 or PA-43 (nothing changed there, and Membership was not named)
- Variant A: PA-41 is started (In Progress), so it is not rewritten: no `editJiraIssue` on PA-41. Its only write is one `addOrEditJiraIssueComment` on PA-41 with no comment id, first line `Spec change not applied (item started)`, whose code block holds only `Redraft requested: kept as read.` and whose last line is `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001`. No `updateConfluenceContent` (no shared context was named)
- Variant A: `publish` returns `held` with PA-41 and the reason "redraft requested (item started)"; the agent tells the user so
- Variant B: zero write calls. No `createConfluenceContent`, `createJiraIssue`, `editJiraIssue`, `addOrEditJiraIssueComment` or `updateConfluenceContent`. `held` and `declined` are both empty, because nothing would have been written; the agent tells the user the Tracker is already up to date and nothing was written
- The ledger keeps its first line and the same 5 Work Refs in every variant
- No Sprint or board call, no transition, and no `executeDestructive` call
</content>
