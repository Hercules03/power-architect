# /power-architect:verify

Adapted from Superpowers `verification-before-completion`. This applies in every phase, not only when the command is run.

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you can't claim it passes.

## The gate

Before claiming any status or expressing satisfaction:

1. **Identify** the command that proves the claim.
2. **Run** the full command, fresh and complete.
3. **Read** the full output: check the exit code and count the failures.
4. **Verify** whether the output confirms the claim. If not, state the actual status with the evidence. If so, state the claim *with* the evidence.
5. **Only then** make the claim.

| Claim | Requires | Not sufficient |
|---|---|---|
| Tests pass | test output showing 0 failures | an earlier run, "should pass" |
| Linter clean | linter output showing 0 errors | a partial check |
| Build succeeds | build command exiting 0 | the linter passing |
| Bug fixed | the original symptom now passes | code changed, assumed fixed |
| Regression test works | a red-green cycle verified (revert the fix → it MUST fail → restore → it passes) | a single passing run |
| Agent completed | the VCS diff shows the changes | the agent saying "success" |
| Requirements met | a line-by-line checklist against the spec | tests passing |

**Red flags:** "should", "probably", "seems to"; "Great!" or "Done!" before verifying; about to commit, push, or open a PR without verifying; trusting an agent's success report; a partial check.

## When the command is run

Re-read the spec (and plan or tickets), build a checklist of every requirement, verify each item with evidence, and report the gaps or confirm completion. Run the full test suite, plus typecheck, lint, and build where the project has them. Then recommend `/power-architect:finish`.

## Stories (with a Tracker)

With a Tracker, verify also closes the spec's Stories (see the [Tracker contract](tracker.md#pullscope-level)). The spec is the one in the ledger's first line (`# Ledger — spec: <Spec Page Work Ref>`), or the Work Ref the user gives.

1. **Pull first**, before any command is run: `pull(<Spec Page Work Ref>, story)` returns the spec's Stories that are not Done, in outline order, each with its Acceptance Criteria, its status, and whether all its Sub-tasks are Done (and which are not). Then `pull(<Spec Page Work Ref>, outline)`: the spec for the checklist above is read from it, not from a file.
   If a `pull` stops, stop the phase: run nothing, write nothing, and tell the user nothing was verified or written, and to re-run `/power-architect:verify` once the Tracker is reachable.
2. **Run the usual checks** (full suite, typecheck, lint, build, and the checklist above).
3. **Each Story from `pull`, one at a time.** Bugs are never part of it.
   - **Unfinished Sub-tasks.** The Story is not verifiable: report `N Sub-tasks unfinished (<Work Refs>)` (or `no Sub-tasks planned`), mark none of its criteria, and write nothing for it.
   - **Otherwise** the gate above applies to each Acceptance Criterion: identify the command or observable that proves it, run it fresh, read the output, and only then mark it passed.
   - **Every criterion passed:** call `record(<Story Work Ref>, done, <evidence>)`. `evidence` is one line per criterion: `<criterion text> — <command> → <result>`.
   - **Any criterion failed or can't be proven:** make no Tracker call for the Story. Report the gap: the criterion, its command and its output. Never call the Story done or complete.
4. **If `record` returns `queued`**, carry on. Tell the user which Stories' `done` is queued, not yet in the Tracker.

`Local:` No Stories, no `pull` and no `record`. Do only what the section above the line says.
