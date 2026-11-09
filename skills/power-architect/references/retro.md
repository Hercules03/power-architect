# /power-architect:retro

Adapted from Matt Pocock's `retro`. A retrospective suggests improvements to the coding agent's **environment** so that future runs go better. It is not a lessons-learned essay.

## Steps

1. Write concisely, for agents: short, pointer-heavy, no filler.
2. Read the primary sources for the session the user names (session logs on this machine if needed). Default to the current session.
3. Look for improvement candidates in these categories:
   - **Navigation**: was it hard to find the right files? Are there hidden dependencies between files? Would a **navigation pointer** help? *Use when* finding information took a long time.
   - **Automated checks**: could lint, types, tests, or a filesystem linter have caught a mistake the agent made? Read the repo's own check commands and CI first: a check that exists but is unwired or silently broken is the finding. A repo with **no guardrail** (no pre-commit hook and no CI job running lint/typecheck/test) is itself a finding.
   - **Coding standards**: should the reviewer enforce a new rule, or should a rule be removed or clarified? A **mechanical** violation (a syntactic pattern, a banned API, an import shape, a file-location rule) gets a deterministic check in the repo's linter, a pre-commit hook, or CI. Reserve `CODING_STANDARDS.md` for genuine **judgement calls**. *Use when* review missed a mistake.
   - **Global steering files** (`CLAUDE.md` / `AGENTS.md`): should instructions move into coding standards or automated checks? *Use when* these files are large.
   - **Tool economy**: were there expensive or token-heavy tool calls that could be streamlined?
   - **No-ops**: are there steering instructions that don't change the agent's behaviour?
   - **Information access**: was a crucial piece of information unavailable (dev-server logs, read-only access to a third-party service)?
4. Present the candidates to the user, **most severe first**.

Optionally save the list to `docs/retros/YYYY-MM-DD-slug.md` as a record. Apply nothing until the user picks candidates.

## Reference

- **Implementation vs review:** the implementation agent carries the most context pressure (exploring, coding, debugging). The reviewer only receives a diff, so **the reviewer is the one that enforces coding standards**.
- `CLAUDE.md` / `AGENTS.md` are loaded into every agent's context, so use them very sparingly, mostly for navigation pointers. `CODING_STANDARDS.md` is read during review, not implementation. Docs are reference files that other files point to. Look for existing docs before writing new ones.
