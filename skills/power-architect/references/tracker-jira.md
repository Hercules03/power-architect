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
| `searchConfluence` | find an earlier Spec Page by title (hint: a CQL query; parameters unverified) | | primary |
| `getConfluenceContent` | read the Spec Page body and key table (hint: page id or URL, Markdown body; parameters unverified) | `getConfluencePage` | primary |
| `getJiraIssue` | read an item's summary, description, status and parent (hints: `issueIdOrKey`, `view: full` or those `fields`, `responseContentFormat: markdown`) | | primary |
| `listJiraIssueComments` | an item's comments (hint: `issueIdOrKey`) | | primary |
| `editJiraIssue` | rewrite an item's summary, description or parent (hints: `issueIdOrKey`, `fields`, `contentFormat`) | | primary |
| `addOrEditJiraIssueComment` | add a comment (hints: `issueIdOrKey`, `commentBody`; never pass `commentId`, which edits an existing comment) | `addCommentToJiraIssue` | primary |

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

Implements [`publish(outline)`](tracker.md#publishoutline) for to-spec's outline: the Spec Page, Epics and Stories. A first publish creates every item. A re-run updates the recorded items in place (see [Re-run](#re-run)).

**Recorded items.** The items recorded for a spec are the rows of the key table on its Spec Page (step 7), plus the outline's recorded Work Refs (the ledger's `## Work Refs` rows) that the key table lacks, as [Re-run](#re-run) step 1 merges them. An item the outline gives as an existing Work Ref that is not recorded (such as an existing Epic the user named for a Small-tier spec) is used as is, on every run: never created, edited, re-parented, commented on, marked removed, or added to the key table.

**Work Refs.** An Epic's or Story's Work Ref is its issue key (for example `PA-12`). The Spec Page's Work Ref is the page's URL.

Make these calls in this order, one at a time. Pass `cloudId` on each Jira and Confluence call. Never pass a Sprint, backlog, priority, story-point or estimate field; leave those blank.

1. **Reach Jira.** Call `atlassianUserInfo`. If it fails, stop and write nothing. Tell the user Jira can't be reached, so nothing was published, and that `/mcp` reconnects the Rovo MCP server. Return an empty map.
2. **Format.** If `discover` finds `getContentFormatGuide`, read it once and follow it for tables and task lists.
3. **Earlier publish.** If the outline names the Spec Page's Work Ref, this is a re-run: go to [Re-run](#re-run). Otherwise `searchConfluence` for a page with the spec's title in the space `confluence-space` (for example CQL `space = "<confluence-space>" AND type = page AND title = "<spec title>"`). If it finds one, show the user its title and URL, ask whether it is this spec's Spec Page, and write nothing until they answer. Yes: go to Re-run with that page. No, or no page found: carry on with step 4.
4. **Spec Page.** `createConfluenceContent`: `contentType` `page`, `title` the spec's title, `parent` {`spaceId`: `confluence-space-id`}, `body` {`format`: `markdown`, `value`: the Spec Page body}. No key table yet.
5. **Epics.** For each new Epic, in outline order, `createJiraIssue`: project `project`, issue type `type-epic`, `summary` its name, `contentFormat` `markdown`, `description`:
   - its slice of the goals and decisions
   - `Spec Page: <page URL>`
   - `ADRs:` one line per ADR link: title, path, and URL if the outline gives one (no `ADRs:` line when it has none)
6. **Stories.** After every Epic, for each new Story in outline order, `createJiraIssue`: project `project`, issue type `type-story`, `parent` its Epic's key, `summary` its title, `contentFormat` `markdown`, `description`:
   - the user-story sentence
   - `## Acceptance Criteria`, then one `- [ ]` line per check
   - `Spec Page: <page URL>`

   If Jira rejects the Epic as a Story's parent, stop: tell the user this project does not let a Story sit under an Epic, then report as for a failed call.
7. **Key table.** `updateConfluenceContent` on the page: the same body, followed by:

   ```md
   ## Work Refs

   | outline id | kind | Work Ref | title |
   |---|---|---|---|
   | spec | Spec Page | <page URL> | <spec title> |
   | E1 | Epic | <key> | <name> |
   | 1 | Story | <key> | <title> |
   ```

   One row per item created from this spec: the Spec Page, then the Epics, then the Stories, in outline order. Sub-task rows are appended below them later. This table is how a re-run finds each item.
8. **Return** the outline id → Work Ref map (the table's rows) and empty `held` and `declined` lists. Tell the user the Spec Page URL and the Epics and Stories created, with their keys.

**A call fails after step 1.** Stop at once. Make no further call: no retry and no key table. If the Spec Page create itself failed, nothing was created: tell the user nothing was published. Otherwise tell the user the spec is only partly published, with a table of what was created (outline id, kind, Work Ref) and a list of what was not. Return the created items as the map, so the phase records them. On a re-run, the map also holds every recorded item.

### Re-run

Read first, then get one go-ahead, then write. Make no write before the go-ahead. These rules apply to every outline item, whatever its kind.

1. **Recorded items.** `getConfluenceContent` on the Spec Page, with a Markdown body. Its `## Work Refs` table lists the recorded items. Add each row of the outline's recorded Work Refs (from the ledger) whose Work Ref is not in that table: a publish that stopped partway created it. Where both list a Work Ref, the page's row wins. If the page has no key table, the ledger's rows are the recorded items.
2. **Read** each recorded item of a kind this outline carries with `getJiraIssue`: its summary, description (Markdown), status and parent. Rows of other kinds (Sub-task rows, when to-spec publishes) are kept unchanged and are not read, paired or marked removed.
3. **Pair** each outline item with a recorded item of the same kind, so renumbering is harmless. The Spec Page pairs with the `spec` row.
   1. Same text, after normalising (see step 4): an Epic's name against the summary; a Story pairs when **either** its title matches the summary **or** its user-story sentence(s) match the first paragraph of the description.
   2. Then the same outline id, among the items still unpaired. A row whose outline id is `—` never pairs by id.
   3. An outline item still unpaired is **new**. A recorded item still unpaired is **removed from spec**.

   If a recorded item could pair with more than one outline item, or an outline item with more than one recorded item, list those pairs and ask the user which is right. Wait for the answer.
4. **Decide** each paired item. Never re-draft an item: its text starts from what step 2 read.
   - **Did the spec change it?** Compare the approved spec's content for the item (an Epic's name, slice and ADR links; a Story's title, user-story sentence, each Acceptance Criteria check and its Epic) with the same content in what step 2 read, piece by piece. Never compare freshly drafted prose with the read text: a difference that comes only from drafting again is no change.
   - **Normalise before comparing any text:** ignore case and whitespace, list markers (`-`, `*`, `+`, `1.`, and a `[ ]` or `[x]` box), Markdown escapes (`\-` is `-`), and link wrapping (a bare URL, `<url>` and `[text](url)` are equal). Equal after normalising means unchanged: no write.
   - **New text** for a changed item is the read summary and description with only the pieces the spec changed replaced, added or removed. Every other line stays exactly as read.

   An item is **not started** when its status is in `status-todo`, and **started** otherwise (In Progress, Done, or a status in no bucket).

   | The spec… | Not started | Started |
   |---|---|---|
   | did not change it | nothing | nothing |
   | changed its summary or description | **update**: rewrite them | **held**: comment what changed |
   | moved the Story to another Epic | **re-parent** | **held**: comment the move |

   A removed item is **held** whatever its status, with a "removed from spec" comment. It is never deleted, closed or transitioned, and its key table row stays.
5. **Comments are written once.** One comment per item. Each starts with a fixed first line:
   - held (changed, moved, or both): first line `Spec change not applied (item started)`. Then one fenced code block (so Jira keeps the `+`/`-` markers and does not turn URLs into links) holding the changed lines only: `Summary: <old> → <new>`, each description line removed (`- <line>`) and added (`+ <line>`), and for a move `Epic: <old key> → <new key> (<name>)`. Then `Spec Page: <page URL>`.
   - removed: first line `Removed from spec`. Then `This item is no longer in the spec. It was not deleted or closed. Spec Page: <page URL>`

   Read the item's comments with `listJiraIssueComments`. A held comment is already there when one has the same first line and the same changed lines after normalising (step 4). A removed comment is already there when one has the first line `Removed from spec`. Then add no new one. The item is still held.
6. **Change summary.** Show the user a table of what would be created, updated, re-parented, held (with the reason) and removed from spec. If there is nothing to write (no create, update, re-parent or new comment, and the page body and key table read in step 1 already match step 8), say the Tracker is already up to date, make no write, and go to step 9. Otherwise ask the user to go ahead, and wait. If they decline, write nothing (no comment either) and go to step 9: every item the summary would have written is **declined**, not held.
7. **Write**, one call at a time, parents first: Epics in outline order, then Stories in outline order, then removed items.
   - new: create it as steps 5 and 6 do. A Story's parent is its Epic's key, new or recorded.
   - update: `editJiraIssue` with `fields` `summary` and `description`, and `contentFormat` `markdown`.
   - re-parent: `editJiraIssue` with `fields` `parent` set to the new Epic's key (in the same call as an update, when both apply).
   - held: `addOrEditJiraIssueComment` with the step 5 text, Markdown, and no `commentId`, unless step 5 skipped it.

   Never call a transition, and never delete.
8. **Spec Page.** Start the body from what step 1 read, and change only the parts the approved spec changed, deciding and comparing as step 4 does. If the body or the key table differs from what step 1 read after normalising, `updateConfluenceContent` as the last call: the Spec Page body followed by the key table. Rows: the Spec Page; the Epics, then the Stories, in outline order, each with its new outline id, its title and its Work Ref (recorded or new); then each removed item, with outline id `—` and its old title; then the kept rows of other kinds, unchanged. Every recorded row stays, and no Work Ref changes.
9. **Return** the map (every key table row), `held` (each item left untouched by the started-item or removed rule, with its reason, whose comment was written or was already there) and `declined` (each item the user declined in step 6; empty otherwise). Tell the user what was created, updated and re-parented, and each held item with its reason. If they declined, tell them nothing was written and list the declined items.

A failed call is handled as in "A call fails after step 1" above.
