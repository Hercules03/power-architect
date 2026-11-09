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

---

## Discipline tables (verbatim from Superpowers `verification-before-completion`)

### Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

### Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

### When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness
