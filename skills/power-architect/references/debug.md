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

---

## Discipline tables (verbatim from Superpowers `systematic-debugging`)

### Red Flags - STOP and Follow Process

If you catch yourself thinking:
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- "Pattern says X but I'll adapt it differently"
- "Here are the main problems: [lists fixes without investigation]"
- Proposing solutions before tracing data flow
- **"One more fix attempt" (when already tried 2+)**
- **Each fix reveals new problem in different place**

**ALL of these mean: STOP. Return to Phase 1.**

**If 3+ fixes failed:** Question the architecture (see Phase 4.5)

### your human partner's Signals You're Doing It Wrong

**Watch for these redirections:**
- "Is that not happening?" - You assumed without verifying
- "Will it show us...?" - You should have added evidence gathering
- "Stop guessing" - You're proposing fixes without understanding
- "Ultra-think this" - Question fundamentals, not just symptoms
- "We're stuck?" (frustrated) - Your approach isn't working

**When you see these:** STOP. Return to Phase 1.

### Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need process" | Simple issues have root causes too. Process is fast for simple bugs. |
| "Emergency, no time for process" | Systematic debugging is FASTER than guess-and-check thrashing. |
| "Just try this first, then investigate" | First fix sets the pattern. Do it right from the start. |
| "I'll write test after confirming fix works" | Untested fixes don't stick. Test first proves it. |
| "Multiple fixes at once saves time" | Can't isolate what worked. Causes new bugs. |
| "Reference too long, I'll adapt the pattern" | Partial understanding guarantees bugs. Read it completely. |
| "I see the problem, let me fix it" | Seeing symptoms ≠ understanding root cause. |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question pattern, don't fix again. |

### When Process Reveals "No Root Cause"

If systematic investigation reveals issue is truly environmental, timing-dependent, or external:

1. You've completed the process
2. Document what you investigated
3. Implement appropriate handling (retry, timeout, error message)
4. Add monitoring/logging for future investigation

**But:** 95% of "no root cause" cases are incomplete investigation.

