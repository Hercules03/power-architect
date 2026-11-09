# /power-architect:to-spec

Adapted from Matt Pocock's `to-spec`. The goals and approaches sections and the builder check come from Superpowers `brainstorming`.

Do **not** interview the user here. Write up what is already settled. If something important was never settled, say so and recommend going back to `/power-architect:grill`.

## Process

1. **Explore the repo** if you haven't already. Use the `GLOSSARY.md` vocabulary throughout, and respect ADRs in the area you're touching.
2. **Sketch the test seams.** Prefer existing seams to new ones, and use the highest seam possible. If new seams are needed, propose them as high as you can. The fewer seams the better; the ideal number is one. **Confirm the seams with the user.** These are the pre-agreed seams `/power-architect:build` will test at.
3. **Assign the Scope Tier** (Small or Large, defined in SKILL.md) with a one-line reason. The user can override it.
4. **Write the spec** to `docs/specs/YYYY-MM-DD-slug.md` using the template below, or publish it to the issue tracker if one is configured.
5. **Builder check (Large tier).** Dispatch a fresh subagent with [prompts/builder-check.md](prompts/builder-check.md). Sort what it asks into three piles:
   - **Already answered** by the conversation or the project: put the answer into the spec.
   - **Minor**: a sensible builder could settle it without changing what gets built. Settle it yourself and mark it in the spec as your call.
   - **Theirs**: only the user can answer it, and the answer changes what gets built. Ask these in one message, most important first.

   This produces one round of questions at most. Without a subagent tool, read the spec as that builder yourself.
6. **Get the user's approval of the spec.** This is the hard gate before any building.

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

Recommend `/power-architect:plan`.
