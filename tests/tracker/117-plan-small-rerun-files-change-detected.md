# 117: A Small plan re-run where only a task's Files changed updates a not-started Sub-task in place and holds a started one with the changed Files lines

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
  | getJiraIssue | PA-50 | {key: "PA-50", type: Story, summary: "Lock out repeated failed logins", status: To Do, parent: PA-5, description: "As a user, I want my account locked for 15 minutes after five failed logins in 10 minutes, so that my password can't be guessed.", then `## Acceptance Criteria` with `- [ ] The sixth login attempt within 10 minutes after five failures returns 423.`, then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, no links} |
  | getJiraIssue | PA-60, PA-61 | PA-60: summary "Failed-login counter", status To Do, parent PA-50; PA-61: summary "Login handler enforces the lockout", status In Progress, parent PA-50. Each `description` is exactly what the adapter's create step wrote for that task from the plan as published (the Files, Interfaces and steps lines below). Links: PA-60 blocks PA-61 (type `Blocks`), no others |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | listJiraIssueLinkTypes | any | [{name: "Blocks", outward: "blocks", inward: "is blocked by"}, {name: "Relates", outward: "relates to", inward: "relates to"}] |
  | createJiraIssue | any | {key: "PA-<n>"} (n starts at 60) |
  | createJiraIssueLink | any | {ok: true}. Its live input schema: `type` (the link type's name); `outwardIssue` (the issue the type's outward text describes); `inwardIssue` (the issue the inward text describes) |
  | editJiraIssue | any | {ok: true} |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | updateConfluenceContent | any | {id: "6001", version: 3} |

  Spec Page shared context: the sections Problem Statement, Solution, Goals / Non-goals / Anti-goals, Approaches considered, Implementation Decisions, Testing Decisions (seam: the login HTTP endpoint), Out of Scope, Scope Tier (`Small`) and Further Notes of the spec "Login lockout". PA-5 is the user's existing Epic "Security"; it was not created from this spec.

  Key table on page 6001:

  ```md
  ## Work Refs

  | outline id | kind | Work Ref | title |
  |---|---|---|---|
  | spec | Spec Page | https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001 | Login lockout |
  | 1 | Story | PA-50 | Lock out repeated failed logins |
  | 1 | Sub-task | PA-60 | Failed-login counter |
  | 2 | Sub-task | PA-61 | Login handler enforces the lockout |
  ```
- Ledger / local files:
  - Today is 2026-11-24. `.power-architect/2026-11-24-login-lockout/progress.md` exists. Its first line is `# Ledger — spec: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`, followed by a `## Work Refs` table with the same 4 rows as the key table. There is no `docs/specs/` file for this spec.
  - The codebase is TypeScript with Express, Redis and Vitest. The plan as published earlier today (Small tier):
    - Goal: Lock an account for 15 minutes after five failed logins within 10 minutes.
    - Architecture: A counter module records failed logins per account in the existing Redis store. The login handler asks it before checking the password and records each failure.
    - Tech Stack: TypeScript, Express, Redis, Vitest.
    - Global Constraints: five failures within 10 minutes lock the account; the lock lasts 15 minutes; a locked login returns 423.
    - Review Focus: failures for different accounts never share a counter (test `counts failures per account`, Task 1).
    - Task 1 "Failed-login counter". Files: Create `src/auth/attempts.ts`; Test `tests/auth/attempts.test.ts`. Interfaces: Produces `recordFailure(accountId: string): Promise<number>` and `isLocked(accountId: string): Promise<boolean>`. Steps: (1) write the failing test `counts failures per account` in `tests/auth/attempts.test.ts`; (2) run `npx vitest run tests/auth/attempts.test.ts`, expected FAIL with "recordFailure is not a function"; (3) implement both functions in `src/auth/attempts.ts` with a Redis key per account and a 10-minute expiry; (4) run `npx vitest run tests/auth/attempts.test.ts`, expected PASS.
    - Task 2 "Login handler enforces the lockout". Files: Modify `src/auth/login.ts:40-62`; Test `tests/auth/login.test.ts`. Interfaces: Consumes `recordFailure` and `isLocked` from Task 1. Steps: (1) write the failing test `returns 423 after five failures` in `tests/auth/login.test.ts`; (2) run `npx vitest run tests/auth/login.test.ts`, expected FAIL with "expected 423, got 401"; (3) in `src/auth/login.ts`, call `isLocked` before the password check and `recordFailure` on each failure; (4) run `npx vitest run tests/auth/login.test.ts`, expected PASS.
  - Sub-task status in the Tracker: PA-60 (Task 1) is To Do and PA-61 (Task 2) is In Progress. Nothing is Done yet.
  - Conversation so far: the user re-runs `/power-architect:plan` to change only the Files of the two tasks. Nothing else about the plan changes.

## When
The user runs `/power-architect:plan` and replies in order:
1. when asked to review the plan and pick an execution method: "Task 1 creates `src/auth/lockout.ts` and its test `tests/auth/lockout.test.ts` instead of the attempts files. Task 2 modifies `src/auth/login.ts:40-70`. Otherwise approved, subagent-driven.";
2. if the plan is shown again for review: "approved, subagent-driven";
3. if shown a change summary and asked to go ahead: "go ahead".

## Then
- The agent calls `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001, outline)` before drafting, and the plan shown for review takes each task's title, Files, Interfaces and steps from the Tracker as read, changed only by the two Files changes above
- No MCP write call of any kind is made before the change summary's "go ahead"
- The change summary, shown before any write, lists PA-60 as updated (its Files changed: the summary and description are rewritten in place) and PA-61 as held (it is In Progress and its Files changed). Nothing created, re-parented or removed; no link; the Plan section and the Story PA-50 are unchanged
- The agent asks one question after the summary, the go-ahead question ("Go ahead? Reply "go ahead", "go ahead, redraft <items>", or "no"."), and the user's "go ahead" answers it; no other question is asked
- The writes, in order: one `editJiraIssue` on PA-60 with `fields` `summary` and `description`, where the description's Files lines name `src/auth/lockout.ts` and `tests/auth/lockout.test.ts`, its Interfaces and steps stay as read, and it ends with `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`
- The only comment: one `addOrEditJiraIssueComment` on PA-61 with no comment id. Its first line is `Plan change not applied (item started)`. Its fenced code block holds only the changed Files lines, as `- Modify: src/auth/login.ts:40-62` and `+ Modify: src/auth/login.ts:40-70`, and no step or Interfaces line. Its last line is `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`
- PA-61 is never edited: no `editJiraIssue` on PA-61, no transition. PA-60's status is not changed
- No `createJiraIssue`, no `createJiraIssueLink`, and no `updateConfluenceContent` (the Plan section, the shared context and the key table did not change)
- `publish` returns `held` with PA-61 and its reason (started, Files changed), and the agent tells the user PA-61 was held and why, and that PA-60 was updated in place
- Second run is not part of this scenario. No Sprint or board call, no transition, no `executeDestructive` call
</content>
