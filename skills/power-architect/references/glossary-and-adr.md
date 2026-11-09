# GLOSSARY.md and ADR formats

Adapted from Matt Pocock's `domain-modeling` (`GLOSSARY-FORMAT.md`, `ADR-FORMAT.md`).

## GLOSSARY.md

```md
# {Context Name}

{One or two sentences on what this context is and why it exists.}

## Language

**Order**:
A customer's request to buy one or more products.
_Avoid_: Purchase, transaction

**Customer**:
A person or organization that places orders.
_Avoid_: Client, buyer, account
```

Rules:
- **Be opinionated.** When several words exist for one concept, pick the best and list the rest under `_Avoid_`.
- **Keep definitions tight**: one or two sentences saying what the term IS, not what it does.
- **Only project-specific terms.** General programming concepts (timeouts, error types, utility patterns) don't belong.
- **No implementation details**: no file paths, class names, or decisions.
- Group terms under subheadings when natural clusters emerge.

**Single context (most repos):** one `GLOSSARY.md` at the repo root. **Multiple contexts:** a `GLOSSARY-MAP.md` at the root lists each context's `GLOSSARY.md`, where it lives, and how the contexts relate (e.g. "Ordering → Fulfillment: Ordering emits `OrderPlaced`; Fulfillment consumes it"). If neither file exists, create a root `GLOSSARY.md` lazily when the first term is resolved.

## ADRs

ADRs live in `docs/adr/` with sequential numbering: `0001-slug.md`, `0002-slug.md`. To pick the next number, scan for the highest existing one and add one. Create the directory lazily.

```md
# {Short title of the decision}

{1–3 sentences: the context, what we decided, and why.}
```

An ADR can be a single paragraph. Optional sections, only when they add real value: **Status** (`proposed | accepted | deprecated | superseded by ADR-NNNN`), **Considered Options**, **Consequences**.

**Offer an ADR only when all three are true:** it's **hard to reverse**, it would be **surprising without context**, and it was **the result of a real trade-off**.

What qualifies: the architectural shape · integration patterns between contexts · technology choices that carry lock-in · boundary and scope decisions (including the explicit no's) · deliberate deviations from the obvious path · constraints not visible in the code · rejected alternatives whose rejection isn't obvious.
