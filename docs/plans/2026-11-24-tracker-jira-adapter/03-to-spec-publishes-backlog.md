# 03: to-spec publishes the Backlog

**What to build:** In Jira Mode, `/power-architect:to-spec` shows a proposed grouping of the spec's user stories into Epics as a table at the spec gate. Once the user approves, it calls `publish`, which creates:
- the Confluence Spec Page holding the shared context and a key table
- one Epic per group, holding its own slice of goals and decisions and linking to the Spec Page and the relevant ADRs
- one Story per user story under its Epic, with the user-story sentence and Acceptance Criteria

A Small-tier spec creates one Story (under a named or new Epic) and has no grouping step. When Jira can't be reached, to-spec stops and says so. In local mode, to-spec writes the spec file exactly as it does today.

**Blocked by:** 02

**Status:** done

- [x] Scenario: a Large spec with 8 stories gives a grouping table at the gate, and after approval the expected Spec Page, Epics and Stories are created with keys recorded
- [x] Scenario: a Small spec creates one Story, with no grouping table
- [x] Scenario: nothing is published before the gate is approved
- [x] Scenario: Rovo unreachable, so to-spec stops and reports it, and nothing is half-written
- [x] Local-mode regression: same behaviour as today, and the Jira adapter is never read
- [x] The locality grep check passes
