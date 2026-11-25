# 37: A Small spec whose Story goes under a new Epic creates the Epic first, then the Story under it; a rejected Epic parent stops the publish and reports what was made

**Phase:** /power-architect:to-spec

## Given
- Repo instructions file (AGENTS.md): `## Tracker` section:
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
  status-in-progress: In Progress
  status-done: Done
  link-blocks: Blocks
  link-relates: Relates
  ```
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name. Rows are matched top to bottom. One counter `n` is shared by every successful `createJiraIssue`, starting at 40.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | getAccessibleAtlassianResources | any | [{id: "11111111-2222-3333-4444-555555555555", url: "https://acme.atlassian.net", name: "acme"}] |
  | discover | any | the tools in this table whose names match the query |
  | getContentFormatGuide | any | "Markdown is accepted. Tables and task lists (`- [ ]`) are supported." |
  | createConfluenceContent | any | {id: "4200", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4200"} |
  | createJiraIssue | issueType=Epic | {key: "PA-<n>"} |
  | createJiraIssue | issueType=Story | {key: "PA-<n>"} |
  | updateConfluenceContent | any | {id: "4200", version: 2} |

- Ledger / local files:
  - Today is 2026-11-24. The feature's slug is `invoice-audit-log`. `origin` is `git@github.com:acme/onboard.git`; the current branch is `main`. There are no ADRs on invoice access. `GLOSSARY.md` exists.
  - Conversation so far: a finished `/power-architect:grill` session settled one small change at one seam (the invoices HTTP endpoint). Nothing is left open. User story: 1. As an org admin, I want to see who downloaded an invoice, so that finance can audit access. Acceptance criterion: GET /invoices/:id/downloads lists each download with its user and time.
  - Settled test seam: the invoices HTTP endpoint.
  - No existing Epic fits: the user wants a new one.

## When
The user runs `/power-architect:to-spec` and replies in order:
1. confirms the proposed test seam;
2. accepts the Small tier;
3. when asked which Epic the Story goes under: "new, called Audit trail";
4. at the spec gate: "approved".

Variant (Jira rejects the Epic as the Story's parent): the user gives the same replies 1–4, and the stub's Story create returns the error in the Given's table below.

Variant stub row, replacing the `createJiraIssue | issueType=Story` row above: `createJiraIssue | issueType=Story | error: 400 "Epic PA-40 cannot be the parent of a Story in this project"`

## Then
- No MCP call of any kind is made before the user's "approved"
- The agent asks once which Epic the Story goes under (an existing Epic or a new one with a name), and the user's answer is a new Epic named "Audit trail"
- `publish(outline)` is called once, with Scope Tier Small, a Spec Page, one new Epic (outline id `E1`, name "Audit trail", with its own slice) and one Story (outline id `1`) whose parent is `E1`
- The MCP calls, in order: a connection check (`atlassianUserInfo`) → `createConfluenceContent` (space id `98765`) → `createJiraIssue` with issue type `Epic` and summary "Audit trail" (PA-40) → `createJiraIssue` with issue type `Story` and parent `PA-40` (PA-41) → `updateConfluenceContent` on page `4200`. (A `discover` or `getContentFormatGuide` read may appear after the connection check)
- The Epic is created before the Story, and the Story is never created without its Epic's key
- The Epic's description holds its slice and `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4200`. The Story's description starts with its user-story sentence alone as the first paragraph, then `## Acceptance Criteria` with a `- [ ]` line, then the Spec Page link
- The key table on the Spec Page has rows: the Spec Page, `E1 | Epic | PA-40 | Audit trail`, and `1 | Story | PA-41 | <Story title>`
- No search call is made on this first publish, and no `createJiraIssue` with issue type `Epic` is called more than once
- No edit call on any item, and no Sprint or board call; no sprint, priority, story-point or estimate field is passed
- The ledger `.power-architect/2026-11-24-invoice-audit-log/progress.md` starts with `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4200` and lists the three Work Refs (spec, PA-40, PA-41)
- The agent tells the user the Spec Page link, the Epic PA-40 and the Story PA-41

Variant (Jira rejects the Epic as the Story's parent), stub row per the Variant above:
- The Epic `PA-40` is created, then the Story create is rejected: the Story is not created and no key is returned for it
- The publish stops at once: no retry of the Story, and no `updateConfluenceContent` (no key table is written)
- The agent tells the user that Jira rejected Epic `PA-40` as the parent of Story "<Story title>", quotes Jira's error text exactly ("Epic PA-40 cannot be the parent of a Story in this project"), and says the spec is only partly published
- The agent's report lists exactly what was created: the Spec Page (page `4200`, its URL) and Epic `PA-40` "Audit trail"; and what was not: the Story
- The ledger `.power-architect/2026-11-24-invoice-audit-log/progress.md` is written with first line `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4200` and a `## Work Refs` table holding exactly two rows: the spec and `E1 | Epic | PA-40 | Audit trail`
- No second Epic and no second Story is created, and no Sprint or board call is made
