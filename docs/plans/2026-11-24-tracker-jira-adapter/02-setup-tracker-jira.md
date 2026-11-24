# 02: `/setup-tracker jira` puts a repo into Jira Mode

**What to build:** A user runs `/power-architect:setup-tracker jira` and their repo enters Jira Mode. The command runs the Jira Tracker Adapter's Install section, which:
- checks the Rovo MCP server is connected and signed in, and explains how to connect it if not
- lists sites, projects and boards to pick from, and asks for the Confluence space
- finds the project's issue-type names for Epic, Story, Sub-task and Bug
- reads the workflow and proposes a To Do / In Progress / Done mapping for the user to confirm
- writes a `## Tracker` section with `adapter: jira` into AGENTS.md or CLAUDE.md

The command is listed in the skill's command table and the README. The Jira Tracker Adapter exists as the only module that names Rovo, MCP tools or ADF.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] The setup command exists and is listed in the command table and the README
- [ ] Scenario: Rovo not connected, so setup stops with connection instructions and writes nothing
- [ ] Scenario: a team-managed project's issue-type names are found and recorded
- [ ] Scenario: a custom workflow gets a proposed status mapping that the user confirms before it is written
- [ ] The written `## Tracker` section is complete enough to pass the contract's selection check
- [ ] The locality grep check passes
