# 31: A Small spec creates one Story under the Epic the user names, with no grouping table

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
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name. One counter `n` is shared by every successful `createJiraIssue`, starting at 30.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | getAccessibleAtlassianResources | any | [{id: "11111111-2222-3333-4444-555555555555", url: "https://acme.atlassian.net", name: "acme"}] |
  | discover | any | the tools in this table whose names match the query |
  | getContentFormatGuide | any | "Markdown is accepted. Tables and task lists (`- [ ]`) are supported." |
  | createConfluenceContent | any | {id: "4100", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4100"} |
  | createJiraIssue | any | {key: "PA-<n>"} |
  | updateConfluenceContent | any | {id: "4100", version: 2} |

- Ledger / local files:
  - Today is 2026-11-24. The feature's slug is `invoice-csv`.
  - `origin` is `git@github.com:acme/onboard.git`; the current branch is `main`. `GLOSSARY.md` exists; there are no ADRs on billing exports.
  - Conversation so far: a finished `/power-architect:grill` session settled a small change at one seam (the invoices HTTP endpoint). Nothing is left open. User stories: 1. As an org admin, I want to download all invoices for a year as one CSV file, so that finance can import them. 2. As an org admin, I want the CSV to include the tax amount per invoice, so that finance can file returns.
  - Settled test seam: the invoices HTTP endpoint.

## When
The user runs `/power-architect:to-spec` and replies in order:
1. confirms the proposed test seam;
2. accepts the Small tier;
3. when asked which Epic the Story goes under: "PA-7";
4. at the spec gate: "approved".

## Then
- The draft spec is written to `.power-architect/2026-11-24-invoice-csv/spec-draft.md`; `docs/specs/` is not written
- No Epic grouping table is shown
- The agent asks once which Epic the Story goes under (an existing Epic or a new one with a name)
- No MCP call of any kind is made before the user's "approved"
- `publish(outline)` is called once with Scope Tier Small, a Spec Page, the existing Epic `PA-7` and exactly one Story that carries both user-story sentences and Acceptance Criteria for both
- The MCP calls, in order: a connection check → `createConfluenceContent` → exactly one `createJiraIssue` (issue type `Story`, parent `PA-7`, key PA-30) → `updateConfluenceContent` on page `4100`. (A `discover` or `getContentFormatGuide` read may appear after the connection check)
- No `createJiraIssue` with issue type `Epic`, and no edit call on `PA-7`
- The key table written to the Spec Page has a row for the Spec Page and a row for the Story (PA-30), and no row for `PA-7`
- The ledger `.power-architect/2026-11-24-invoice-csv/progress.md` starts with `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4100`
- No Sprint or board call; no sprint, priority, story-point or estimate field is passed
