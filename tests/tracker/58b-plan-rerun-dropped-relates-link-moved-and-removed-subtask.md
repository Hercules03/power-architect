# 58b: A Large plan re-run keeps a dropped relates link and comments on it, re-parents a not-started Sub-task moved to another Story, and comments once on a Sub-task removed from the plan without deleting it

**Phase:** /power-architect:plan

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
  | getConfluenceContent | page 6001 | {id: "6001", title: "Login lockout", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): the shared context below, then the `## Plan` section below, then the key table below (after an update by this dry run, that update's body)} |
  | getJiraIssue | PA-50, PA-51 | the Stories in the Items table below, with `description` exactly what the adapter's create step writes for each from the spec as published |
  | getJiraIssue | PA-60, PA-61, PA-62 | the Sub-tasks in the Items table below, with `description` exactly what the adapter's create step writes for each from the plan as published, and the links shown in the table |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | listJiraIssueLinkTypes | any | [{name: "Blocks", outward: "blocks", inward: "is blocked by"}, {name: "Relates", outward: "relates to", inward: "relates to"}] |
  | editJiraIssue | any | {ok: true} |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | updateConfluenceContent | any | {id: "6001", version: 3} |

  Items:

  | Key | Kind | summary | status | parent | links |
  |---|---|---|---|---|---|
  | PA-50 | Story | Lock out repeated failed logins | To Do | PA-5 | none |
  | PA-51 | Story | Show a lockout notice | To Do | PA-5 | none |
  | PA-60 | Sub-task | Failed-login counter | To Do | PA-50 | relates PA-51 (type `Relates`) |
  | PA-61 | Sub-task | Lockout notice text | To Do | PA-50 | blocked by PA-60 (type `Blocks`) |
  | PA-62 | Sub-task | Clear the lock on reset | To Do | PA-50 | blocked by PA-61 (type `Blocks`) |

  PA-5 is the user's existing Epic "Security"; it was not created from this spec. PA-50 and PA-51 are Stories under PA-5 for this spec.

  Spec Page shared context: the sections Problem Statement, Solution, Goals / Non-goals / Anti-goals, Approaches considered, Implementation Decisions, Testing Decisions, Out of Scope, Scope Tier (`Large`) and Further Notes of the spec "Login lockout", as the spec was published.

  `## Plan` section on page 6001, as published:

  ```md
  ## Plan

  | ticket | title | Blocked by |
  |---|---|---|
  | 01 | Failed-login counter | None |
  | 02 | Lockout notice text | 01 |
  | 03 | Clear the lock on reset | 02 |
  ```

  Key table on page 6001:

  ```md
  ## Work Refs

  | outline id | kind | Work Ref | title |
  |---|---|---|---|
  | spec | Spec Page | https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001 | Login lockout |
  | 1 | Story | PA-50 | Lock out repeated failed logins |
  | 2 | Story | PA-51 | Show a lockout notice |
  | 01 | Sub-task | PA-60 | Failed-login counter |
  | 02 | Sub-task | PA-61 | Lockout notice text |
  | 03 | Sub-task | PA-62 | Clear the lock on reset |
  ```
- Ledger / local files:
  - Today is 2026-11-24. `.power-architect/2026-11-24-login-lockout/progress.md` exists. Its first line is `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, followed by a `## Work Refs` table with the same 6 rows as the key table. There is no `docs/specs/` file for this spec. The codebase is TypeScript with Express, Redis and Vitest.
  - The plan's three Sub-tasks are all To Do. Each Sub-task's parent Story is as in the Items table. Sub-task 01 relates to Story 2 (`relates` link, recorded at the first plan publish).
  - Conversation so far: the plan was published earlier today. The user now re-runs `/power-architect:plan` to change the plan in this session.

## When
The user runs `/power-architect:plan` and replies in order:
1. when asked to review the plan, the user answers: "Drop the relates link from Failed-login counter to Show a lockout notice. Move Lockout notice text under Show a lockout notice (Story 2). Remove Clear the lock on reset. Otherwise approved.";
2. at the change summary: "go ahead".

## Then
- Before drafting, the run calls `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001, outline)`, and the plan shown for review takes the Sub-tasks' titles, parents and links from the Tracker as read, plus the three changes the user asked for
- No MCP write call of any kind is made before the change summary's "go ahead"
- The change summary, shown before any write, lists: Failed-login counter (PA-60) held, because its relates link to PA-51 is dropped and the link stays; Lockout notice text (PA-61) re-parented from PA-50 to PA-51; Clear the lock on reset (PA-62) held as removed from the plan. Nothing else is created, updated or re-parented
- The go-ahead is asked once, and the run waits for "go ahead" before the first write
- Write 1: `addOrEditJiraIssueComment` on PA-60, no comment id. Its first line is `Plan change not applied (links are never deleted)`, its fenced code block holds one `Relates to:` line showing PA-51 as the old key and no new key, and its last line is `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`. PA-60 is not otherwise edited
- Write 2: `editJiraIssue` on PA-61 with `fields` `parent` set to `PA-51`. No `addOrEditJiraIssueComment` on PA-61: it is re-parented, not held
- Write 3: `addOrEditJiraIssueComment` on PA-62, no comment id. Its first line is `Removed from plan`, and its text is `This item is no longer in the plan. It was not deleted or closed. Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`. It gets exactly one such comment
- Write 4 (last): one `updateConfluenceContent` on page 6001. The shared context is kept exactly as read. The `## Plan` section is replaced by a table with rows `01 | Failed-login counter | None` and `02 | Lockout notice text | 01`, because ticket 03 is no longer in the plan. The key table keeps the spec row, PA-50 and PA-51 unchanged, `01 | Sub-task | PA-60 | Failed-login counter`, `02 | Sub-task | PA-61 | Lockout notice text`, and `— | Sub-task | PA-62 | Clear the lock on reset`. No row is deleted, and no Work Ref changes
- `publish` returns `held` with PA-60 (its reason: the dropped relates link) and PA-62 (its reason: removed from the plan); the agent tells the user both and why
- No `createJiraIssue`, no `createJiraIssueLink`, and no `deleteJiraIssue` or other delete; no `executeDestructive` call. No transition, and no Sprint or board call
- Nothing is written to PA-50 or PA-51, and no comment is written on PA-61
- The ledger keeps its first line and the same 6 Work Refs
