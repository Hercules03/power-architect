# Jira Tracker Adapter

Implements the [Tracker contract](tracker.md) for Jira Cloud, through the Atlassian Rovo MCP server only (ADR-0002). The Spec Page lives in Confluence. This is the only skill file that names Jira, Rovo, Confluence, MCP tools or ADF.

## Calling Rovo

- **Finding tools.** The server (`https://mcp.atlassian.com/v2/mcp`) always lists a few primary tools. Reach every other tool with `discover`, then run it through `executeRead` (reads) or `executeWrite` (writes). Never call `executeDestructive`. This adapter deletes nothing.
- **Names.** Tool names can carry a client prefix (such as `mcp__atlassian__`, or `v2`), so match tools by suffix. If a tool below is missing, look for its older name.
- **Parameters.** Sources disagree on parameter names. Before each call, read the tool's live input schema and follow it. Parameter names in this file are hints only.
- **cloudId.** Pass it on every call except the two below that list sites or the user. Take it from the `cloud-id:` line of the `## Tracker` section, or from the site list during Install.
- **Text.** Write descriptions, comments and page bodies as Markdown (`contentFormat: markdown`). Never build ADF; it is not needed.
- **No Sprint control.** Never call `manageJiraSprint` or `createJiraBoard`, and never pass a sprint or backlog assignment (such as `assignToSprint`, `sprintId`, `assignToBacklog`) to a create or transition call. Reading boards and Sprints is fine. Never set story points or estimates.

| Tool | Used for | Older name | Reached by |
|---|---|---|---|
| `atlassianUserInfo` | connection check | | primary |
| `getAccessibleAtlassianResources` | sites and their cloudId | | primary |
| `listJiraProjects` | projects | `getVisibleJiraProjects` | `discover` |
| `listJiraBoards` | boards | | `discover` |
| `listConfluenceSpaces` | Confluence spaces (key and id) | `getConfluenceSpaces` | `discover` |
| `listJiraProjectIssueTypesMetadata` | a project's issue types (hint: `projectIdOrKey`) | `getJiraProjectIssueTypesMetadata` | `discover` |
| `listJiraIssueLinkTypes` | link type names | | `discover` |
| `getJiraWorkflows` | workflow statuses (admin-disabled by default) | | `discover` |
| `listJiraStatuses` | status list | | `discover` |
| `searchJiraIssuesUsingJql` | find one existing issue (hint: `jql`, `maxResults`) | | primary |
| `listJiraIssueTransitions` | an issue's transitions | `getTransitionsForJiraIssue` | `discover` |
| `getContentFormatGuide` | how page bodies are formatted (unverified name) | | `discover` |
| `createConfluenceContent` | create the Spec Page (hints: `contentType`, `title`, `parent` {`spaceId`}, `body` {`format`, `value`}) | `createConfluencePage` | primary |
| `updateConfluenceContent` | replace the Spec Page body (hints: `contentId`, `body`) | `updateConfluencePage` | primary |
| `createJiraIssue` | create an Epic or Story (hints: `projectKey`, issue type, `summary`, `description`, `parent`) | | primary |

## The `## Tracker` section

Install writes these lines, one per line, in this order. Values are as Jira returns them, never translated.

| Key | Value |
|---|---|
| `adapter` | `jira` |
| `site` | the site URL |
| `cloud-id` | the site's cloudId |
| `project` | the project key |
| `board` | the board id |
| `confluence-space` | the Confluence space key for Spec Pages |
| `confluence-space-id` | that space's id |
| `type-epic`, `type-story`, `type-subtask`, `type-bug` | the project's issue-type names for Epic, Story, Sub-task and Bug |
| `status-todo`, `status-in-progress`, `status-done` | every workflow status in that bucket, comma-separated. The first is the one items are moved to |
| `link-blocks`, `link-relates` | the link-type names for "blocks" and "relates to" |

**Config check** (run at selection, with no MCP call): every key above is present with a value, and `adapter` is `jira`. If not, stop, name the missing keys, and recommend `/power-architect:setup-tracker jira`.

## Install

Run by `/power-architect:setup-tracker jira`. Write nothing until step 8. If any call in steps 2–7 fails for a reason other than the fallbacks below, stop and say which step failed.

1. **Connection.** Call `atlassianUserInfo`, then `getAccessibleAtlassianResources`. If either fails or is missing, stop and write nothing. Tell the user the Rovo MCP server is not connected or not signed in: add the server `https://mcp.atlassian.com/v2/mcp` to their client and sign in. In Claude Code, run `/mcp` to connect or re-authenticate. Then run this command again.
In steps 2 and 3, the user picks from lists you fetch. Never ask the user for an id or key you can list. If a list has exactly one entry, use it and say so.

2. **Site.** From the site list, ask the user to pick one. Record its URL and cloudId.
3. **Project, board and Confluence space.** List each (`listJiraProjects`, `listJiraBoards` for the project, `listConfluenceSpaces`) and ask the user to pick.
4. **Issue types.** Call `listJiraProjectIssueTypesMetadata` for the project. Use the names exactly as returned:
   - Epic: the type at hierarchy level 1.
   - Sub-task: the sub-task type (level -1). Its name varies by project (for example `Sub-task` or `Subtask`), so never assume it.
   - Story and Bug: the level-0 types named Story and Bug.
   - If any of the four is missing or ambiguous, ask the user to pick from the project's types.
5. **Link types.** Call `listJiraIssueLinkTypes`. Pick the type whose outward text is "blocks" and the one whose text is "relates to". If either is missing, ask the user to pick.
6. **Statuses.** Find the project's workflow statuses:
   1. Try `getJiraWorkflows`. It is often disabled by the site admin. If it fails, go on.
   2. Otherwise call `listJiraStatuses` for the project.
   3. If that also fails, find one issue in the project with `searchJiraIssuesUsingJql` (`project = <key>`) and read its statuses from `listJiraIssueTransitions`.

   Put each status in exactly one bucket: To Do, In Progress or Done. Use the status category when the tool returns one; otherwise propose by name. In each bucket, put first the status that items should move to.
7. **Confirm.** Show the user the full proposed section, with the status mapping as a table, and ask them to confirm or correct it. If AGENTS.md or CLAUDE.md already has a `## Tracker` section, say which file it is in and that it will be replaced. Wait. Write nothing before they confirm.
8. **Write.** Write the section described above:
   - If AGENTS.md or CLAUDE.md already has a `## Tracker` section, replace that section in place: its heading and every line up to the next `#` or `##` heading. Never add a second `## Tracker` section.
   - Otherwise append it to AGENTS.md if that exists, else to CLAUDE.md if that exists, else create AGENTS.md with it.
   - Leave every other line of the file unchanged.

   Tell the user which file was written and that the repo is now in Jira Mode.

## publish

Implements [`publish(outline)`](tracker.md#publishoutline) for to-spec's outline: the Spec Page, Epics and Stories. Every item in the outline is created new, except an item that already carries a Work Ref (such as an existing Epic the user named). That item is used as is: never created, edited or added to the key table.

**Work Refs.** An Epic's or Story's Work Ref is its issue key (for example `PA-12`). The Spec Page's Work Ref is the page's URL.

Make these calls in this order, one at a time. Pass `cloudId` on each Jira and Confluence call. Never pass a Sprint, backlog, priority, story-point or estimate field; leave those blank.

1. **Reach Jira.** Call `atlassianUserInfo`. If it fails, stop and write nothing. Tell the user Jira can't be reached, so nothing was published, and that `/mcp` reconnects the Rovo MCP server. Return an empty map.
2. **Format.** If `discover` finds `getContentFormatGuide`, read it once and follow it for tables and task lists.
3. **Spec Page.** `createConfluenceContent`: `contentType` `page`, `title` the spec's title, `parent` {`spaceId`: `confluence-space-id`}, `body` {`format`: `markdown`, `value`: the Spec Page body}. No key table yet.
4. **Epics.** For each new Epic, in outline order, `createJiraIssue`: project `project`, issue type `type-epic`, `summary` its name, `contentFormat` `markdown`, `description`:
   - its slice of the goals and decisions
   - `Spec Page: <page URL>`
   - `ADRs:` one line per ADR link: title, path, and URL if the outline gives one
5. **Stories.** After every Epic, for each Story in outline order, `createJiraIssue`: project `project`, issue type `type-story`, `parent` its Epic's key, `summary` its title, `contentFormat` `markdown`, `description`:
   - the user-story sentence
   - `## Acceptance Criteria`, then one `- [ ]` line per check
   - `Spec Page: <page URL>`

   If Jira rejects the Epic as a Story's parent, stop: tell the user this project does not let a Story sit under an Epic, then report as for a failed call.
6. **Key table.** `updateConfluenceContent` on the page: the same body, followed by:

   ```md
   ## Work Refs

   | outline id | kind | Work Ref | title |
   |---|---|---|---|
   | spec | Spec Page | <page URL> | <spec title> |
   | E1 | Epic | <key> | <name> |
   | 1 | Story | <key> | <title> |
   ```

   One row per item created from this spec: the Spec Page, then the Epics, then the Stories, in outline order. Sub-task rows are appended below them later. This table is how a re-run finds each item.
7. **Return** the outline id → Work Ref map (the table's rows) and an empty `held` list. Tell the user the Spec Page URL and the Epics and Stories created, with their keys.

**A call fails after step 1.** Stop at once. Make no further call: no retry and no key table. If the Spec Page create itself failed, nothing was created: tell the user nothing was published. Otherwise tell the user the spec is only partly published, with a table of what was created (outline id, kind, Work Ref) and a list of what was not. Return the created items as the map, so the phase records them.
