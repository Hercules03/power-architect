# 09: verify closes Stories; finish links the delivery

**What to build:**
- In Jira Mode, `/power-architect:verify` pulls the spec's Stories, checks each one against its own Acceptance Criteria with fresh evidence, and moves it to Done only when they all pass. It stops when Jira can't be reached.
- `/power-architect:finish`, after a PR or merge, records `shipped`, which comments the PR or merge link on every Story with at least one Sub-task done in this branch and changes no status. When Jira can't be reached, that comment is queued.

**Blocked by:** 07

**Status:** done

- [x] Scenario: a Story with all Acceptance Criteria proven moves to Done, with evidence in a comment
- [x] Scenario: a Story with one failing criterion stays open, and verify reports the gap
- [x] Scenario: unreachable, so verify stops
- [x] Scenario: finish comments the link on only the Stories delivered in this branch, with no status change
- [x] Scenario: unreachable during finish, so the link comment is queued and the merge or PR still goes ahead
- [x] Local-mode regression and the locality grep check pass
