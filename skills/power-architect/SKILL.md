---
name: power-architect
description: Integrated architecture + TDD workflow that runs Matt Pocock's skills (grilling, domain modeling, deep-module design, specs, tracer-bullet tickets, two-axis review, retros) and Jesse Vincent's Superpowers (implementation plans, subagent-driven TDD execution, systematic debugging, verification, branch finishing) as one pipeline. Use when the user asks to design, architect, spec, plan, implement, debug, review, or finish software work, or invokes /power-architect:grill, :design-interface, :to-spec, :plan, :build, :debug, :review, :verify, :finish, or :retro.
---

# Power Architect

Power Architect does not invent a methodology. Each phase runs one upstream skill's method as written, adapted from:

- **Matt Pocock, [`mattpocock/skills`](https://github.com/mattpocock/skills)**: alignment, domain language, module design, specs, tickets, review, retro.
- **Jesse Vincent, [`obra/superpowers`](https://github.com/obra/superpowers)**: plans, execution, TDD discipline, debugging, verification, finishing.

What Power Architect adds is only the glue: which phase comes next, which method applies at which **Scope Tier**, where files live, and the next-step footer.

## How to run a phase

1. Read the phase's reference file (table below) and follow it exactly. Don't paraphrase it from memory.
2. **If the upstream skill is installed** (it appears in your available skills, e.g. `mattpocock-skills:grilling` or `superpowers:writing-plans`), invoke it for that phase instead, then apply the Power Architect conventions below on top. The reference files are the bundled fallback so that nothing else needs to be installed.
3. End every response with the Next-Step Footer.

| Command | Phase | Method | Reference |
|---|---|---|---|
| `/power-architect:grill` | Align | Matt `grilling` + `domain-modeling` | [references/grill.md](references/grill.md) |
| `/power-architect:design-interface` | Design | Matt `codebase-design` / Design It Twice | [references/design-interface.md](references/design-interface.md) |
| `/power-architect:to-spec` | Specify | Matt `to-spec` + Superpowers builder check | [references/to-spec.md](references/to-spec.md) |
| `/power-architect:plan` | Plan | Small: Superpowers `writing-plans` · Large: Matt `to-tickets` | [references/plan.md](references/plan.md) |
| `/power-architect:build` | Build | Small: Superpowers `subagent-driven-development` / `executing-plans` · Large: Matt `implement` / `implement-spec` | [references/build.md](references/build.md) |
| `/power-architect:debug` | Debug | Matt `diagnosing-bugs` + Superpowers `systematic-debugging` | [references/debug.md](references/debug.md) |
| `/power-architect:review` | Review | Matt `code-review` + Superpowers `receiving-code-review` | [references/review.md](references/review.md) |
| `/power-architect:verify` | Verify | Superpowers `verification-before-completion` | [references/verify.md](references/verify.md) |
| `/power-architect:finish` | Finish | Superpowers `finishing-a-development-branch` | [references/finish.md](references/finish.md) |
| `/power-architect:retro` | Improve | Matt `retro` | [references/retro.md](references/retro.md) |

Shared references: [references/testing.md](references/testing.md) (good tests, mocking, TDD rules) and [references/glossary-and-adr.md](references/glossary-and-adr.md) (file formats).

## Scope Tier

`/power-architect:to-spec` assigns a tier, and later phases route on it. The user can override it.

- **Small**: a well-defined change at one seam with no architectural ambiguity, typically 1 to 3 files. Runs the **Superpowers** execution path: an exact-file-path plan, then per-task TDD with fresh reviewers.
- **Large**: several seams, state or data migrations, cross-cutting concerns, or more than one session's worth of work. Runs the **Matt** execution path: tracer-bullet tickets with blocking edges, then TDD at pre-agreed seams.

If the work grows mid-phase, stop, say so, and step up a tier.

## Pipeline

```
grill ──► design-interface (optional) ──► to-spec ──► plan ──► build ──► review ──► verify ──► finish ──► retro (optional)
                                                                  ▲
                                                debug ────────────┘  (whenever something breaks)
```

**Hard gate (Superpowers brainstorming):** nothing gets built (no product code, scaffolding, dependency installs, or `/power-architect:build`) until the user has approved the spec. Reading and exploring are fine. A throwaway spike the user explicitly agreed to is the only exception, and keeping its output means going back through the gate.

## Where the two methods disagree, and how Power Architect resolves it

Each resolution keeps both methods intact by giving each one its own tier or phase:

1. **When to refactor.** Superpowers refactors inside the TDD loop; Matt moves refactoring to review. **Small tier:** red → green → refactor (Superpowers). **Large tier:** red → green only, and refactoring happens in `/power-architect:review` (Matt).
2. **File paths in written plans.** Superpowers requires exact paths; Matt bans them from specs and tickets because they go stale. **Specs and Large-tier tickets** carry no file paths. **Small-tier plans** carry exact paths.
3. **When to ask the user.** Matt confirms test seams with the user; Superpowers execution never stalls except for its four stop conditions. Seams are confirmed during `/power-architect:to-spec`, so `/power-architect:build` can run without stopping.
4. **Domain language file.** Matt's current convention applies: `GLOSSARY.md` at the repo root, with no implementation details in it.

## File conventions

Create files and directories lazily, only when there is something to write. Project-level instructions override these paths.

| Artifact | Path |
|---|---|
| Glossary (domain language) | `GLOSSARY.md` (multi-context repos: `GLOSSARY-MAP.md` → per-context `GLOSSARY.md`) |
| Decisions | `docs/adr/0001-slug.md` |
| Specs | `docs/specs/YYYY-MM-DD-slug.md` |
| Small-tier plan | `docs/plans/YYYY-MM-DD-slug.md` |
| Large-tier tickets | `docs/plans/YYYY-MM-DD-slug/NN-ticket-slug.md` (one file per ticket) |
| Execution ledger (git-ignored scratch) | `.power-architect/<plan-slug>/progress.md` |
| Retros (optional record) | `docs/retros/YYYY-MM-DD-slug.md` |

If the user has an issue tracker configured (for example via Matt's `/setup-matt-pocock-skills`), publish specs and tickets there as the upstream skills do, and skip the local files.

## Rules that apply in every phase

- **Facts are yours, decisions are theirs.** Look up anything the code, docs, or tools can answer. Put only real decisions to the user.
- **Use the glossary's terms** in questions, specs, tickets, test names, and code. Respect ADRs in the area you're touching.
- **No completion claims without fresh evidence**: see [references/verify.md](references/verify.md).
- **No production code without a failing test first**: see [references/testing.md](references/testing.md).

## Next-Step Footer (mandatory)

End every response with:

```text
---
[Power Architect | Phase: <phase> | Scope Tier: <Small | Large | TBD>]
Artifacts updated: <paths, or "None">
Next:
- Run `/power-architect:<command> [args]` to <what happens next>
- Alternative: `/power-architect:<command>` if you want to <alternative>
```
