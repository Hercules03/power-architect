# 07: Offline queue and replay

**What to build:** When Jira can't be reached:
- `record` returns `queued` and writes the event to the ledger's `## Tracker queue`, with an id. The calling phase carries on.
- The next `pull` that reaches Jira replays the queue first, in order, marks each entry sent, and never duplicates a comment or a status change.
- `publish` and `pull` themselves stop and say so.

The result: build keeps delivering through a Jira outage, and its updates arrive later.

**Blocked by:** 06

**Status:** done

- [x] Scenario: Jira goes down mid-build, so the remaining started and done events are queued and the build completes
- [x] Scenario: the next run replays the queue in order before pulling, and each event lands exactly once
- [x] Scenario: replay is interrupted partway, so a re-run sends only the unsent entries
- [x] Scenario: build starts while Jira is unreachable, so `pull` stops and nothing is built on a guess
