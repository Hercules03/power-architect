# 120: The re-run go-ahead takes three reply forms: "go ahead" writes the summary only, "go ahead, redraft <item>" also redrafts that item, "no" declines every change

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
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name. Rows are matched top to bottom. The stub keeps state within each dry run: a read returns what that run's own earlier writes left behind. Each of the three runs starts from this same state.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getContentFormatGuide | any | "Markdown is accepted. Tables and task lists (`- [ ]`) are supported." |
  | getConfluenceContent | page 5001 | {id: "5001", title: "Team invites", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001", body (Markdown): the Page body below, followed by the key table below} |
  | getJiraIssue | PA-40, PA-50 | that item's row of the Items table below, with `description` exactly as given in the Descriptions below (after any edit this run made, the edited values) |
  | listJiraIssueComments | any | the comments this run has added to that issue (none at the start) |
  | editJiraIssue | any | {ok: true} |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | createJiraIssue | any | {key: "PA-<n>"} (n starts at 60) |
  | updateConfluenceContent | any | {id: "5001", version: 3} |

  Items:

  | Key | Kind | summary | status | parent |
  |---|---|---|---|---|
  | PA-40 | Epic | Invitations | To Do | — |
  | PA-50 | Story | Invite a teammate by email | To Do | PA-40 |

  Descriptions as published:
  - PA-40 (Epic): slice "Invite teammates by email." Then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001` and `ADRs: ADR 0001 — docs/adr/0001-sessions.md — https://github.com/acme/app/blob/main/docs/adr/0001-sessions.md`
  - PA-50 (Story): user-story sentence "As a member, I want to invite a teammate by email, so that I can share the workspace." Then `## Acceptance Criteria` with `- [ ] An invite email is sent to the address entered.` Then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001`

  Key table on page 5001 (the shared context above it is unchanged):

  ```md
  ## Work Refs

  | outline id | kind | Work Ref | title |
  |---|---|---|---|
  | spec | Spec Page | https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001 | Team invites |
  | E1 | Epic | PA-40 | Invitations |
  | 1 | Story | PA-50 | Invite a teammate by email |
  ```
- Ledger / local files:
  - Today is 2026-11-25. The feature's slug is `team-invites`. `GLOSSARY.md` exists.
  - ADRs: the spec's ADR list has one entry, `docs/adr/0001-sessions.md`, which PA-40 already links.
  - `.power-architect/2026-11-24-team-invites/progress.md` exists. Its first line is `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/5001`, followed by a `## Work Refs` table with the same 3 rows as the key table.
  - Spec as now: Story 1's user-story sentence changed to "As a team admin, I want to invite a teammate by email, so that they can join the team." Its criterion is unchanged in the spec. The grouping is unchanged (Story 1 under Invitations). The Epic's slice in the spec is "Invite teammates by email, and let invitees accept from the link." The shared context is unchanged.
  - The change summary for this re-run therefore has one write: PA-50 updated (its sentence changed, so its summary and description are redrafted). Nothing else is in it: PA-40's membership did not change, so its slice is not in the summary.
  - Conversation so far: the user re-runs to-spec after changing the Story 1 sentence.

## When
The user runs `/power-architect:to-spec` and replies in order:
1. confirms the proposed test seam;
2. accepts the Large tier;
3. to any builder-check questions: "your call on all of them";
4. at the spec gate: "approved".

Then, at the change summary and its go-ahead question, the three runs differ:
- Run A: "go ahead"
- Run B: "go ahead, redraft the Epic slice"
- Run C: "no"

## Then
- Before Run A, Run B and Run C each, no MCP call of any kind is made before the user's "approved"
- In each run the change summary lists PA-50 as updated (new sentence, redrafted title and criteria), PA-40 is not listed, and nothing is created, held or removed. The agent asks the go-ahead question once, with the summary, in the form "Go ahead? Reply "go ahead", "go ahead, redraft <items>", or "no"." It waits for the reply before its first write
- Run A ("go ahead"): exactly one write call: `editJiraIssue` on PA-50 with `fields` `summary` and `description`. No `editJiraIssue` on PA-40 (the slice is not redrafted: "go ahead" redrafts nothing beyond the summary). No `addOrEditJiraIssueComment`, no `createJiraIssue`, no `updateConfluenceContent`. `publish` returns an empty `held` list and an empty `declined` list. The agent tells the user PA-50 was updated
- Run B ("go ahead, redraft the Epic slice"): the same summary write on PA-50, plus exactly one more write: `editJiraIssue` on PA-40 with `fields` `description` and `summary`, the slice redrafted from the spec's Epic slice, keeping its `Spec Page:` line and its ADR 0001 line. The writes run parents first: the PA-40 edit, then the PA-50 edit. Exactly two `editJiraIssue` calls in total; no other write. `held` and `declined` are empty. The agent tells the user PA-50 was updated and PA-40's slice was redrafted
- Run C ("no"): zero write calls. No `editJiraIssue`, `createJiraIssue`, `addOrEditJiraIssueComment`, `createConfluenceContent` or `updateConfluenceContent`. No comment is added on PA-50. `publish` returns `declined` with PA-50 and an empty `held` list. The agent tells the user nothing was written and lists PA-50 as declined, not as held
- No `executeDestructive` call and no transition, Sprint or board call in any run
