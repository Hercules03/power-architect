<!--
Why this can fail against the text before this fix: plan's Re-plan drafted afresh each session, so session 2
words step 6 differently from session 1 (both wordings are fixed below). The held change never reaches Jira, so
session 2 re-adds it in new words; the de-duplication (first line + normalised code-block lines) then misses
session 1's comment and a second comment is added. Session 2's "no second comment" line fails.
-->
# 57: A started Sub-task whose approved steps changed is left untouched, gets one comment holding only the change across sessions, and is listed as held

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
  | getJiraIssue | PA-60, PA-61 | PA-60: summary "Failed-login counter", status Done, parent PA-50; PA-61: summary "Login handler enforces the lockout", status In Progress, parent PA-50. Each `description` is exactly what the adapter's create step writes for that task from the plan as published. Links: PA-60 blocks PA-61 (type `Blocks`), no others |
  | listJiraIssueComments | any | the comments this dry run has added to that issue (none at the start) |
  | listJiraIssueLinkTypes | any | [{name: "Blocks", outward: "blocks", inward: "is blocked by"}, {name: "Relates", outward: "relates to", inward: "relates to"}] |
  | createJiraIssue | any | {key: "PA-<n>"} (n starts at 60) |
  | createJiraIssueLink | any | {ok: true}. Its live input schema: `type` (the link type's name); `outwardIssue` (the issue the type's outward text describes: `<outwardIssue> blocks <inwardIssue>`); `inwardIssue` (the issue the inward text describes: `<inwardIssue> is blocked by <outwardIssue>`) |
  | editJiraIssue | any | {ok: true} |
  | addOrEditJiraIssueComment | any | {id: "c-<n>"} |
  | updateConfluenceContent | any | {id: "6001", version: 3} |

  Spec Page shared context: the sections Problem Statement, Solution, Goals / Non-goals / Anti-goals, Approaches considered, Implementation Decisions, Testing Decisions (seam: the login HTTP endpoint), Out of Scope, Scope Tier (`Small`) and Further Notes of the spec "Login lockout". Then a `## Plan` section, exactly what the adapter writes for this plan as published (Goal, Architecture, Tech Stack, Global Constraints, Review Focus). PA-5 is the user's existing Epic "Security"; it was not created from this spec.

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
  - The codebase is TypeScript with Express, Redis and Vitest. The plan as published earlier today:
    - Goal: Lock an account for 15 minutes after five failed logins within 10 minutes.
    - Architecture: A counter module records failed logins per account in the existing Redis store. The login handler asks it before checking the password and records each failure.
    - Tech Stack: TypeScript, Express, Redis, Vitest.
    - Global Constraints: five failures within 10 minutes lock the account; the lock lasts 15 minutes; a locked login returns 423.
    - Review Focus: failures for different accounts never share a counter (test `counts failures per account`, Task 1).
    - Task 1 "Failed-login counter". Files: Create `src/auth/attempts.ts`; Test `tests/auth/attempts.test.ts`. Interfaces: Produces `recordFailure(accountId: string): Promise<number>` and `isLocked(accountId: string): Promise<boolean>`. Steps: (1) write the failing test `counts failures per account` in `tests/auth/attempts.test.ts`: five failures lock the account, another account stays unlocked; (2) run `npx vitest run tests/auth/attempts.test.ts`, expected FAIL with "recordFailure is not a function"; (3) implement `recordFailure` and `isLocked` in `src/auth/attempts.ts` with a Redis key per account and a 10-minute expiry; (4) run `npx vitest run tests/auth/attempts.test.ts`, expected PASS; (5) commit with `git add src/auth/attempts.ts tests/auth/attempts.test.ts && git commit -m "feat: count failed logins"`.
    - Task 2 "Login handler enforces the lockout". Files: Modify `src/auth/login.ts:40-62`; Test `tests/auth/login.test.ts`. Interfaces: Consumes `recordFailure` and `isLocked` from Task 1. Steps: (1) write the failing test `returns 423 after five failures` in `tests/auth/login.test.ts`; (2) run `npx vitest run tests/auth/login.test.ts`, expected FAIL with "expected 423, got 401"; (3) in `src/auth/login.ts`, call `isLocked` before the password check and `recordFailure` on each failure; (4) run `npx vitest run tests/auth/login.test.ts`, expected PASS; (5) commit with `git add src/auth/login.ts tests/auth/login.test.ts && git commit -m "feat: lock out repeated failed logins"`.

  - Each session is new. If the agent drafted the plan afresh, it would word every step differently (same meaning, other words). In particular, the requested step 6 on Task 2 is worded in session 1 as `` - [ ] **Step 6: Run the whole suite**   Run: `npx vitest run`  Expected: PASS ``; a session 2 that drafted afresh would word it as `` - [ ] **Step 6: Run every test to confirm nothing else broke**   Run: `npx vitest run`  Expected: all tests PASS ``.
  - At the start of session 2, `listJiraIssueComments` on PA-61 returns exactly one comment: session 1's, first line `Plan change not applied (item started)`, whose code block holds the single line `` + - [ ] **Step 6: Run the whole suite**   Run: `npx vitest run`  Expected: PASS ``, then `Spec Page: https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001`.
  - Conversation so far: Task 1 is built (Done) and Task 2 is being built (In Progress). The user re-runs plan to add one step to Task 2.

## When
The user runs `/power-architect:plan` and replies in order:
1. when asked to review the plan and pick an execution method: "Add a final step 6 to Task 2: run `npx vitest run`, expected PASS (the whole suite). Otherwise approved, subagent-driven.";
2. if the plan is shown again for review: "approved, subagent-driven";
3. if shown a change summary and asked to go ahead: "go ahead".

Then, in a new session (session 2), the user runs `/power-architect:plan` a second time with the same request, and gives the same replies 1–3.

Variant (session 3, a new session after session 2): the user runs `/power-architect:plan` and replies in order:
1. when asked to review the plan and pick an execution method: "Add a final step 6 to Task 2: run `npx tsc --noEmit`, expected no errors. Otherwise approved, subagent-driven.";
2. if the plan is shown again for review: "approved, subagent-driven";
3. if shown a change summary and asked to go ahead: "go ahead".

## Then
- Each run calls `pull(https://acme.atlassian.net/wiki/spaces/PASPEC/pages/6001, outline)` before drafting, and the plan shown for review takes the Plan section and each task's title, files and steps from the Tracker as read, plus the requested step 6 on Task 2
- No MCP write call of any kind is made before the change summary's "go ahead"
- First run: the change summary, shown before any write, lists PA-61 as held because it is started and its approved steps changed; nothing created, updated, re-parented or removed; nothing for PA-60
- First run, the only write: one `addOrEditJiraIssueComment` on PA-61 with no comment id. Its first line is `Plan change not applied (item started)`, and its fenced code block holds only the added step as a `+` line (the `npx vitest run` step). It holds no other step text and no unchanged step
- PA-61 and PA-60 are never edited: no `editJiraIssue`, no transition. No `createJiraIssue`, no `createJiraIssueLink`, and no `updateConfluenceContent` (the Plan section and the titles did not change)
- `publish` returns `held` with PA-61 and its reason, and the agent tells the user PA-61 was held and why
- Second run: only reads; no write call of any kind. In particular no second comment on PA-61 (it has exactly one comment across both sessions), even though a fresh draft would word step 6 as in the Given's session 2 wording. PA-61 is still reported as held
- Second run: the plan shown for review takes Task 2's steps 1–5 from PA-61's description as read, not from a fresh draft; no `addOrEditJiraIssueComment` and no `editJiraIssue` on any item
- Variant (session 3): the only write is exactly one more `addOrEditJiraIssueComment` on PA-61 with no comment id (PA-61 then has exactly two comments). Its first line is `Plan change not applied (item started)`, and its code block holds only the added `npx tsc --noEmit` step as a `+` line: no `npx vitest run` step and no unchanged step. No other write of any kind
- The ledger lists the same 4 rows after every run. Nothing is written under `docs/plans/`
- No Sprint or board call, no `executeDestructive` call
