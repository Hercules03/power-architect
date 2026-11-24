# 22: A team-managed project's issue-type names are found and recorded as returned

**Phase:** /power-architect:setup-tracker jira

## Given
- Repo instructions file: no AGENTS.md; CLAUDE.md exists with this content and no `## Tracker` section:
  ```md
  # Project notes

  ## Testing
  Run `npm test`.
  ```
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` matches the row with its own name.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | getAccessibleAtlassianResources | any | [{id: "11111111-2222-3333-4444-555555555555", url: "https://acme.atlassian.net", name: "acme"}] |
  | discover | any | the tools in this table whose names match the query |
  | listJiraProjects | any | [{key: "MOB", name: "Mobile", style: "next-gen (team-managed)"}] |
  | listJiraBoards | any | [{id: 31, name: "MOB board", type: "scrum"}] |
  | listConfluenceSpaces | any | [{id: "55555", key: "MOBSPEC", name: "Mobile Specs"}] |
  | listJiraProjectIssueTypesMetadata | projectIdOrKey=MOB | [{name: "Epic", hierarchyLevel: 1}, {name: "Story", hierarchyLevel: 0}, {name: "Task", hierarchyLevel: 0}, {name: "Bug", hierarchyLevel: 0}, {name: "Subtask", hierarchyLevel: -1, subtask: true}] |
  | listJiraIssueLinkTypes | any | [{name: "Blocks", outward: "blocks", inward: "is blocked by"}, {name: "Relates", outward: "relates to", inward: "relates to"}] |
  | getJiraWorkflows | any | [{name: "MOB workflow", statuses: [{name: "To Do", category: "To Do"}, {name: "In Progress", category: "In Progress"}, {name: "Done", category: "Done"}]}] |
  | listJiraStatuses | any | [{name: "To Do", category: "To Do"}, {name: "In Progress", category: "In Progress"}, {name: "Done", category: "Done"}] |

- Ledger / local files: none relevant

## When
The user runs `/power-architect:setup-tracker jira`. Each list has one entry, so the agent may use it and say so. When shown the proposed section and status mapping, the user replies "yes".

## Then
- `listJiraProjectIssueTypesMetadata` is called for project `MOB`, with the site's cloudId
- The proposed section shown to the user names the Sub-task type `Subtask`, exactly as returned, and Epic `Epic`, Story `Story`, Bug `Bug`
- Nothing is written before the user's "yes"
- CLAUDE.md gains one `## Tracker` section with `adapter: jira` and `type-subtask: Subtask`; the name `Sub-task` appears nowhere in it
- The `## Testing` section of CLAUDE.md is unchanged, and no AGENTS.md is created
- No Sprint or board is created or changed (no `manageJiraSprint`, no `createJiraBoard`)
