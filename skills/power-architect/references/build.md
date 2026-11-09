# /power-architect:build

Read [testing.md](testing.md) before the first task. It governs every step below.

- **Small tier**: Superpowers `subagent-driven-development` (S1) or `executing-plans` (S2), whichever the user picked at plan handoff.
- **Large tier**: Matt Pocock's `implement` (L1, one ticket, `/power-architect:build 03`) or `implement-spec` (L2, the whole ticket graph, `/power-architect:build all`).

## Setup (both tiers): isolated workspace (Superpowers `using-git-worktrees`)

1. **Detect existing isolation.** If `git rev-parse --git-dir` differs from `--git-common-dir` and you're not in a submodule, you're already in a linked worktree, so don't create another.
2. **Otherwise create one.** Prefer the harness's native worktree tool. The fallback is `git worktree add` under `.worktrees/`, after confirming that directory is git-ignored (add it to `.gitignore` and commit if not). If the sandbox blocks worktree creation, say so and work in place on a feature branch. **Never start implementation on main/master without the user's explicit consent.**
3. **Project setup:** install dependencies the way the project does (`npm install`, `cargo build`, `uv sync`, `go mod download`, …).
4. **Verify a clean baseline:** run the full test suite. If it fails, report the failures and ask whether to proceed or investigate.

---

## Small tier

Shared by S1 and S2:

- **Ledger.** Conversation memory doesn't survive compaction, and agents that lose their place re-do completed tasks. Keep `.power-architect/<plan-slug>/progress.md` (git-ignored). Its first line is `# Ledger — plan: <plan path>`. If a ledger already exists for this plan, tasks with a `Task <N>: complete` line are DONE; resume at the first task without one. Trust the ledger and `git log` over your own recollection.
- **Read the plan and its spec once.** The spec is the binding authority, and the plan is its argument. Create one todo per task.
- **Pre-flight scan** before Task 1: for every pair of tasks that share a file or interface, write one ledger row with the two tasks, what one produces against what the other consumes, and what you found. Rule on each conflict and record the ruling beside its row. A plan whose tasks share nothing gets `Pre-flight: no shared interfaces`.
- **Continuous execution.** Don't pause to check in between tasks.
- **Rulings, not stalls.** Decide conflicts, ambiguities, and plan defects yourself, with the spec as the authority. Record each as `Ruling: <what you decided> — <why> — <what it costs if wrong>` and keep going.
- **Only four things stop you:** an irreversible or destructive operation; a security-sensitive action; a side effect outside this worktree that norms say to ask about first (a merge, a push to a shared branch, a publish); a plan so broken that every path forward is a guess.
- **TDD here is red → green → refactor** (see testing.md).

### S1. Subagent-driven (most thorough)

Per task:

1. **Record BASE** (`git rev-parse HEAD`). Never use `HEAD~1` for review ranges, because it drops all but the last commit of a multi-commit task.
2. **Write the task brief** (the task's full text from the plan) to `<workspace>/task-N-brief.md`. Dispatch a fresh implementer with [prompts/implementer.md](prompts/implementer.md). The dispatch contains: one line on where the task fits, the brief path ("read this first: these are your requirements"), interfaces from earlier tasks, your resolution of any ambiguity, and the report path `<workspace>/task-N-report.md`. Never paste prior-task history. **Never run implementers in parallel.**
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

**Model selection:** use the least capable model that can do the job. Mechanical 1–2 file tasks with a complete spec get a cheap model. Multi-file integration gets a standard model. Design judgment and the final review get the most capable model. Always name the model explicitly.

### S2. Inline (cheapest)

Per task: read the brief (not the whole plan) → work the steps in order, running every command and comparing it with its `Expected:` line. If the code is wrong, use `/power-architect:debug`, never a symptom patch. If the plan is wrong, rule and ledger it. Then commit as the plan says.

A task is complete only when every named test exists and ran, the final run passed, every `Expected:` line was checked, and every deviation has a `Ruling:` line. Then add the ledger line `Task N: complete (commits a..b, tests: <cmd> → <result>)`.

### Final review (both S1 and S2)

1. Write the whole-branch diff (`git merge-base main HEAD`..HEAD) to a file.
2. Dispatch **one fresh reviewer on the most capable model** with [prompts/code-reviewer.md](prompts/code-reviewer.md). Give it the plan's Review Focus verbatim, the spec path, and the ledger's `Ruling:` and deferred-minor lines. Without a subagent tool, do this review yourself as a separate pass, record `Final review: self-review` in the ledger, and tell the user it's weaker.
3. **Re-grade** findings by their effect on a real user. Critical and Important findings go into **one** fix pass: in S1 a single fix subagent with the full list plus one scoped re-review; in S2 you fix each one via a test that fails first, then a green suite. Minor findings go to the ledger. There is no second fix wave.
4. **Report.** Your final message lists every `Ruling:` line under "Rulings I made" (each with what it costs if wrong) and every deferred minor under "Deferred minors". Then delete the workspace directory.

Recommend `/power-architect:verify`, then `/power-architect:finish`. `/power-architect:review` adds Matt's two-axis review if the user wants it.

---

## Large tier

**TDD here is red → green only.** Refactoring happens in `/power-architect:review`. Tests go only at the seams confirmed in the spec.

### L1. One ticket (Matt `implement`)

1. Read the ticket (`docs/plans/<slug>/NN-*.md` or the tracker) and state its title before starting. If the reference is ambiguous, ask.
2. Build it with TDD at the pre-agreed seams.
3. Run typechecking regularly, single test files regularly, and the full suite once at the end.
4. Run the `/power-architect:review` method on the work, then commit to the current branch.
5. Mark the ticket done, show the passing output and a diff summary, and recommend the next frontier ticket.

### L2. The whole graph (Matt `implement-spec`)

The goal is the whole spec implemented on one **integration branch**. The tickets form a **task graph**, not a list. There is always a **frontier** of ready tickets.

1. Read the spec and tickets to understand the graph.
2. Optionally run an **exploration subagent** that saves notes outside the repo, for later implementers to read.
3. Create the integration branch. Open a draft PR after the first merge if the tracker closes work through PRs or the user asks for one.
4. Give each frontier ticket a **fresh implementer subagent** in its own worktree and branch, run in the background for concurrency. Each one confirms its worktree is based on the integration branch (resetting onto it if not), builds the ticket with TDD, and merges the integration branch tip into its own branch before reporting done.
5. When an implementer finishes, a **merger subagent** merges its work into the integration branch. If the frontier changed, start implementers for the newly ready tickets.
6. When every ticket is done, run the `/power-architect:review` method on the integration branch, and fix everything it raises in **one** fresh implementer subagent.
7. Mark the draft PR ready (or resolve the tickets), then clean up all worktrees.

Keep communication with subagents sparse: pass **context pointers** (spec, ticket, notes, commits) rather than copying their content.

Recommend `/power-architect:verify`, then `/power-architect:finish`.
