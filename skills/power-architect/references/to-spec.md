# /power-architect:to-spec

Adapted from Matt Pocock's `to-spec`. The goals and approaches sections and the builder check come from Superpowers `brainstorming`.

Do **not** interview the user here. Write up what is already settled. If something important was never settled, say so and recommend going back to `/power-architect:grill`.

A step with a `Local:` line below it reads two ways. With a Tracker configured, do what the step says. Without one (no `## Tracker` section), do only what its `Local:` line says.

## Process

1. **Explore the repo** if you haven't already. Use the `GLOSSARY.md` vocabulary throughout, and respect ADRs in the area you're touching.
2. **Sketch the test seams.** Prefer existing seams to new ones, and use the highest seam possible. If new seams are needed, propose them as high as you can. The fewer seams the better; the ideal number is one. **Confirm the seams with the user.** These are the pre-agreed seams `/power-architect:build` will test at.
3. **Assign the Scope Tier** (Small or Large, defined in SKILL.md) with a one-line reason. The user can override it.
4. **Write the spec** as a draft to `.power-architect/<spec-slug>/spec-draft.md` (git-ignored scratch; `<spec-slug>` is `YYYY-MM-DD-slug`) using the template below. Nothing reaches the Tracker before the gate in step 6.
   `Local:` Write the spec to `docs/specs/YYYY-MM-DD-slug.md` using the template below.
5. **Builder check (Large tier).** Dispatch a fresh subagent with [prompts/builder-check.md](prompts/builder-check.md), pointing it at the file written in step 4. Sort what it asks into three piles:
   - **Already answered** by the conversation or the project: put the answer into the spec.
   - **Minor**: a sensible builder could settle it without changing what gets built. Settle it yourself and mark it in the spec as your call.
   - **Theirs**: only the user can answer it, and the answer changes what gets built. Ask these in one message, most important first.

   This produces one round of questions at most. Without a subagent tool, read the spec as that builder yourself.
6. **Get the user's approval of the spec.** This is the hard gate before any building.
   - **Epics.** Show the Epics beside the spec; the user approves both together.
     - Large tier: a table `Epic | user stories (by number) | why they belong together`. Group by functional area, user persona or system boundary. Every user story sits in exactly one Epic.
     - Small tier: no table. Ask once which Epic the one Story goes under: an existing Epic's Work Ref, or "new" with a name.
     - If the user edits the spec or the Epics, update the draft, show both again and wait for approval.

     `Local:` No Epics; the user approves the spec alone.
7. **Publish.** Build the [Work Outline](#work-outline) from the approved draft and call `publish(outline)` (see the [Tracker contract](tracker.md#publishoutline)). Then write the ledger `.power-architect/<spec-slug>/progress.md`: first line `# Ledger — spec: <the Spec Page's Work Ref>`, then a `## Work Refs` table `outline id | kind | Work Ref | title`, one row per item `publish` returned.
   - If `publish` stops partway, write the ledger the same way with the items it did create, and tell the user the spec is only partly published.
   - If it published nothing, write no ledger, and tell the user the draft is still at `.power-architect/<spec-slug>/spec-draft.md`.

   `Local:` Nothing to publish; the spec file from step 4 is the record.

## Work Outline

Built in step 7 from the approved draft. `Local:` not built.

- **Scope Tier**: Small or Large.
- **Spec Page** (outline id `spec`): the spec's title and its shared context: Problem Statement, Solution, Goals / Non-goals / Anti-goals, Approaches considered, the Implementation and Testing Decisions that span Epics (including the cross-Epic test seams), Out of Scope, Scope Tier and Further Notes.
- **Epics** (outline ids `E1`, `E2`, … in the approved order): the name; this Epic's own slice of the goals and Implementation Decisions; links to the ADRs relevant to it. Small tier: the one Epic the user named, as its Work Ref if it already exists (it is used as is), or as a new name.
- **Stories** (outline id: the user story's number in the spec): a short title, the user-story sentence, its parent Epic's outline id, and **Acceptance Criteria**: a checklist of testable checks drawn from the story and the Testing Decisions, each one provable by `/power-architect:verify` with a command or an observable result. Small tier: one Story (outline id `1`) that carries every user-story sentence of the spec and all their Acceptance Criteria.
- **ADR links**: each ADR's title and repo-relative path (`docs/adr/NNNN-slug.md`). If the `origin` remote has a web host, add its URL: `<origin web URL>/blob/<current branch>/<path>`. The web URL is `https://<host>/<owner>/<repo>`, with any trailing `.git` dropped (so `git@host:owner/repo.git` becomes `https://host/owner/repo`).

## Spec template

- **Problem Statement**: the problem from the user's perspective.
- **Solution**: the solution from the user's perspective.
- **Goals / Non-goals / Anti-goals**: anti-goals are what would make this a failure even if it technically works.
- **Approaches considered**: the 2–3 ways considered, what each trades off, which was picked, and why.
- **User Stories**: a LONG, numbered list in the form "As an <actor>, I want a <feature>, so that <benefit>". Cover every aspect of the feature.
- **Implementation Decisions**: modules built or modified, their interfaces, architectural decisions, schema changes, API contracts, and specific interactions. **No file paths or code snippets**, because they go stale. Exception: a prototype snippet that captures a decision more precisely than prose (state machine, reducer, schema, type shape), trimmed to the essentials and labelled as coming from a prototype.
- **Testing Decisions**: what makes a good test (external behaviour only), the confirmed seams, which modules are tested, and prior art in the codebase.
- **Out of Scope**
- **Scope Tier**: Small or Large, with the reason.
- **Further Notes**

## Handoff

Recommend `/power-architect:plan`. If nothing was published (the Tracker was unreachable), recommend re-running `/power-architect:to-spec` once the Tracker is reachable instead.
