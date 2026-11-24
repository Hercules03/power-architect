# 04: Re-runs update in place

**What to build:** Re-running to-spec against a spec that is already published updates the existing items instead of duplicating them. Each item is identified by the Work Ref in the Spec Page's key table, so renumbering stories is harmless.
- To Do items are rewritten.
- In Progress and Done items get a comment instead, and `publish` returns them in `held`.
- A To Do Story moved to another Epic is re-parented. A started one gets a comment.
- A user story removed from the spec is never deleted. It gets a "removed from spec" comment and is reported as held.

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] Scenario: re-running unchanged creates no new items and no duplicate comments
- [ ] Scenario: a Done Story's text changed in the spec, so it gets a comment and is held, and is not rewritten
- [ ] Scenario: a To Do Story moved to a different Epic is re-parented
- [ ] Scenario: a removed user story gets a "removed from spec" comment, is held, and is not deleted
- [ ] Scenario: renumbered user stories map to their existing keys
