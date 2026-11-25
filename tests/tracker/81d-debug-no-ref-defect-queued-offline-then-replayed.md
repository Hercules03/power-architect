# 81d: a no-ref defect found while Jira is unreachable is queued with ref `-`, never blocks another no-ref defect, and is replayed through the open-Bug search

(Red first: against the pre-round-2 text, Run B fails because "Steps 1 and 3 apply" queued every no-ref defect behind the first unsent one, and Run D fails because replay skipped later no-ref entries behind a `[!]` entry. Runs A, C1 and C2 are not claimed to fail there.)

**Phase:** /power-architect:debug

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
  | getJiraIssue | PA-60 | {key: "PA-60", type: Sub-task, summary: "Failed-login counter", status: Done, parent: PA-50} |
  | getJiraIssue | PA-61 | {key: "PA-61", type: Sub-task, summary: "Login handler enforces the lockout", status: In Progress, parent: PA-50} |
  | getJiraIssue | PA-70 | the Bug this dry run created |
  | getJiraIssue | PA-72 | {key: "PA-72", type: Bug, summary: "Password-reset mail greets users as undefined", status: To Do, description: "Symptom: the mail sent after a password reset opens with `Hello, undefined`.\nRepro: a user named Zoë asks for a reset and opens the mail.\nRoot cause: the mail template reads `user.name` but the user record only has `displayName`."} |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | createJiraIssue | any | {key: "PA-<n>"} (n increments from 70). Live input schema: `cloudId`, `projectKey`, `issueTypeName`, `summary`, `description`, `contentFormat`, `parent`, `assignee_account_id`, `additional_fields`, `sprintId`, `assignToBacklog`, `boardId` |
  | searchJiraIssuesUsingJql | any | the issues in this table that match the JQL, with this dry run's own creations (none at the start) |
- Ledger / local files:
  - Today is 2026-11-25. `.power-architect/bugs/progress.md` (in the main checkout) does not exist yet. No `Task` line anywhere; nothing is being built.
  - Run A: `atlassianUserInfo` and every Rovo call fail (Jira unreachable). Run B (later, a second no-ref defect, "the export button does nothing"): Jira is reachable while run A's entry is still `- [ ]`. Run C (a `pull` later): Jira reachable. In C1 the stub's `searchJiraIssuesUsingJql` returns no open Bug for q1. In C2 it returns PA-72 (an open Bug created by a timed-out earlier attempt of q1; its summary and description are in the table above). Run D (separate start): the Given's ledger below, Jira reachable.
  - q1's evidence (reset-email defect), four lines: `Symptom: the password-reset email starts with "Hello, undefined".` / `Repro: a user named Zoë requests a reset and opens the email.` / `Root cause: the template reads user.name, but the field is displayName.` / `Found while working on no tracked item`. PA-72 describes the same symptom and the same root cause in different words, so it is the same defect.
  - Run D ledger: `- [!] q1 | defect | - | <q1 evidence on one line> | failed: Jira rejected the create (400)` then `- [ ] q2 | defect | - | Symptom: the export button does nothing. / Repro: click Export on the reports page. / Root cause: the click handler is never bound. / Found while working on no tracked item`. q2 is a different defect from q1 and from PA-72.
- Execution outcomes (take as given): each run reaches clean-up with a proven root cause, `record(defect, …)` with no ref; evidence four lines as in scenario 81.
- Trace: report files read, ledger writes, Tracker operations and MCP calls in one chronological list.

## When
The user runs `/power-architect:debug` (run A) on the reset-email defect with Jira unreachable. Later the user runs `/power-architect:debug` (run B) on a second defect with Jira reachable. Later a `pull` reaches Jira (run C), twice in two variants, each starting from the state after Run A only (Run B's writes, including its created PA-70 export-button Bug, are NOT present): C1 the search finds no open Bug for q1; C2 the search finds PA-72, already created by a timed-out earlier attempt of q1. Run D: a `pull` reaches Jira with the Run D ledger.

## Then
- Run A: `record` returns `queued`; the file `<ledger root>/.power-architect/bugs/progress.md` has first line `# Ledger — bugs` and the entry `- [ ] q1 | defect | - | <evidence on one line>`; no `createJiraIssue`; the phase carries on
- Run B: the entry for the first defect is `[ ]` but the second defect is NOT queued behind it: the adapter searches open Bugs and creates (or comments on) normally; the bugs ledger gains no `q2` line
- Run C1: replay reaches q1, runs the open-Bug search first, finds none, makes exactly one `createJiraIssue` (Bug, no parent, no Sprint field), and marks q1 `- [x]`
- Run C2 (from the state after Run A only): replay of q1 runs the open-Bug search, finds PA-72, judges it the same defect (same symptom, same root cause), makes exactly one `addOrEditJiraIssueComment` on PA-72 whose first line is `Defect seen again`, makes no `createJiraIssue`, and marks q1 `- [x]`
- Run D: replay does NOT skip q2 because of q1's `[!]` (entries with ref `-` are independent); q2 is replayed through the open-Bug search (one comment on a matching open Bug, or exactly one `createJiraIssue`); q2 becomes `- [x]`; q1 stays `- [!]`; the user is told how to clear q1: change it to `- [ ]` to retry, or `- [x]` if it was applied by hand
