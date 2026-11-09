# /power-architect:debug

Combines Matt Pocock's `diagnosing-bugs` (the phase structure and the feedback loop) with Superpowers `systematic-debugging` (pattern analysis, one variable at a time, the 3-failed-fixes rule). Skip a phase only with an explicit justification.

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST        (Superpowers)
NO HYPOTHESES WITHOUT A RED-CAPABLE FEEDBACK LOOP      (Matt)
```

Read `GLOSSARY.md` and the relevant ADRs for a mental model of the modules involved. **Redact secrets** in every command, output, and artifact you show (write `<REDACTED>`), and build loops against env vars.

## Phase 1: Build a feedback loop

**This is the skill.** If you have a tight pass/fail signal that goes red on *this* bug, you will find the cause. Be aggressive, be creative, and don't give up. First **read the error messages and stack traces completely** and **check recent changes** (git diff, new dependencies, config, environment).

Ways to build a loop, roughly in this order: a failing test at whatever seam reaches the bug · a curl/HTTP script · a CLI run with a fixture diffed against a known-good snapshot · a headless browser script · replaying a captured trace · a throwaway harness · a property/fuzz loop · a bisection harness (`git bisect run`) · a differential loop (old vs new) · a human-in-the-loop script, as a last resort.

In multi-component systems (CI → build → deploy, API → service → DB), instrument each component boundary once (what goes in, what comes out, config propagation) to find *where* it breaks.

**Tighten the loop:** make it faster, give it a sharper signal (assert the exact symptom), and make it deterministic (pin time, seed RNG, isolate the filesystem). For flaky bugs, the goal is a higher reproduction rate.

If you **cannot** build a loop, stop and say so. List what you tried and ask for environment access, a redacted artifact (HAR, logs, recording), or permission to add temporary instrumentation. Don't hypothesise without a loop.

**Done when** you can name one command you have already run, with its output shown, that is: **red-capable** (it asserts the user's exact symptom) · **deterministic** · **fast** (seconds) · **agent-runnable**.

## Phase 2: Reproduce and minimise

Run the loop and watch it go red. Confirm it's the failure the **user** described, not a nearby one, that it reproduces across runs, and that you've captured the exact symptom. Then **minimise**: cut inputs, callers, config, data, and steps one at a time, re-running after each cut, until every remaining element is needed for the failure.

## Phase 3: Pattern analysis (Superpowers)

Find similar code in the codebase that **works**. If you're implementing a pattern, read the reference implementation completely. List **every** difference between working and broken, however small, and the dependencies, settings, and assumptions involved.

## Phase 4: Hypothesise

Generate **3–5 ranked hypotheses** before testing any of them. Each must be falsifiable: "If X is the cause, then changing Y will make the bug disappear / changing Z will make it worse." A hypothesis without a prediction is a vibe: sharpen it or drop it. **Show the ranked list to the user** (they often re-rank instantly); don't block on it if they're away.

## Phase 5: Instrument and test, one hypothesis at a time

Test the top hypothesis with the **smallest possible change, one variable at a time**. Prefer a debugger or REPL, then targeted logs at the boundaries that tell hypotheses apart. Never "log everything and grep". **Tag every debug log** with a unique prefix (e.g. `[DEBUG-a4f2]`). For performance regressions, measure a baseline first, then bisect. If the hypothesis is refuted, move to the next one; don't stack fixes. If you don't understand something, say so.

## Phase 6: Fix with a regression test

Write the regression test **before the fix**, at a **correct seam**: one that exercises the real bug pattern as it happens at the call site. If no correct seam exists, **that is the finding**: record it, because the architecture is preventing the bug from being locked down.

1. Turn the minimised repro into a failing test and watch it fail.
2. Make **one** fix at the root cause, with no "while I'm here" changes.
3. Watch the test pass, run the whole suite, and re-run the Phase 1 loop on the original, un-minimised scenario.

**If the fix doesn't work:** count your attempts. Fewer than 3: go back to Phase 1 with what you learned. **Three or more: stop and question the architecture** (each fix reveals new coupling elsewhere, fixes need massive refactoring, each fix creates new symptoms). Discuss it with the user before trying fix #4.

## Phase 7: Clean up

- [ ] The original repro no longer reproduces (re-run the Phase 1 loop)
- [ ] The regression test passes, or the missing seam is documented
- [ ] All `[DEBUG-…]` instrumentation is removed (grep the prefix)
- [ ] Throwaway harnesses are deleted or clearly marked
- [ ] The hypothesis that proved correct is stated in the commit or PR message

Then follow [verify.md](verify.md) before claiming it's fixed.
