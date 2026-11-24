# 05: plan publishes Sub-tasks

**What to build:** In Jira Mode, `/power-architect:plan` reads the spec with `pull(spec, outline)`.
- It cuts each Large-tier slice inside one Story. An exception is flagged and filed under its main Story with "relates to" links.
- After the user approves, `publish` creates one Sub-task per ticket or task, with "blocks" links for blocking edges, and writes the plan-level content (Goal, Architecture, Global Constraints, Review Focus) into a Plan section on the Spec Page.
- Small-tier Sub-tasks carry their exact steps and file paths.
- A plan re-run updates in place, using 04's rules.
- When Jira can't be reached, plan stops. In local mode, plan works as it does today.

**Blocked by:** 04

**Status:** done

- [x] Scenario: a Large plan creates Sub-tasks under the right Stories, with "blocks" links matching the blocking edges
- [x] Scenario: a slice spanning two Stories is flagged and gets "relates to" links
- [x] Scenario: a Small plan's Sub-tasks carry exact steps and file paths
- [x] Scenario: the Plan section appears on the Spec Page, and `pull(spec, outline)` returns it
- [x] Scenario: unreachable, so plan stops
- [x] Local-mode regression and the locality grep check pass
