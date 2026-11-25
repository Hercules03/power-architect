# Talk to Jira only through the Atlassian Rovo MCP server

Power Architect is prompt-only, with no code to install or maintain, so it reaches Jira and Confluence only through Atlassian's official Rovo MCP server, which signs in with OAuth. That server can move work items between statuses and into Sprints, but it cannot create Sprints. Sprint creation and scoping therefore stay with the user as Product Owner, and the agent never starts, closes, or edits a Sprint.

**Considered Options**: shipped scripts calling the Jira REST and Agile APIs with an API token (rejected: adds code and secret handling to a code-free skill); Atlassian's `acli` CLI (rejected: another install, and it is less suited to agent use than MCP).
