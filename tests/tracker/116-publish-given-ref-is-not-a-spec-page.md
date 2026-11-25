# 116: A Work Ref or URL the user gives must be a Spec Page: an answer that is not one asks once more, and a second such answer stops with nothing written

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
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name. Rows are matched top to bottom. The stub keeps state within this dry run. There is no search tool in this table: a search call has no row to match.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getContentFormatGuide | any | "Markdown is accepted. Tables and task lists (`- [ ]`) are supported." |
  | createConfluenceContent | title "Team invites" | error: a page titled "Team invites" already exists in space PASPEC (a create rejected as a duplicate title) |
  | getConfluenceContent | page 7001 | {id: "7001", title: "Team invites notes", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/7001", body (Markdown): "Meeting notes for the invitations work. No key table on this page."} |
  | getJiraIssue | PA-40 | {key: "PA-40", summary: "Invitations", issuetype: "Epic", status: "To Do"} |
  | createJiraIssue | any | {key: "PA-<n>"} (n starts at 50) |
  | updateConfluenceContent | any | {id: "5001" or "6001", version: 2} |

- Ledger / local files:
  - Today is 2026-11-24. The feature's slug is `team-invites`. There are no ADRs. `GLOSSARY.md` exists.
  - There is no `.power-architect/` directory: no ledger, and no Work Ref was recorded.
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

The Spec Page title is "Team invites", and its create is rejected as a duplicate title. The agent asks the duplicate-title question. The user answers: "https://acme.atlassian.net/browse/PA-40". The agent asks once more. The user answers: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/7001".

## Then
- No MCP call of any kind is made before the user's "approved"
- No search call is made anywhere in the run: no `searchConfluence`, and no CQL or JQL query of any kind
- The first Spec Page create (`createConfluenceContent`, title "Team invites") is the first write attempted, and it is rejected as a duplicate title; nothing else is written before the question
- The first answer, a Jira issue URL, is not a Spec Page: the agent does not treat PA-40 as the Spec Page (no `getJiraIssue` makes it the Spec Page, and no re-run starts from it), and asks once more, word for word: "A page with this title already exists. Give me the Work Ref or URL of this spec's Spec Page: a page in the space PASPEC that has its key table (`## Work Refs`). Otherwise give a different title."
- The agent waits for the answer; no write call is made before it
- The second answer is a page in the space PASPEC with no `## Work Refs` key table: `getConfluenceContent` on page 7001 shows no key table, so it is not a Spec Page. The agent stops and says nothing was written
- After the second invalid answer the agent asks no third question, makes no re-run and no change summary, and asks for no go-ahead
- No write call of any kind is made in the run: no `createJiraIssue`, no `editJiraIssue`, no `addOrEditJiraIssueComment`, no `updateConfluenceContent`, and no second `createConfluenceContent` (with any title)
- No ledger `.power-architect/2026-11-24-team-invites/progress.md` is written, and no Work Ref is recorded
- The agent tells the user the draft is still at `.power-architect/2026-11-24-team-invites/spec-draft.md` under the ledger root, in the same message as the stop
- No Sprint or board call, and no transition
</content>
