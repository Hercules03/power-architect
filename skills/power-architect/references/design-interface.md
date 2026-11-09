# /power-architect:design-interface

Adapted from Matt Pocock's `codebase-design` and its `DESIGN-IT-TWICE.md` and `DEEPENING.md`.

## Vocabulary (use these terms exactly)

- **Module**: anything with an interface and an implementation, at any scale: a function, class, package, or a slice spanning tiers. *Avoid*: unit, component, service.
- **Interface**: everything a caller must know to use the module correctly. That includes the type signature, but also invariants, ordering constraints, error modes, required configuration, and performance characteristics. *Avoid*: API, signature.
- **Implementation**: the code inside a module.
- **Depth**: leverage at the interface, meaning how much behaviour a caller or test can exercise per unit of interface it has to learn. A **deep** module hides a lot of behaviour behind a small interface. A **shallow** module's interface is nearly as complex as its implementation.
- **Seam** (Michael Feathers): a place where you can change behaviour without editing in that place. It is the *location* of a module's interface. *Avoid*: boundary.
- **Adapter**: a concrete thing that satisfies an interface at a seam.
- **Leverage**: what callers get from depth. **Locality**: what maintainers get from depth (change, bugs, and verification concentrate in one place).

Principles:
- Depth is a property of the interface, not the implementation.
- **Deletion test:** imagine deleting the module. If complexity vanishes, it was a pass-through. If it reappears across N callers, it was earning its keep.
- The interface is the test surface.
- One adapter means a hypothetical seam; two adapters means a real one.

## Dependency categories (DEEPENING)

Classify each dependency, because the category decides how the module is tested across its seam:

1. **In-process** (pure computation, in-memory state): merge the modules and test through the interface directly.
2. **Local-substitutable** (a local stand-in exists, e.g. PGLite for Postgres, an in-memory filesystem): test with the stand-in. The seam stays internal.
3. **Remote but owned** (your own services across a network): define a port at the seam, use an in-memory adapter in tests and an HTTP/gRPC/queue adapter in production.
4. **True external** (third parties such as Stripe or Twilio): inject the dependency as a port and use a mock adapter in tests.

Testing strategy: **replace, don't layer.** Once tests exist at the deepened interface, delete the old unit tests on the shallow modules.

## Process: Design It Twice (Ousterhout)

1. **Frame the problem space** for the user: the constraints any interface must satisfy, the dependencies and their categories, and a rough illustrative code sketch to make the constraints concrete (not a proposal). Show it, then go straight to step 2. The user reads while the subagents work.
2. **Spawn 3 or more subagents in parallel**, each with a fresh context and a separate technical brief (file paths, coupling, dependency categories, what sits behind the seam). Include the vocabulary above and the `GLOSSARY.md` terms in each brief. Give each subagent a different constraint:
   - Agent 1: "Minimize the interface: aim for 1–3 entry points. Maximise leverage per entry point."
   - Agent 2: "Maximise flexibility: support many use cases and extension."
   - Agent 3: "Optimise for the most common caller: make the default case trivial."
   - Agent 4 (if applicable): "Design around ports & adapters for cross-seam dependencies."

   Each returns: the interface (types, methods, params, invariants, ordering, error modes), a usage example, what the implementation hides, its dependency strategy and adapters, and trade-offs.

   Without a subagent tool, write the designs yourself, one at a time, each against its own constraint.
3. **Present and compare.** Show the designs one after another, then compare them in prose on **depth**, **locality**, and **seam placement**. Give your own recommendation and why. Propose a hybrid if parts combine well. Be opinionated: the user wants a strong read, not a menu.

Record the chosen design as an ADR only if it meets the three ADR criteria. Then recommend `/power-architect:to-spec`.
