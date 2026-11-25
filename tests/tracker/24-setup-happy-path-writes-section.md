# 24: Setup lets the user pick from lists and writes a complete `## Tracker` section

**Phase:** /power-architect:setup-tracker jira

## Given
- Repo instructions file: AGENTS.md exists with this content and no `## Tracker` section; CLAUDE.md also exists:
  ```md
  # Agents

  ## Testing
  Run `npm test`.
  ```
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` matches the row with its own name.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | getAccessibleAtlassianResources | any | [{id: "11111111-2222-3333-4444-555555555555", url: "https://acme.atlassian.net", name: "acme"}, {id: "99999999-8888-7777-6666-555555555555", url: "https://acme-sandbox.atlassian.net", name: "acme-sandbox"}] |
  | discover | any | the tools in this table whose names match the query |
  | listJiraProjects | cloudId=11111111-2222-3333-4444-555555555555 | [{key: "PA", name: "Power Architect"}, {key: "WEB", name: "Website"}] |
  | listJiraBoards | any | [{id: 12, name: "PA board", type: "scrum"}, {id: 13, name: "PA kanban", type: "kanban"}] |
  | listConfluenceSpaces | any | [{id: "98765", key: "PASPEC", name: "PA Specs"}, {id: "11223", key: "ENG", name: "Engineering"}] |
  | listJiraProjectIssueTypesMetadata | projectIdOrKey=PA | [{name: "Epic", hierarchyLevel: 1}, {name: "Story", hierarchyLevel: 0}, {name: "Task", hierarchyLevel: 0}, {name: "Bug", hierarchyLevel: 0}, {name: "Sub-task", hierarchyLevel: -1, subtask: true}] |
  | listJiraIssueLinkTypes | any | [{name: "Blocks", outward: "blocks", inward: "is blocked by"}, {name: "Relates", outward: "relates to", inward: "relates to"}, {name: "Duplicate", outward: "duplicates", inward: "is duplicated by"}] |
  | getJiraWorkflows | any | [{name: "PA workflow", statuses: [{name: "To Do", category: "To Do"}, {name: "In Progress", category: "In Progress"}, {name: "Done", category: "Done"}]}] |

- Ledger / local files: none relevant

## When
The user runs `/power-architect:setup-tracker jira` and answers each question in turn: site `acme`, project `PA`, board `PA board` (12), Confluence space `PASPEC`. When shown the proposed section and status mapping, the user replies "yes".

## Then
- The first MCP call is a connection check (`atlassianUserInfo` or `getAccessibleAtlassianResources`), and it succeeds
- The agent shows the user lists to pick the site, project, board and Confluence space from, and never asks the user to type an id
- Every Jira and Confluence call after the site is picked passes cloudId `11111111-2222-3333-4444-555555555555`
- The agent shows the proposed section, including the To Do / In Progress / Done mapping, and writes nothing before the user's "yes"
- AGENTS.md gains exactly this section, and its `## Testing` section is unchanged:
  ```md
  ## Tracker
  adapter: jira
  site: https://acme.atlassian.net
  cloud-id: 11111111-2222-3333-4444-555555555555
  project: PA
  board: 12
  confluence-space: PASPEC
  confluence-space-id: 98765
  type-epic: Epic
  type-story: Story
  type-subtask: Sub-task
  type-bug: Bug
  status-todo: To Do
  status-in-progress: In Progress
  status-done: Done
  link-blocks: Blocks
  link-relates: Relates
  ```
- CLAUDE.md is not changed
- No Sprint or board is created or changed (no `manageJiraSprint`, no `createJiraBoard`), and no work item is created
