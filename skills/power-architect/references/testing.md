# Testing discipline

Combines Superpowers `test-driven-development` with Matt Pocock's `tdd`, `tests.md` and `mocking.md`. The two agree on almost everything. The only difference is **when to refactor**, which is settled by tier (see the end).

## The Iron Law (Superpowers)

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Code written before its test gets deleted. Don't keep it as "reference", don't adapt it, don't look at it. Implement fresh from the tests. Exceptions (throwaway prototypes, generated code, config files) need the user's permission.

## The loop

1. **RED**: write one minimal test for one behaviour, with a clear name and real code (mocks only if unavoidable).
2. **Verify RED (mandatory)**: run it and watch it fail *for the expected reason* (the feature is missing, not a typo). A test that passes immediately is a finding about the test.
3. **GREEN**: write the minimal code that passes it. Don't anticipate future tests or add speculative features.
4. **Verify GREEN**: that test and all the others pass, with clean output.
5. **Refactor**: see the tier rule below.
6. Next behaviour → back to RED.

**One slice at a time (Matt):** one seam, one test, one minimal implementation per cycle. **Never slice horizontally** (all tests first, then all code). Bulk tests verify *imagined* behaviour. Each test is a tracer bullet that responds to what the last cycle taught you.

## Seams: where tests go (Matt)

Tests live at seams, the public interfaces where behaviour is observable, never against internals. **Test only at the seams agreed in the spec.** If the shape of the interface itself is in question, consult [design-interface.md](design-interface.md).

## Good and bad tests

Good tests check behaviour through public interfaces, read like a specification ("user can checkout with valid cart"), survive internal refactors, and describe WHAT, not HOW.

Anti-patterns:
- **Implementation-coupled**: mocks internal collaborators, tests private methods, asserts call counts or order, or verifies through a side channel (querying the DB instead of using the interface). The tell: it breaks on a refactor when behaviour hasn't changed.
- **Tautological**: the expected value is recomputed the way the code computes it (`expect(add(a,b)).toBe(a+b)`), so the test can never disagree with the code. Expected values must come from an independent source: a known literal, a worked example, the spec.
- **Mock-behaviour tests**: they assert on the mock instead of the code.

Before writing any test, name the production change that would make it fail.

## Mocking (Matt)

Mock only at **system boundaries**: external APIs, sometimes databases (prefer a test DB), time and randomness, sometimes the filesystem. Never mock your own modules or internal collaborators. At those boundaries, inject dependencies, and prefer SDK-style interfaces (one function per operation) over a generic fetcher.

## Red flags: stop and start over

Code before the test · a test that passes immediately · you can't explain why it failed · "I'll add tests later" · "I already tested it manually" · "keep it as reference" · "this case is different".

## When stuck

If you don't know how to test something, write the API you wish you had and the assertion first. If the test is complicated, the design is too: simplify the interface. If you'd have to mock everything, the code is too coupled: use dependency injection.

## Refactoring by tier

- **Small tier (Superpowers):** after GREEN, refactor (remove duplication, improve names, extract helpers) while staying green and adding no behaviour.
- **Large tier (Matt):** refactoring is **not** part of the loop. It happens in `/power-architect:review`, where the Standards axis flags smells and the fixes are made with the tests as the safety net.

## Checklist before calling a task done

Every new function has a test · you watched each test fail for the expected reason · each test got minimal code · all tests pass · output is clean · tests use real code · edge cases and errors are covered.

---

## Discipline tables (verbatim from Superpowers `test-driven-development`)

### Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests written after pass immediately — which proves nothing. They may test the wrong thing, test the implementation instead of the behavior, or miss the edge case you forgot. You never watched it fail, so you never proved it can catch the bug. Test-first forces that failure. |
| "Tests after achieve same goals (spirit not ritual)" | Tests-after answer "what does this do?"; tests-first answer "what should this do?" Tests written after are biased by the code you already wrote — you verify the cases you remembered, not the ones you'd have discovered. Coverage without proof the tests work. |
| "Already manually tested" | Manual testing is ad-hoc: no record of what you covered, no way to re-run it when the code changes, easy to forget cases under pressure. "Worked when I tried it" ≠ comprehensive. Automated tests run the same way every time. |
| "Deleting X hours is wasteful" | Sunk cost fallacy — that time is already spent either way. The real choice: rewrite with TDD (high confidence) vs. keep it and bolt tests on after (low confidence, likely bugs). Keeping code you can't trust is the waste. |
| "Keep as reference, write tests first" | You'll adapt it. That's testing after. Delete means delete. |
| "Need to explore first" | Fine. Throw away exploration, start with TDD. |
| "Test hard = design unclear" | Listen to test. Hard to test = hard to use. |
| "TDD will slow me down" | TDD IS the pragmatic path: catches bugs before commit, prevents regressions, lets you refactor without fear. "Pragmatic" shortcuts mean debugging in production — slower, not faster. |
| "Manual test faster" | Manual doesn't prove edge cases. You'll re-test every change. |
| "Existing code has no tests" | You're improving it. Add tests for existing code. |

### Red Flags - STOP and Start Over

- Code before test
- Test after implementation
- Test passes immediately
- Can't explain why test failed
- Tests added "later"
- Rationalizing "just this once"
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "It's about spirit not ritual"
- "Keep as reference" or "adapt existing code"
- "Already spent X hours, deleting is wasteful"
- "TDD is dogmatic, I'm being pragmatic"
- "This is different because..."

**All of these mean: Delete code. Start over with TDD.**

