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
