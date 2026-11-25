# 21: Setup stops with connection instructions when Rovo is not connected

**Phase:** /power-architect:setup-tracker jira

## Given
- Repo instructions file (AGENTS.md): exists, with no `## Tracker` section
- Tracker state: stubbed Rovo table. The server is configured but the user is not signed in:

  | Tool | Called with (match) | Returns |
  |---|---|---|
  | * | any | error: 401 Unauthorized (sign-in required) |

- Ledger / local files: none relevant

## When
The user runs `/power-architect:setup-tracker jira`.

## Then
- The agent opens the Tracker contract (`references/tracker.md`), then the Jira Tracker Adapter (`references/tracker-jira.md`), and runs its Install section
- The first MCP call is a connection check (`atlassianUserInfo` or `getAccessibleAtlassianResources`), and it fails
- The agent stops and tells the user the Rovo MCP server is not connected or not signed in, and how to fix it (connect or re-authenticate the server; in Claude Code, `/mcp`)
- No project, board, space, issue-type or status call is made after the failed check
- No file is written: AGENTS.md is unchanged and no CLAUDE.md is created
