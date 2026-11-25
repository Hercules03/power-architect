# 08: Defects and Sprint Bugs

**What to build:**
- In Jira Mode, `/power-architect:debug` records a defect found inside current work as a comment on that work item. A defect found outside current work becomes a Bug in the Backlog.
- `/power-architect:review` always passes the current item's ref, so its findings become comments and never Bugs.
- When the Product Owner puts a Bug into the active Sprint, build's work list includes it. Build fixes it with the debug method (a regression test first) and records started and done on the Bug.

**Blocked by:** 06

**Status:** done

- [x] Scenario: debug inside current work comments on that item, and no Bug is created
- [x] Scenario: debug outside current work creates a Bug in the Backlog, not in a Sprint
- [x] Scenario: review findings produce comments only
- [x] Scenario: a Bug in the Sprint is built test-first and moves In Progress, then Done, with evidence
- [x] Local-mode regression and the locality grep check pass
