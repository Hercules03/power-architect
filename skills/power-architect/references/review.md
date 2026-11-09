# /power-architect:review

Matt Pocock's `code-review` (two axes, parallel fresh subagents) for running the review, and Superpowers `receiving-code-review` for acting on it.

## Running the review (Matt)

1. **Pin the fixed point.** Use the commit, branch, or tag the user names. If they didn't name one, use the branch's merge-base with main and say so. Confirm it resolves (`git rev-parse`) and the diff is non-empty *before* dispatching anything. Diff: `git diff <fixed-point>...HEAD`. Commits: `git log <fixed-point>..HEAD --oneline`.
2. **Find the spec**, in this order: issue references in commit messages → a path the user passed → the matching spec in `docs/specs/` (and its plan or tickets in `docs/plans/`) → ask the user. If there's no spec, skip the Spec axis and say so.
3. **Find the standards sources**: every file that documents how code should be written (always include `CODING_STANDARDS.md` and `CONTRIBUTING.md` if they exist, plus `GLOSSARY.md` for naming). The **smell baseline** below always applies too. A documented repo standard overrides the baseline. Every smell is a judgement call, never a hard violation. Skip anything tooling already enforces.

   Smell baseline (Fowler, *Refactoring* ch. 3), each as *what it is* → *fix*:
   - **Mysterious Name**: the name doesn't reveal what it does → rename it.
   - **Duplicated Code**: the same logic shape in several hunks → extract it.
   - **Feature Envy**: a method reaches into another object's data → move it.
   - **Data Clumps**: fields that always travel together → bundle them into a type.
   - **Primitive Obsession**: a primitive standing in for a domain concept → give it a type.
   - **Repeated Switches**: the same switch across the change → polymorphism or one shared map.
   - **Shotgun Surgery**: one change forces scattered edits → gather into one module.
   - **Divergent Change**: one module edited for unrelated reasons → split it.
   - **Speculative Generality**: hooks or params the spec doesn't need → delete them.
   - **Message Chains**: `a.b().c().d()` → hide the walk behind one method.
   - **Middle Man**: something that only delegates → cut it.
   - **Refused Bequest**: a subclass ignores what it inherits → use composition.
4. **Spawn both subagents in parallel**, each with a fresh context:
   - **Standards**: give it the diff command, commit list, standards files, and the full smell baseline. Brief: "Report, per file/hunk, (a) every violation of a documented standard, citing the file and rule; (b) any baseline smell, naming it and quoting the hunk. Separate hard violations from judgement calls. Skip anything tooling enforces. Under 400 words."
   - **Spec**: give it the diff command, commit list, and spec. Brief: "Report (a) requirements missing or partial; (b) behaviour not asked for (scope creep); (c) requirements that look implemented but wrong. Quote the spec line for each. Under 400 words."

   Without a subagent tool, do the two passes one after the other and keep them separate.
5. **Aggregate.** Present the two reports under `## Standards` and `## Spec`, verbatim or lightly cleaned. **Don't merge or re-rank across the axes.** End with one line giving the number of findings per axis and the worst issue *within* each.

## Acting on the review (Superpowers)

For each item: **read** it all → **restate** the requirement (or ask) → **verify** it against the codebase → **evaluate** whether it's sound for *this* codebase → respond with a technical acknowledgement or reasoned pushback → **implement one item at a time, testing each**.

- Clarify anything unclear *first*, then fix blocking issues (breakage, security) → simple fixes → complex fixes. Test each fix and check for regressions.
- **Push back** when a suggestion breaks behaviour, the reviewer lacks context, it violates YAGNI, it's wrong for this stack, legacy constraints apply, or it conflicts with the user's architectural decisions. Use technical reasoning and involve the user if the decision is architectural.
- No performative agreement ("You're absolutely right!", "Great point!"). State the fix, or just do it.

**Large tier:** this is where refactoring happens. Fix the Standards findings you accept under green tests, and re-run the full suite after each one.

Then recommend `/power-architect:verify`.
