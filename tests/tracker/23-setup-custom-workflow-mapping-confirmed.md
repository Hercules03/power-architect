# 23: A custom workflow gets a proposed status mapping, confirmed before anything is written

**Phase:** /power-architect:setup-tracker jira

## Given
- Repo instructions file (AGENTS.md): exists, with no `## Tracker` section
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` matches the row with its own name. The workflow tool is disabled by the site admin.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | getAccessibleAtlassianResources | any | [{id: "11111111-2222-3333-4444-555555555555", url: "https://acme.atlassian.net", name: "acme"}] |
  | discover | any | the tools in this table whose names match the query |
  | listJiraProjects | any | [{key: "PA", name: "Power Architect"}] |
  | listJiraBoards | any | [{id: 12, name: "PA board", type: "scrum"}] |
  | listConfluenceSpaces | any | [{id: "98765", key: "PASPEC", name: "PA Specs"}] |
  | listJiraProjectIssueTypesMetadata | any | [{name: "Epic", hierarchyLevel: 1}, {name: "Story", hierarchyLevel: 0}, {name: "Bug", hierarchyLevel: 0}, {name: "Sub-task", hierarchyLevel: -1, subtask: true}] |
  | listJiraIssueLinkTypes | any | [{name: "Blocks", outward: "blocks", inward: "is blocked by"}, {name: "Relates", outward: "relates to", inward: "relates to"}] |
  | getJiraWorkflows | any | error: this tool is disabled by your site admin |
  | listJiraStatuses | any | [{name: "Backlog", category: "To Do"}, {name: "Selected for Development", category: "To Do"}, {name: "Doing", category: "In Progress"}, {name: "Code Review", category: "In Progress"}, {name: "Shipped", category: "Done"}] |

- Ledger / local files: none relevant

## When
The user runs `/power-architect:setup-tracker jira`. Each list has one entry, so the agent may use it and say so. The user has not yet answered the status-mapping question.

## Then
- The agent tries the workflow tool (`getJiraWorkflows`); its failure does not stop setup
- The agent falls back to the status list (`listJiraStatuses`) for the project
- The agent shows a proposed To Do / In Progress / Done mapping in which each of the five statuses (Backlog, Selected for Development, Doing, Code Review, Shipped) appears under exactly one of To Do, In Progress or Done
- The agent asks the user to confirm or correct the mapping, and waits
- No file is written before that answer: AGENTS.md has no `## Tracker` section and no CLAUDE.md is created
