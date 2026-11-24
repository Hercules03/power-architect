# 47: A Small-tier re-run updates its one Story and never touches the Epic the user owns

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
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` / `executeWrite` matches the row with its own name. Rows are matched top to bottom. The stub keeps state within this dry run.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | discover | any | the tools in this table whose names match the query |
  | getContentFormatGuide | any | "Markdown is accepted. Tables and task lists (`- [ ]`) are supported." |
  | getConfluenceContent | page 4100 | {id: "4100", title: "Invoice CSV export", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4100", body (Markdown): exactly the Spec Page body the agent builds from the spec now, followed by the key table below} |
  | getJiraIssue | PA-30 | {key: "PA-30", summary: "Invoice CSV export", status: "To Do", parent: "PA-7", description: exactly what the adapter's create step writes for the Story from the spec as published} |
  | getJiraIssue | PA-7 | {key: "PA-7", summary: "Billing exports", status: "In Progress", type: "Epic", description: "Owned by the finance squad."} |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | editJiraIssue | any | {ok: true} |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | createJiraIssue | any | {key: "PA-<n>"} (n starts at 50) |
  | updateConfluenceContent | any | {id: "4100", version: 3} |

  Key table on page 4100:

  ```md
  ## Work Refs

  | outline id | kind | Work Ref | title |
  |---|---|---|---|
  | spec | Spec Page | https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4100 | Invoice CSV export |
  | 1 | Story | PA-30 | Invoice CSV export |
  ```
- Ledger / local files:
  - Today is 2026-11-24. The feature's slug is `invoice-csv`. `GLOSSARY.md` exists; there are no ADRs on billing exports.
  - `.power-architect/2026-11-24-invoice-csv/progress.md` exists. Its first line is `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/4100`, followed by a `## Work Refs` table with the same 2 rows as the key table.
  - Spec as published earlier today (Small tier, title "Invoice CSV export", one Story "Invoice CSV export" under the user's existing Epic PA-7). Settled test seam: the invoices HTTP endpoint. User stories: 1. As an org admin, I want to download all invoices for a year as one CSV file, so that finance can import them (criterion: GET /invoices.csv?year=2026 returns one row per invoice). 2. As an org admin, I want the CSV to include the tax amount per invoice, so that finance can file returns (criterion: every row has a tax_amount column).
  - Spec now: the same, plus a third user story: 3. As an org admin, I want the CSV to show each invoice's currency, so that finance never guesses it (criterion: every row has a currency column).
  - Conversation so far: the user re-ran `/power-architect:grill`, which added the third user story, and now re-runs to-spec.

## When
The user runs `/power-architect:to-spec` and replies in order:
1. confirms the proposed test seam;
2. accepts the Small tier;
3. when asked which Epic the Story goes under: "PA-7";
4. at the spec gate: "approved";
5. when shown the change summary and asked to go ahead: "go ahead".

## Then
- No Epic grouping table is shown, and no MCP call of any kind is made before the user's "approved"
- The change summary, shown before any write, lists PA-30 as updated and nothing created, re-parented, held or removed. It does not list PA-7
- The only write call is one `editJiraIssue` on PA-30 whose Markdown description carries all three user-story sentences and all three criteria; it does not change PA-30's parent
- No write call names PA-7: no `editJiraIssue`, `addOrEditJiraIssueComment` or other write on PA-7, and PA-7 is never reported as "removed from spec" or held
- No `createJiraIssue` (no new Epic or Story) and no `updateConfluenceContent` (the key table is unchanged and still has no row for PA-7)
- `publish` returns an empty `held` list; the ledger keeps the same 2 Work Refs
- No `createConfluenceContent` call, no Sprint or board call, no transition, and no `executeDestructive` call
