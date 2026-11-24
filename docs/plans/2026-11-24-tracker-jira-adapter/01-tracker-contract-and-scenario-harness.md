# 01: Tracker contract and scenario harness

**What to build:** A maintainer can read one shared Tracker contract that every phase links to. It defines how the adapter is chosen: no `## Tracker` section means Local Files; `adapter: <name>` means follow that Tracker Adapter; an unknown adapter or a broken section stops the phase and recommends setup. It also defines Work Refs and `publish`, `pull` (levels `story`, `subtask`, `outline`) and `record` (events started, done, note, defect, shipped), with their invariants and error modes (`stop` vs `queued`). The skill's top-level rules point to the contract in place of the old "if the user has an issue tracker configured" sentence. A scenario harness exists: a Given / When / Then scenario format, a stubbed Rovo table format (fixed tool responses, plus simulated "unreachable"), instructions for a fresh subagent to dry-run a phase against it and write out its calls, and the locality grep check.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The Tracker contract states selection, Work Ref, all three operations with inputs, outputs, invariants and error modes, and the adapter rules (no Sprint changes, no estimates, the whole contract implemented)
- [x] The skill's top-level rules link to the contract, and the old issue-tracker sentence is gone
- [x] The scenario format and the stubbed Rovo table format are documented, with dry-run instructions for a subagent
- [x] Scenario: an unknown adapter name stops the phase and recommends `/power-architect:setup-tracker`, as shown by a dry run
- [x] Scenario: no `## Tracker` section leaves the phase reading nothing new, as shown by a dry run
- [x] The locality grep check is documented and passes
