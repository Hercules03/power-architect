# /power-architect:build

Read [testing.md](testing.md) before the first task. It governs every step below.

- **Small tier**: Superpowers `subagent-driven-development` (S1) or `executing-plans` (S2), whichever the user picked at plan handoff.
- **Large tier**: Matt Pocock's `implement` (L1, one ticket) or `implement-spec` (L2, the whole ticket graph). With a Tracker, ask the Product Owner to put the Stories in a Sprint, then run `/power-architect:build` (the active Sprint) or `/power-architect:build <Work Ref>`.
  `Local:` L1 is `/power-architect:build 03`, L2 is `/power-architect:build all`.

A step with a `Local:` line below it reads two ways. With a Tracker configured, do what the step says. Without one (no `## Tracker` section), do only what its `Local:` line says.

## Work list (before Setup)

**Pull the work list first**, before Setup, so nothing is set up or built on a guess. Call `pull(scope, subtask)` (see the [Tracker contract](tracker.md#pullscope-level)). `/power-architect:build <Work Ref>` gives that Work Ref as `scope`: a Sub-task, or a Story (its unfinished Sub-tasks). With no argument, or `all`, `scope` is `sprint`: the active Sprint the Product Owner filled. Build nothing outside it, and never create, start, close or edit a Sprint.
- `pull` returns the ready items in `blocks` order, blockers first, each with its Work Ref, title, description, Story, its spec's Spec Page Work Ref and Scope Tier. Tell the user each item in its `blocked` list, with its blocker; never build one.
- If the ready list is empty after replay and `pull`, the build stops before Setup and says so: nothing is ready to build.
- If `pull` stops, stop the phase: set nothing up, build nothing, write nothing. If the Tracker was unreachable, tell the user nothing was built, and to re-run `/power-architect:build` once it is reachable. If the Work Ref is unknown, ask the user to check it and the ledger's first line.
- **One spec at a time.** After Setup, group the items by Spec Page Work Ref, and finish one spec's items, through its final review, before the next spec's. For each spec:
  - **Its ledger** is `<ledger root>/.power-architect/<spec-slug>/progress.md`, the one whose first line is `# Ledger — spec: <Spec Page Work Ref>` (to-spec and plan wrote it). Without one, write it: that first line, with `<spec-slug>` today's date and the spec title's slug. The **ledger root** is the main checkout, not a linked worktree: the parent directory of `git rev-parse --git-common-dir`, resolved to an absolute path. Ledgers and their queues live in the ledger root's `.power-architect/`, so a queue written from a worktree survives it; never delete that directory during a build. Every "ledger" below means this file. A ledger line names its Sub-task by Work Ref: `Task <Work Ref>: …`.
    `Local:` The ledger stays where it is today: `.power-architect/<plan-slug>/progress.md` in the current checkout, as below.
  - **Read the spec and plan once:** `pull(<Spec Page Work Ref>, outline)`. Its shared context is the spec, and its Plan section is the plan header (Global Constraints, Review Focus). A Large-tier Plan section is a ticket overview with no Review Focus. Write the outline to `<workspace>/spec.md` and give that path to every reviewer in place of a spec or plan path. Each Sub-task's description is its task (Small) or its ticket (Large), and its Story's Acceptance Criteria come with it.
  - **Route by its Scope Tier:** Small runs S1 or S2. Large runs L1 for one Sub-task and L2 for more.
- **Bugs.** A Bug in the work list is not part of any spec: leave it out of the spec grouping, and build it after every spec's items, with the debug method ([debug.md](debug.md): feedback loop, minimise, hypothesise, regression test **before** the fix, fix, clean-up) at any tier, in place of a task or ticket. Its brief is its description. Call `record(<Bug ref>, started)` before any work. Its ledger is `<ledger root>/.power-architect/bugs/progress.md` (the main checkout, like every Tracker-mode ledger), with first line `# Ledger — bugs` (write it if absent). Its completion line is `Task <Bug ref>: complete (commits a..b, tests: <cmd> → <result>)`, where `tests:` is the regression test's own command and its passing result (a Bug has no implementer run, which the Sub-task rule uses). Do not call `record(done)` for it yet: its Done is deferred until after the Bug review (see [Deferred Done](#deferred-done)). Do not call `record(defect)` for the Bug's own defect. Bugs never enter a spec's final review. If Bugs were built this run, review their commits together once, with the `/power-architect:review` method and without a spec. That review covers only the commits in the bugs ledger's `Task` lines from this run, and those of a resumed Bug line with no `Bug review: passed (<its Bug ref>)` line after it: its fixed point is the commit before the first of them. When it, after the fixes it prompts, leaves no Critical or Important finding open, add the ledger line `Bug review: passed (<Bug ref>)` to the bugs ledger, one per Bug in this run's work list (a Bug's marker covers only that Bug; a Bug not in this run's work list never gains a marker); then [Deferred Done](#deferred-done) applies to the Bugs.
  `Local:` No Bugs come back: there is no work list.
- **Resume.** An item whose ledger (a Bug's is the bugs ledger) already has a `Task <Work Ref>: complete` line is never rebuilt. `pull` returned it, so the Tracker has not recorded it done.
  - **S1 and L1 items** (their Done follows their own task review): call `record(<Work Ref>, done, <evidence>)` once, with the evidence from that line, before any other work. If the ledger's `## Tracker queue` already holds an unsent `done` for it, call nothing: replay delivers it.
  - **Deferred items** (see [Deferred Done](#deferred-done)) need the ledger marker that their review passed, a `Final review: passed (spec <Spec Page Work Ref>)` line (a Bug's: `Bug review: passed (<Bug ref>)`) written **after** the item's `Task` line. With the marker, call `record(<Work Ref>, done, <evidence>)` once, with the evidence from the item's line, before any other work, unless the queue already holds an unsent `done` for it: then call nothing. Without it, call no `record(done)`: run the missing review first, and Deferred Done then applies to the item. For an S2 item that is the [Final review](#final-review-both-s1-and-s2); for an L2 item it is L2 step 6, with steps 1–5 skipped; for a Bug it is the Bug review. A re-run after Done was withheld is the same: that review runs again over the diff described in its section, and if it leaves no Critical or Important finding open it writes the marker and fires Done.
- **Evidence** for `record(done)`: every commit from `a` to `b` of the line's `commits a..b`, both included (`git log --oneline a^..b`), or the PR URL; then the test command and its result. For a deferred item, list the commits of its spec's `Fix` lines once, after the item's own commits.
- **Deferred Done.** An S2, L2 or Bug item is a **deferred item**: its Done waits for the review that covers it. Its `record(<Work Ref>, started)` and its ledger completion line `Task <Work Ref>: complete (…)` stay per item, but `record(done)` is not called per item. On resume classify an item by the tokens of its ledger line only: it is deferred when its line carries the token `S2` or `L2`, or when it is a Bug. An S1 line (`review clean …`) and an L1 line (no `S2` or `L2` token) are never deferred. After the spec's final review and its one fix pass (for Bugs: the Bug review) have finished:
  - **No Critical or Important finding open:** write the marker line in the ledger (`Final review: passed (spec <Spec Page Work Ref>)`, or `Bug review: passed` in the bugs ledger), then call `record(<Work Ref>, done, <evidence>)` for every deferred item of that spec built this run, and for each resumed deferred item whose review has now passed, in ledger-line order. The evidence follows the Evidence rule above, taken from each item's ledger line.
  - **A Critical or Important finding still open:** write no marker and call no `record(done)` for the spec's deferred items from this run. They stay In Progress. Tell the user which findings are open and that Done is withheld; the user can fix them and re-run `/power-architect:build`. Any commit the user makes to fix them lies outside every `Task` and `Fix` range: the re-run's final review diffs the union of the spec's `Task` and `Fix` ranges plus the commits made since the last of those ranges, up to HEAD (a Bug's commits excluded).
  - Minor findings never block.
  A deferred `done` queues like any other `record`.
- **If `record` returns `queued`**, carry on: the event is in the ledger's `## Tracker queue` and the next `pull` that reaches the Tracker replays it. At the end of the build, tell the user which items' starts and completions are queued, not yet in the Tracker.

`Local:` No work list to pull. The argument (none, a ticket number, or `all`) and the plan or tickets choose the work, and the ledger is `.power-architect/<plan-slug>/progress.md`, as below.

## Setup (both tiers): isolated workspace (Superpowers `using-git-worktrees`)

1. **Detect existing isolation.** If `git rev-parse --git-dir` differs from `--git-common-dir` and you're not in a submodule, you're already in a linked worktree, so don't create another.
2. **Otherwise create one.** Prefer the harness's native worktree tool. The fallback is `git worktree add` under `.worktrees/`, after confirming that directory is git-ignored (add it to `.gitignore` and commit if not). If the sandbox blocks worktree creation, say so and work in place on a feature branch. **Never start implementation on main/master without the user's explicit consent.**
3. **Project setup:** install dependencies the way the project does (`npm install`, `cargo build`, `uv sync`, `go mod download`, …).
4. **Verify a clean baseline:** run the full test suite. If it fails, report the failures and ask whether to proceed or investigate.

---

## Small tier

Shared by S1 and S2:

- **Ledger.** Conversation memory doesn't survive compaction, and agents that lose their place re-do completed tasks. Keep `.power-architect/<plan-slug>/progress.md` (git-ignored). Its first line is `# Ledger — plan: <plan path>`. If a ledger already exists for this plan, tasks with a `Task <N>: complete` line are DONE; resume at the first task without one. Trust the ledger and `git log` over your own recollection.
  The ledger is the spec's ledger from the [Work list](#work-list-before-setup), with its first line kept, and each task is named by its Sub-task's Work Ref in place of `N`.
  `Local:` Keep `.power-architect/<plan-slug>/progress.md` (git-ignored) in the current checkout. Its first line is `# Ledger — plan: <plan path>`. If a ledger already exists for this plan, tasks with a `Task <N>: complete` line are DONE; resume at the first task without one.
- **Read the plan and its spec once.** The spec is the binding authority, and the plan is its argument. Create one todo per task.
  Read them through `pull(<Spec Page Work Ref>, outline)`, as the [Work list](#work-list-before-setup) says, and take the tasks from the work list, in its order.
  `Local:` Read the plan and its spec once, from the plan and the spec file. The spec is the binding authority, and the plan is its argument. Create one todo per task.
- **Pre-flight scan** before Task 1: for every pair of tasks that share a file or interface, write one ledger row with the two tasks, what one produces against what the other consumes, and what you found. Rule on each conflict and record the ruling beside its row. A plan whose tasks share nothing gets `Pre-flight: no shared interfaces`.
- **Continuous execution.** Don't pause to check in between tasks.
- **Rulings, not stalls.** Decide conflicts, ambiguities, and plan defects yourself, with the spec as the authority. Record each as `Ruling: <what you decided> — <why> — <what it costs if wrong>` and keep going.
- **Only four things stop you:** an irreversible or destructive operation; a security-sensitive action; a side effect outside this worktree that norms say to ask about first (a merge, a push to a shared branch, a publish); a plan so broken that every path forward is a guess.
- **TDD here is red → green → refactor** (see testing.md).

### S1. Subagent-driven (most thorough)

Per task:

1. **Record BASE** (`git rev-parse HEAD`). Never use `HEAD~1` for review ranges, because it drops all but the last commit of a multi-commit task.
2. **Write the task brief** (the task's full text from the plan) to `<workspace>/task-<Work Ref>-brief.md`. Dispatch a fresh implementer with [prompts/implementer.md](prompts/implementer.md). The dispatch contains: one line on where the task fits, the brief path ("read this first: these are your requirements"), interfaces from earlier tasks, your resolution of any ambiguity, and the report path `<workspace>/task-<Work Ref>-report.md`. Never paste prior-task history. **Never run implementers in parallel.**

   The task's full text is its Sub-task's description, then its Story's Acceptance Criteria. Call `record(<Work Ref>, started)` (see the [Tracker contract](tracker.md#recordref-event-evidence)) just before the dispatch.
   `Local:` The brief and report files are `<workspace>/task-N-brief.md` and `<workspace>/task-N-report.md`. The brief is the plan's task text. No record.
3. **Handle the report.**
   - **DONE**: go to review.
   - **DONE_WITH_CONCERNS**: address correctness or scope concerns before review; just note observations.
   - **NEEDS_CONTEXT**: provide the missing context and re-dispatch.
   - **BLOCKED**: add context, use a more capable model, split the task, or rule on a plan correction. Never retry unchanged.
4. **Review.** Write the diff (`git log --oneline`, `git diff --stat`, `git diff -U10` for BASE..HEAD) to one file. Dispatch a fresh reviewer with [prompts/task-reviewer.md](prompts/task-reviewer.md), giving it the brief, the report, the diff file, and the plan's Global Constraints verbatim. Both verdicts, spec compliance and quality, are required. Never pre-judge findings for the reviewer ("don't flag X").
5. **Fix loop** when the review shows spec ❌, any Critical or Important finding, or a confirmed ⚠️ gap. Record Minor findings in the ledger as `Task N: minor (deferred): …`; they never enter the loop. Allow at most 5 rounds:
   - Rounds 1–3: resume the same implementer with the findings verbatim.
   - Rounds 4–5: dispatch a fresh implementer on a more capable model.

   Each round ends with a **scoped re-review** of the fix diff only. Never fix findings yourself in the controller session. After round 5, rule on each open finding: park it with a ruling, or for a load-bearing defect, rule on the smallest unblocking change and carry it forward.
6. **Complete:** add the ledger line `Task N: complete (commits a..b, review clean | K parked)` and mark the todo done.

   The line is `Task <Work Ref>: complete (commits a..b, review clean | K parked, tests: <cmd> → <result>)`, with the implementer's final test run. Then call `record(<Work Ref>, done, <evidence>)`.
   `Local:` Add the ledger line `Task N: complete (commits a..b, review clean | K parked)` and mark the todo done. No record.

**Model selection:** use the least capable model that can do the job. Mechanical 1–2 file tasks with a complete spec get a cheap model. Multi-file integration gets a standard model. Design judgment and the final review get the most capable model. Always name the model explicitly.

### S2. Inline (cheapest)

Per task: read the brief (not the whole plan) → work the steps in order, running every command and comparing it with its `Expected:` line. If the code is wrong, use `/power-architect:debug`, never a symptom patch. If the plan is wrong, rule and ledger it. Then commit as the plan says.

A task is complete only when every named test exists and ran, the final run passed, every `Expected:` line was checked, and every deviation has a `Ruling:` line. Then add the ledger line `Task N: complete (commits a..b, tests: <cmd> → <result>)`.

Before a task's first step, call `record(<Work Ref>, started)`; its brief is its Sub-task's description, then its Story's Acceptance Criteria. The ledger line names the task by Work Ref and carries the token `S2`: `Task <Work Ref>: complete (commits a..b, S2, tests: <cmd> → <result>)`. Do not call `record(done)` yet: it is deferred until the spec's final review has passed (see [Deferred Done](#deferred-done)).
`Local:` Add the ledger line `Task N: complete (commits a..b, tests: <cmd> → <result>)`. No record.

### Final review (both S1 and S2)

0. If every item of this spec in the work list this run was a resume item (nothing of this spec was built this run), skip this spec's final review and say so. A spec with any new work this run gets its final review, and so does a spec with a resumed deferred item that has no `Final review: passed` line after its `Task` line (see [Resume](#work-list-before-setup)); the diff is the union of the spec's ledger `Task` and `Fix` ranges, as below.
   `Local:` No skip. The final review always runs.
1. Write the whole-branch diff (`git merge-base main HEAD`..HEAD) to a file.
   With a Tracker, write instead the diff of this spec's commits: the UNION of the ranges of this spec's ledger `Task` lines AND `Fix` lines, each range taken inclusively as `a^..b` (never one first-to-last span, so a Bug commit lying between two Sub-task commits is excluded), not the whole-branch merge-base diff. On a re-run after Done was withheld, the union includes the earlier `Fix` ranges and any commit made since the last range, up to HEAD; first write those later commits as a `Fix (spec <Spec Page Work Ref>): commits a..b` line, so the Done evidence lists them. Tell the reviewer which commits belong to the spec.
   `Local:` Write the whole-branch diff (`git merge-base main HEAD`..HEAD) to a file.
2. Dispatch **one fresh reviewer on the most capable model** with [prompts/code-reviewer.md](prompts/code-reviewer.md). Give it the plan's Review Focus verbatim, the spec path, and the ledger's `Ruling:` and deferred-minor lines. Without a subagent tool, do this review yourself as a separate pass, record `Final review: self-review` in the ledger, and tell the user it's weaker.

   The Review Focus is the Plan section's, verbatim, and the spec is `<workspace>/spec.md`.
   `Local:` Give it the plan's Review Focus verbatim, the spec path (`docs/specs/`), and the ledger's `Ruling:` and deferred-minor lines. Without a subagent tool, do this review yourself as a separate pass, record `Final review: self-review` in the ledger, and tell the user it's weaker.
3. **Re-grade** findings by their effect on a real user. Critical and Important findings go into **one** fix pass: in S1 a single fix subagent with the full list plus one scoped re-review; in S2 you fix each one via a test that fails first, then a green suite. Minor findings go to the ledger. There is no second fix wave.
   With a Tracker, if the fix pass made commits, add the ledger line `Fix (spec <Spec Page Work Ref>): commits a..b` (one per fix pass). Then settle Done as [Deferred Done](#deferred-done) says: with no Critical or Important finding open after the fix pass, add the ledger line `Final review: passed (spec <Spec Page Work Ref>)` and record the deferred items done; otherwise withhold Done for the deferred items (S1 items are already Done) and tell the user which findings are open.
   `Local:` No marker and no record.
4. **Report.** Your final message lists every `Ruling:` line under "Rulings I made" (each with what it costs if wrong) and every deferred minor under "Deferred minors". Then delete the workspace directory.

With a Tracker, recommend `/power-architect:verify`, then `/power-architect:finish`, only when Done was recorded (or queued) for every deferred item of this run; otherwise say what is open and recommend neither. `/power-architect:review` adds Matt's two-axis review if the user wants it.
`Local:` Recommend `/power-architect:verify`, then `/power-architect:finish`. `/power-architect:review` adds Matt's two-axis review if the user wants it.

---

## Large tier

**TDD here is red → green only.** Refactoring happens in `/power-architect:review`. Tests go only at the seams confirmed in the spec.

### L1. One ticket (Matt `implement`)

1. Read the ticket (`docs/plans/<slug>/NN-*.md` or the tracker) and state its title before starting. If the reference is ambiguous, ask.
   The ticket is the one Sub-task in the work list, read with its spec through `pull` (see the [Work list](#work-list-before-setup)). Call `record(<Work Ref>, started)` before any work on it.
   `Local:` Read the ticket (`docs/plans/<slug>/NN-*.md`) and state its title before starting. If the reference is ambiguous, ask. No record.
2. Build it with TDD at the pre-agreed seams.
3. Run typechecking regularly, single test files regularly, and the full suite once at the end.
4. Run the `/power-architect:review` method on the work, then commit to the current branch.
5. Mark the ticket done, show the passing output and a diff summary, and recommend the next frontier ticket.
   To mark it done, add the ledger line `Task <Work Ref>: complete (commits a..b, tests: <cmd> → <result>)`, then call `record(<Work Ref>, done, <evidence>)`. The next frontier ticket is a Sub-task of the outline whose blockers are all done, or have their `done` queued.
   `Local:` Mark the ticket done, show the passing output and a diff summary, and recommend the next frontier ticket. No ledger line and no record.

### L2. The whole graph (Matt `implement-spec`)

The goal is the whole spec implemented on one **integration branch**. The tickets form a **task graph**, not a list. There is always a **frontier** of ready tickets.

1. Read the spec and tickets to understand the graph.
   The tickets are the Sub-tasks in the work list, and the graph is their `blocks` edges: the first frontier is every item whose blockers are all done. Read the spec through `pull` (see the [Work list](#work-list-before-setup)).
   `Local:` Read the spec and tickets (`docs/specs/` and `docs/plans/<slug>/`) to understand the graph.
2. Optionally run an **exploration subagent** that saves notes outside the repo, for later implementers to read.
3. Create the integration branch. Open a draft PR after the first merge if the tracker closes work through PRs or the user asks for one.
4. Give each frontier ticket a **fresh implementer subagent** in its own worktree and branch, run in the background for concurrency. Each one confirms its worktree is based on the integration branch (resetting onto it if not), builds the ticket with TDD, and merges the integration branch tip into its own branch before reporting done.
   Call `record(<Work Ref>, started)` for each ticket just before its implementer is dispatched.
   `Local:` No record.
5. When an implementer finishes, a **merger subagent** merges its work into the integration branch. If the frontier changed, start implementers for the newly ready tickets.
   Once the merger has merged a ticket, add its ledger line `Task <Work Ref>: complete (commits a..b, L2, tests: <cmd> → <result>)`. Do not call `record(done)` yet: it is deferred until the spec's final review has passed (see [Deferred Done](#deferred-done)). A ticket joins the frontier only when every blocker is already Done in the Tracker, or is merged into the integration branch and has a `Task <Work Ref>: complete` ledger line, whatever its Tracker status. `pull` lists such an In Progress blocker earlier than its dependent, so the dependent is ready.
   `Local:` When an implementer finishes, a **merger subagent** merges its work into the integration branch. If the frontier changed, start implementers for the newly ready tickets. No ledger line and no record.
6. When every ticket is done, run the `/power-architect:review` method on the integration branch, and fix everything it raises in **one** fresh implementer subagent.
   With a Tracker, "every ticket is done" means every ticket is merged and has its ledger line. This review is the spec's final review. Read the spec first with `pull(<Spec Page Work Ref>, outline)`, as [review.md](review.md) does, and review the diff of the UNION of the spec's ledger `Task` and `Fix` ranges, each `a^..b`, never one first-to-last span. If that `pull` stops (the Tracker is unreachable), stop the build BEFORE the final review: the items stay In Progress and ledger-complete, write no marker and call no `record(done)`, and tell the user to re-run `/power-architect:build` once the Tracker is reachable. After the one fix, write the ledger line `Fix (spec <Spec Page Work Ref>): commits a..b`, run a scoped re-review of the fix diff, then settle Done as [Deferred Done](#deferred-done) says (marker `Final review: passed (spec <Spec Page Work Ref>)`). A re-run that finds ledger-complete L2 items without the marker starts here.
   `Local:` No marker and no record.
7. Mark the draft PR ready (or resolve the tickets), then clean up all worktrees.
   Deferred Done has recorded the Sub-tasks done (or withheld it, or queued it): make no further Tracker call. Mark the draft PR ready, and recommend verify and finish, only when Done was recorded (or queued); otherwise leave it a draft and say what is open. Stories are closed by `/power-architect:verify`, never here.
   `Local:` Mark the draft PR ready (or resolve the tickets), then clean up all worktrees.

Keep communication with subagents sparse: pass **context pointers** (spec, ticket, notes, commits) rather than copying their content.

Recommend `/power-architect:verify`, then `/power-architect:finish`.
