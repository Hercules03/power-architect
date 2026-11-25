# 52: A Small plan publishes one Sub-task per task under the spec's one Story, each carrying its exact files, steps and commands

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
  | getConfluenceContent | page 6001 | {id: "6001", title: "Login lockout", url: "https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001", body (Markdown): the shared context below, then the key table below (after an update by this dry run, that update's body)} |
  | getJiraIssue | PA-50 | {key: "PA-50", type: Story, summary: "Lock out repeated failed logins", status: To Do, parent: PA-5, description: "As a user, I want my account locked for 15 minutes after five failed logins in 10 minutes, so that my password can't be guessed.", then `## Acceptance Criteria` with `- [ ] The sixth login attempt within 10 minutes after five failures returns 423.`, then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, no links} |
  | getJiraIssue | a key this dry run created | what this dry run created, status To Do, with the links this dry run made |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | listJiraIssueLinkTypes | any | [{name: "Blocks", outward: "blocks", inward: "is blocked by"}, {name: "Relates", outward: "relates to", inward: "relates to"}] |
  | createJiraIssue | any | {key: "PA-<n>"} (n starts at 60) |
  | createJiraIssueLink | any | {ok: true}. Its live input schema: `type` (the link type's name); `outwardIssue` (the issue the type's outward text describes: `<outwardIssue> blocks <inwardIssue>`); `inwardIssue` (the issue the inward text describes: `<inwardIssue> is blocked by <outwardIssue>`) |
  | editJiraIssue | any | {ok: true} |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | updateConfluenceContent | any | {id: "6001", version: 3} |

  Spec Page shared context: the sections Problem Statement, Solution, Goals / Non-goals / Anti-goals, Approaches considered, Implementation Decisions, Testing Decisions (seam: the login HTTP endpoint), Out of Scope, Scope Tier (`Small`) and Further Notes of the spec "Login lockout". There is no `## Plan` section. PA-5 is the user's existing Epic "Security"; it was not created from this spec.

  Key table on page 6001:

  ```md
  ## Work Refs

  | outline id | kind | Work Ref | title |
  |---|---|---|---|
  | spec | Spec Page | https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001 | Login lockout |
  | 1 | Story | PA-50 | Lock out repeated failed logins |
  ```
- Ledger / local files:
  - Today is 2026-11-24. `.power-architect/2026-11-24-login-lockout/progress.md` exists. Its first line is `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, followed by a `## Work Refs` table with the same 2 rows as the key table. There is no `docs/specs/` file for this spec.
  - The codebase is TypeScript with Express, Redis and Vitest. The plan the agent drafts (take it as given: exploring the codebase finds nothing that changes it):
    - Goal: Lock an account for 15 minutes after five failed logins within 10 minutes.
    - Architecture: A counter module records failed logins per account in the existing Redis store. The login handler asks it before checking the password and records each failure.
    - Tech Stack: TypeScript, Express, Redis, Vitest.
    - Global Constraints: five failures within 10 minutes lock the account; the lock lasts 15 minutes; a locked login returns 423.
    - Review Focus: failures for different accounts never share a counter (test `counts failures per account`, Task 1).
    - Task 1 "Failed-login counter". Files: Create `src/auth/attempts.ts`; Test `tests/auth/attempts.test.ts`. Interfaces: Produces `recordFailure(accountId: string): Promise<number>` and `isLocked(accountId: string): Promise<boolean>`. Steps: (1) write the failing test `counts failures per account` in `tests/auth/attempts.test.ts`: five failures lock the account, another account stays unlocked; (2) run `npx vitest run tests/auth/attempts.test.ts`, expected FAIL with "recordFailure is not a function"; (3) implement `recordFailure` and `isLocked` in `src/auth/attempts.ts` with a Redis key per account and a 10-minute expiry; (4) run `npx vitest run tests/auth/attempts.test.ts`, expected PASS; (5) commit with `git add src/auth/attempts.ts tests/auth/attempts.test.ts && git commit -m "feat: count failed logins"`.
    - Task 2 "Login handler enforces the lockout". Files: Modify `src/auth/login.ts:40-62`; Test `tests/auth/login.test.ts`. Interfaces: Consumes `recordFailure` and `isLocked` from Task 1. Steps: (1) write the failing test `returns 423 after five failures` in `tests/auth/login.test.ts`; (2) run `npx vitest run tests/auth/login.test.ts`, expected FAIL with "expected 423, got 401"; (3) in `src/auth/login.ts`, call `isLocked` before the password check and `recordFailure` on each failure; (4) run `npx vitest run tests/auth/login.test.ts`, expected PASS; (5) commit with `git add src/auth/login.ts tests/auth/login.test.ts && git commit -m "feat: lock out repeated failed logins"`.

## When
The user runs `/power-architect:plan` and replies in order:
1. when asked to review the plan and pick an execution method: "approved, subagent-driven";
2. if shown a change summary and asked to go ahead: "go ahead".

## Then
- The agent calls `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001, outline)` before drafting (reads only), and it returns Scope Tier Small and the one Story PA-50 with its Acceptance Criteria
- The plan is drafted to `.power-architect/2026-11-24-login-lockout/plan-draft.md` with the plan header and both tasks. Nothing is written under `docs/plans/` and nothing under `docs/specs/` is read
- No MCP write call of any kind is made before the user's "approved"
- After approval, `publish(outline)` is called once, with a Plan section and 2 Sub-tasks (outline ids 1 and 2, both under Story 1, Sub-task 2 blocked by 1)
- The MCP writes, in order: `createJiraIssue` with issue type `Sub-task`, parent PA-50, summary "Failed-login counter" → PA-60 → `createJiraIssue` with issue type `Sub-task`, parent PA-50, summary "Login handler enforces the lockout" → PA-61 → exactly one `createJiraIssueLink` with type `Blocks`, `outwardIssue` PA-60 and `inwardIssue` PA-61 → one `updateConfluenceContent` on page 6001, the last call
- PA-60's Markdown description carries `src/auth/attempts.ts` and `tests/auth/attempts.test.ts`, the produced signatures, the five steps as a `- [ ]` checklist, the command `npx vitest run tests/auth/attempts.test.ts`, the commit command, and the Spec Page link
- PA-61's Markdown description carries `src/auth/login.ts:40-62` and `tests/auth/login.test.ts`, the five steps as a `- [ ]` checklist, the command `npx vitest run tests/auth/login.test.ts`, its commit command, and the Spec Page link
- The `updateConfluenceContent` body is the shared context exactly as read, then a `## Plan` section with the Goal, Architecture, Tech Stack, Global Constraints and Review Focus, then the key table last: the 2 rows as read, then `1 | Sub-task | PA-60 | Failed-login counter` and `2 | Sub-task | PA-61 | Login handler enforces the lockout`
- No `editJiraIssue` or comment on PA-5 or PA-50, and no `Relates` link
- The ledger keeps its first line and its `## Work Refs` table lists 4 rows: the 2 as before, then the 2 Sub-tasks
- After publishing, the agent recommends `/power-architect:build`
- No Sprint or board call, no transition, no `executeDestructive` call; no create passes a sprint, backlog, priority, story-point or estimate field
