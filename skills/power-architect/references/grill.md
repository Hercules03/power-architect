# /power-architect:grill

Adapted from Matt Pocock's `grill-with-docs`, which runs `grilling` and `domain-modeling` together. Formats: [glossary-and-adr.md](glossary-and-adr.md).

## Grilling: the interview

Interview the user relentlessly until you reach a shared understanding. Map the work as a **design tree**: every decision branches into the decisions that depend on it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask *now* without guessing at answers you haven't heard yet. Ask the whole frontier in one round. Number each question and give your recommended answer. Then wait for the user's answers before the next round.

```
❓ **Q1** - **<question title>**: <question body, possibly several paragraphs, with choices if any>

➡️ <your recommended answer>

---

❓ **Q2** - **<question title>**: <question body>

➡️ <your recommended answer>
```

Word each question so that "yes" accepts your recommended answer.

Each round of answers reshapes the tree: settled decisions push the frontier outward and unblock the questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a *later* round.

Finding *facts* is your job, never the user's. When a frontier question needs a fact from the environment (files, tools, etc.), dispatch a subagent with a fresh context to find it. Never ask the user for something you could look up. Don't block on it: only the questions downstream of a running lookup wait for it, so ask the rest of the frontier now. The *decisions* are the user's: put each one to them and wait.

The session is done when the frontier is empty, meaning every branch of the tree has been visited and nothing is silently assumed. Do not act on the result until the user confirms you've reached a shared understanding.

## Domain modeling: during the session

- **Challenge terms against the glossary.** When the user uses a term that conflicts with `GLOSSARY.md`, say so immediately: "Your glossary defines 'cancellation' as X, but you seem to mean Y. Which is it?"
- **Sharpen fuzzy language.** When a term is vague or overloaded, propose a precise canonical term: "You're saying 'account': do you mean the Customer or the User? Those are different things."
- **Discuss concrete scenarios.** Stress-test domain relationships with specific scenarios you invent to probe edge cases and the boundaries between concepts.
- **Cross-reference with code.** When the user states how something works, check whether the code agrees, and surface any contradiction: "Your code cancels entire Orders, but you just said partial cancellation is possible. Which is right?"
- **Update `GLOSSARY.md` inline.** When a term is resolved, write it into the glossary right then. Don't batch updates. The glossary holds no implementation details: it is not a spec, a scratch pad, or a place for implementation decisions.
- **Offer ADRs sparingly.** Only offer one when a decision is hard to reverse, surprising without context, *and* the result of a real trade-off. If any of the three is missing, skip it.

## Handoff

- If *how to build it* is still open with two or more real options, lay out the approaches in a message of their own (Superpowers brainstorming): sketch the 2–3 strongest concretely, with what each trades off, recommend one, and let the user pick. If the open question is the shape of a module's interface, recommend `/power-architect:design-interface` instead.
- Otherwise recommend `/power-architect:to-spec`.
