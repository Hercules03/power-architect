# Jira owns the work; the repo owns the knowledge

In Jira Mode, Jira is the source of truth for the work: Epics, Stories, Sub-tasks, Sprints, status, and a spec's shared context (a Confluence page). Knowledge Docs (GLOSSARY.md, ADRs, DESIGN.md, AGENTS.md) always stay in the repo, because agents read them alongside the code and they must be versioned with it. Jira links to them and never copies them. So grill and design-interface write nothing to Jira. Only to-spec and plan create work items.

**Considered Options**: everything in Jira (rejected: Knowledge Docs drift from the code, and closed tickets bury long-lived decisions); repo-first with Jira as a read-only mirror (rejected: Jira would not be the place where progress is tracked).
