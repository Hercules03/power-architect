# 119: An Epic redrafted for a membership change gains a new spec ADR link and keeps its old ones; an untouched Epic gains none

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
  | getJiraIssue | PA-40 … PA-53 | that item's row of the Items table below, with `description` exactly what the adapter's create step wrote for it from the spec as published (after any edit this dry run made, the edited values) |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | editJiraIssue | any | {ok: true} |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | createJiraIssue | any | {key: "PA-<n>"} (n starts at 60) |
  | updateConfluenceContent | any | {id: "5001", version: 3} |

  Items (Stories are under the Epic in the parent column):

  | Key | Kind | summary | status | parent |
  |---|---|---|---|---|
  | PA-40 | Epic | Invitations | To Do | — |
  | PA-41 | Epic | Membership | To Do | — |
  | PA-42 | Epic | Billing | To Do | — |
  | PA-50 | Story | Invite a teammate by email | To Do | PA-40 |
  | PA-51 | Story | Accept an invite | To Do | PA-40 |
  | PA-52 | Story | Remove a member | To Do | PA-41 |
  | PA-53 | Story | Pay by card | To Do | PA-42 |

  Descriptions as published (the Epics' descriptions are the ones the adapter wrote; each holds its slice, its `Spec Page:` line and its ADR lines):
  - PA-40: slice "Invite teammates by email, and let invitees accept from the link." Then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001` and `ADR: ADR 0001 — docs/adr/0001-sessions.md — https://github.com/acme/app/blob/main/docs/adr/0001-sessions.md`
  - PA-41: slice "Manage who belongs to an organization." Then the same `Spec Page:` line and the same `ADR:` line for 0001 as PA-40
  - PA-42: slice "Take payment for a plan." Then the same `Spec Page:` line and the same `ADR:` line for 0001 as PA-40

  Key table on page 5001:

  ```md
  ## Work Refs

  | outline id | kind | Work Ref | title |
  |---|---|---|---|
  | spec | Spec Page | https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001 | Team invites |
  | E1 | Epic | PA-40 | Invitations |
  | E2 | Epic | PA-41 | Membership |
  | E3 | Epic | PA-42 | Billing |
  | 1 | Story | PA-50 | Invite a teammate by email |
  | 2 | Story | PA-51 | Accept an invite |
  | 3 | Story | PA-52 | Remove a member |
  | 4 | Story | PA-53 | Pay by card |
  ```
- Ledger / local files:
  - Today is 2026-11-25. The feature's slug is `team-invites`. `GLOSSARY.md` exists.
  - ADRs: the spec's ADR list has two entries now: `docs/adr/0001-sessions.md` (linked by all three Epics already) and `docs/adr/0007-invite-expiry.md` (title "Invite expiry", URL `https://github.com/acme/app/blob/main/docs/adr/0007-invite-expiry.md`). ADR 0007 is new: no Epic links it yet.
  - `.power-architect/2026-11-24-team-invites/progress.md` exists. Its first line is `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001`, followed by a `## Work Refs` table with the same 8 rows as the key table.
  - Spec as published, and spec now, differ in one place. The grouping now is: Invitations (1), Membership (2, 3), Billing (4). Story 2 "Accept an invite" moves from Invitations to Membership; its sentence and criterion are unchanged. Stories 1, 3 and 4 and their sentences are unchanged. The shared context is unchanged.
  - Conversation so far: the user re-runs to-spec after the grill session changed the Invitations and Membership grouping and added ADR 0007 in this session.

## When
The user runs `/power-architect:to-spec` and replies in order:
1. confirms the proposed test seam;
2. accepts the Large tier;
3. to any builder-check questions: "your call on all of them";
4. at the spec gate: "approved" (grouping Invitations (1), Membership (2, 3), Billing (4));
5. at the change summary and its go-ahead question: "go ahead".

## Then
- No MCP call of any kind is made before the user's "approved"
- The change summary, shown before any write, lists: PA-51 (Story 2) re-parented from PA-40 to PA-41; PA-40 and PA-41 updated with a redrafted slice, because their membership changed; PA-42 is not updated, redrafted or commented (an "unchanged" row in the summary is allowed; its membership did not change). Nothing created, held or removed
- Each updated Epic's ADR lines are refreshed from the spec's current ADR list: PA-40 and PA-41 each gain one line `ADR: Invite expiry — docs/adr/0007-invite-expiry.md — <its URL>`, every ADR line carrying the `ADR:` prefix, and keep their existing `ADR: ADR 0001 — …` line
- The writes, in order, one call at a time, parents first: `editJiraIssue` on PA-40 (summary and description, the description keeping its `Spec Page:` line and ADR 0001 line, and gaining the ADR 0007 line); `editJiraIssue` on PA-41 (the same, with its slice redrafted for its new membership); then `editJiraIssue` on PA-51 setting `fields` `parent` to PA-41 (its summary and description are not changed)
- No `editJiraIssue` on PA-42: it is untouched, so it gains no ADR line. No edit of PA-50, PA-52 or PA-53
- No `addOrEditJiraIssueComment` (nothing started or removed) and no `createJiraIssue`
- No `updateConfluenceContent` (the shared context and the key table rows are unchanged: PA-51 is still the Story 2 row under outline id 2)
- `publish` returns an empty `held` list and an empty `declined` list; the ledger keeps its first line and the same 8 Work Refs
- The agent tells the user what was updated and re-parented, and that PA-40 and PA-41 gained the ADR 0007 link
- No createConfluenceContent call, no Sprint or board call, no transition, and no `executeDestructive` call
</content>
