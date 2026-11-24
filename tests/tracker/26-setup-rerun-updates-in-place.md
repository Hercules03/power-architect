# 26: Re-running setup updates the existing `## Tracker` section in place

**Phase:** /power-architect:setup-tracker jira

## Given
- Repo instructions files: AGENTS.md exists with no `## Tracker` section (content: `# Agents`). CLAUDE.md holds an older, stale section followed by another section:
  ```md
  # Project notes

  ## Tracker
  adapter: jira
  site: https://acme.atlassian.net
  cloud-id: 11111111-2222-3333-4444-555555555555
  project: WEB
  board: 13

  ## Testing
  Run `npm test`.
  ```
- Tracker state: stubbed Rovo table. A tool reached through `discover` and `executeRead` matches the row with its own name.

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | atlassianUserInfo | any | {account_id: "u-1", name: "Dana"} |
  | getAccessibleAtlassianResources | any | [{id: "11111111-2222-3333-4444-555555555555", url: "https://acme.atlassian.net", name: "acme"}] |
  | discover | any | the tools in this table whose names match the query |
  | listJiraProjects | any | [{key: "PA", name: "Power Architect"}, {key: "WEB", name: "Website"}] |
  | listJiraBoards | any | [{id: 12, name: "PA board", type: "scrum"}] |
  | listConfluenceSpaces | any | [{id: "98765", key: "PASPEC", name: "PA Specs"}] |
  | listJiraProjectIssueTypesMetadata | any | [{name: "Epic", hierarchyLevel: 1}, {name: "Story", hierarchyLevel: 0}, {name: "Bug", hierarchyLevel: 0}, {name: "Sub-task", hierarchyLevel: -1, subtask: true}] |
  | listJiraIssueLinkTypes | any | [{name: "Blocks", outward: "blocks", inward: "is blocked by"}, {name: "Relates", outward: "relates to", inward: "relates to"}] |
  | getJiraWorkflows | any | [{name: "PA workflow", statuses: [{name: "To Do", category: "To Do"}, {name: "In Progress", category: "In Progress"}, {name: "Done", category: "Done"}]}] |

- Ledger / local files: none relevant

## When
The user runs `/power-architect:setup-tracker jira` again and picks project `PA` (other lists have one entry, which the agent may use and say so). When shown the proposed section and status mapping, the user replies "yes".

## Then
- The agent finds the existing `## Tracker` section in CLAUDE.md and says it will be replaced
- CLAUDE.md still has exactly one `## Tracker` heading, now with `project: PA`, `board: 12` and every other key of a complete section; `project: WEB` and `board: 13` are gone
- The `# Project notes` heading and the `## Testing` section of CLAUDE.md are unchanged
- AGENTS.md is unchanged: no `## Tracker` section is added there
- No Sprint or board is created or changed (no `manageJiraSprint`, no `createJiraBoard`)
