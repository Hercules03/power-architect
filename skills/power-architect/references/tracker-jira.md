# Jira Tracker Adapter

Implements the [Tracker contract](tracker.md) for Jira Cloud, through the Atlassian Rovo MCP server only (ADR-0002). The Spec Page lives in Confluence. This is the only skill file that names Jira, Rovo, Confluence, MCP tools or ADF.

## Calling Rovo

- **Finding tools.** The server (`https://mcp.atlassian.com/v2/mcp`) always lists a few primary tools. Reach every other tool with `discover`, then run it through `executeRead` (reads) or `executeWrite` (writes). Never call `executeDestructive`. This adapter deletes nothing.
- **Names.** Tool names can carry a client prefix (such as `mcp__atlassian__`, or `v2`), so match tools by suffix. If a tool below is missing, look for its older name.
- **Parameters.** Sources disagree on parameter names. Before each call, read the tool's live input schema and follow it. Parameter names in this file are hints only.
- **cloudId.** Pass it on every call except the two below that list sites or the user. Take it from the `cloud-id:` line of the `## Tracker` section, or from the site list during Install.
- **Text.** Write descriptions, comments and page bodies as Markdown (`contentFormat: markdown`). Never build ADF; it is not needed.
- **No Sprint control.** Never call `manageJiraSprint` or `createJiraBoard`, and never pass a sprint, board or backlog assignment (such as `assignToSprint`, `sprintId`, `boardId`, `assignToBacklog`) to a create or transition call. Reading boards and Sprints is fine. Never set story points or estimates.

| Tool | Used for | Older name | Reached by |
|---|---|---|---|
| `atlassianUserInfo` | connection check | | primary |
| `getAccessibleAtlassianResources` | sites and their cloudId | | primary |
| `listJiraProjects` | projects | `getVisibleJiraProjects` | `discover` |
| `listJiraBoards` | boards | | `discover` |
| `listConfluenceSpaces` | Confluence spaces (key and id) | `getConfluenceSpaces` | `discover` |
| `listJiraProjectIssueTypesMetadata` | a project's issue types (hint: `projectIdOrKey`) | `getJiraProjectIssueTypesMetadata` | `discover` |
| `listJiraIssueLinkTypes` | link type names, with their inward and outward text | | `discover` |
| `getJiraWorkflows` | workflow statuses (admin-disabled by default) | | `discover` |
| `listJiraStatuses` | status list | | `discover` |
| `searchJiraIssuesUsingJql` | find existing issues (hint: `jql`, `maxResults`) | | primary |
| `getJiraBoardSprintData` | read the board's active Sprint and its issues (hints: `boardId`, `includeIssues`; the active Sprint is the default; parameters unverified). Read-only | | `discover` |
| `listJiraIssueTransitions` | an issue's transitions, each with its target status | `getTransitionsForJiraIssue` | `discover` |
| `transitionJiraIssue` | move an issue (hints: `issueIdOrKey`, `transitionId`; parameters unverified). Pass nothing else: no `fields`, `sprintId`, `boardId` or `assignToBacklog` | | primary |
| `getContentFormatGuide` | how page bodies are formatted (unverified name) | | `discover` |
| `createConfluenceContent` | create the Spec Page (hints: `contentType`, `title`, `parent` {`spaceId`}, `body` {`format`, `value`}) | `createConfluencePage` | primary |
| `updateConfluenceContent` | replace the Spec Page body (hints: `contentId`, `body`) | `updateConfluencePage` | primary |
| `createJiraIssue` | create an Epic, Story or Sub-task (hints: `projectKey`, issue type, `summary`, `description`, `parent`) | | primary |
| `createJiraIssueLink` | add a "blocks" or "relates to" link (hints: link type name as `linkType` or `type`, `inwardIssue`, `outwardIssue`; parameters and their direction unverified, see [Links](#links)) | `createIssueLink` | `discover` |
| `getConfluenceContent` | read the Spec Page body and key table (hint: page id or URL, Markdown body; parameters unverified) | `getConfluencePage` | primary |
| `getJiraIssue` | read an item's summary, description, status, parent and issue links (hints: `issueIdOrKey`, `view: full` or those `fields`, `responseContentFormat: markdown`; that `view: full` returns the links is unverified, so ask for the links field if it does not) | | primary |
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

The section is a `## Tracker` heading followed by one `key: value` line per key (for example `cloud-id: 1234`).

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

**An outline that carries Sub-tasks is plan's.** Go straight to [Plan publish](#plan-publish). The numbered steps below and [Re-run](#re-run) are for to-spec's outline only; Plan publish names the parts of them it reuses.

**Recorded items.** The items recorded for a spec are the rows of the key table on its Spec Page (step 7), plus the outline's recorded Work Refs (the ledger's `## Work Refs` rows) that the key table lacks, as [Re-run](#re-run) step 1 merges them. An item the outline gives as an existing Work Ref that is not recorded (such as an existing Epic the user named for a Small-tier spec) is used as is, on every run: never created, edited, re-parented, commented on, marked removed, or added to the key table.

**Work Refs.** An Epic's or Story's Work Ref is its issue key (for example `PA-12`). The Spec Page's Work Ref is the page's URL.

Make these calls in this order, one at a time. Pass `cloudId` on each Jira and Confluence call. Never pass a Sprint, backlog, priority, story-point or estimate field; leave those blank.

1. **Reach Jira.** Call `atlassianUserInfo`. If it fails, stop and write nothing. Tell the user Jira can't be reached, so nothing was published, and that `/mcp` reconnects the Rovo MCP server. Return an empty map.
2. **Format.** If `discover` finds `getContentFormatGuide`, read it once and follow it for tables and task lists.
3. **Earlier publish.** If the outline names the Spec Page's Work Ref, this is a re-run: go to [Re-run](#re-run). Otherwise this is a first publish: make no search call, and carry on with step 4.
4. **Spec Page.** `createConfluenceContent`: `contentType` `page`, `title` the spec's title, `parent` {`spaceId`: `confluence-space-id`}, `body` {`format`: `markdown`, `value`: the Spec Page body}. No key table yet. If the create is rejected as a duplicate title, stop here: see Duplicate title below.
5. **Epics.** For each new Epic, in outline order, `createJiraIssue`: project `project`, issue type `type-epic`, `summary` its name, `contentFormat` `markdown`, `description`:
   - its slice of the goals and decisions
   - `Spec Page: <page URL>`
   - `ADRs:` one line per ADR link: title, path, and URL if the outline gives one (no `ADRs:` line when it has none)
6. **Stories.** After every Epic, for each new Story in outline order, `createJiraIssue`: project `project`, issue type `type-story`, `parent` its Epic's key, `summary` its title, `contentFormat` `markdown`, `description`:
   - the user-story sentence, alone as the first paragraph: nothing else in that paragraph, because a re-run pairs and compares on it
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

**A call fails after step 1.** Stop at once. Make no further call: no retry and no key table. If the Spec Page create itself failed (other than as a duplicate title, below), nothing was created: tell the user nothing was published. Otherwise tell the user the spec is only partly published, with a table of what was created (outline id, kind, Work Ref) and a list of what was not. Return the created items as the map, so the phase records them. On a re-run, the map also holds every recorded item.

**Duplicate title.** The Spec Page create is rejected as a duplicate title when the Tracker refuses it because a page with that title already exists in the space `confluence-space`. Only that rejection counts. Its wording is unverified, so treat a rejection whose reason says the title is taken, or that a page with it already exists in that space, as this case. Any other create failure is handled above. A duplicate-title rejection is the first write's failure, so nothing else has been written: make no further call, return the failure with the title to the phase, and write nothing. The phase asks the user (to-spec step 7). A Work Ref or URL the user gives makes the run a re-run from that page. A new title is put in the outline, and the create is retried once with it.

### Re-run

Read first, then get one go-ahead, then write. Make no write before the go-ahead. These rules apply to every outline item, whatever its kind.

1. **Recorded items.** `getConfluenceContent` on the Spec Page, with a Markdown body. Its `## Work Refs` table lists the recorded items. Add each row of the outline's recorded Work Refs (from the ledger) whose Work Ref is not in that table: a publish that stopped partway created it. Where both list a Work Ref, the page's row wins. If the page has no key table, the ledger's rows are the recorded items.
2. **Read** each recorded item of a kind this outline carries with `getJiraIssue`: its summary, description (Markdown), status and parent. Rows of other kinds (Sub-task rows, when to-spec publishes) are kept unchanged and are not read, paired or marked removed.
3. **Pair** each outline item with a recorded item of the same kind, so renumbering is harmless. The Spec Page pairs with the `spec` row.
   1. Same text, after normalising (see step 4): an Epic's name against the summary; a Story's user-story sentence(s) against the first paragraph of the description.
   2. Then the same outline id, among the items still unpaired. A row whose outline id is `—` never pairs by id.
   3. An outline item still unpaired is **new**. A recorded item still unpaired is **removed from spec**, except as the next item says.
   4. **Ask, never guess.** If an outline item and a recorded item of the same kind both remain unpaired, do not create or mark removed yet: a started item keeps its old text, so after its sentence or name changed and the outline was renumbered it pairs by neither. Open the change summary with every candidate pair, one line each: `new: <sentence or name> / recorded: <Work Ref> <its sentence or name as read>`. Ask the user, for each remaining new item, "same as <Work Ref>" or "new", and wait. Make no write before the answer. "Same as" pairs the two, and **Decide** (step 4) handles them (a started Story whose sentence changed is **held** with a comment, never rewritten). An item answered "new" is created. A recorded item that no answer claims is removed from spec. The answer is final for this run. A recorded row already marked removed from spec (outline id `—`, already commented) is not a candidate for pairing and is never offered again: it stays removed unless the user names it explicitly.

   If a recorded item could pair with more than one outline item, or an outline item with more than one recorded item, list those pairs and ask the user which is right. Wait for the answer.
4. **Decide** each paired item.
   - **Only user-approved spec content is compared:** a Story's user-story sentence(s) against the first paragraph of its description; a Story's Epic against its parent; an Epic's name against its summary, and its member Stories against the approved grouping. Text the agent drafts (Story titles, Acceptance Criteria, Epic slices, ADR lines) is never compared: the earlier session's drafts are not kept, so the Tracker text is their only record.
   - **Normalise** sentences and names before comparing: ignore case and whitespace, list markers (`-`, `*`, `+`, `1.`, and a `[ ]` or `[x]` box), Markdown escapes (`\-` is `-`), and link wrapping (a bare URL, `<url>` and `[text](url)` are equal). Equal after normalising means unchanged: no write.
   - **Drafted text is kept verbatim as read.** Each paired item's summary and description start exactly as step 2 read them, and are never rewritten because the agent would word them differently now. Drafted text is redrafted only in these cases, and only on a not-started item:
     - **Sentence changed:** redraft the Story's title and Acceptance Criteria from the new sentence and the spec's Testing Decisions. New text: summary the new title; description the new sentence, the redrafted `## Acceptance Criteria`, and every other line as read.
     - **Membership changed:** this run creates a Story under an Epic, or re-parents a Story into or out of it. Redraft that Epic's slice; every other line stays as read. A held or removed Story does not change membership.
     - **User asks:** at the go-ahead (step 6) the user names an item to redraft.

     Show each redraft in the change summary.

     A redraft whose text equals the text read from the Tracker (after the same normalising) is not an update: it makes no write and is not listed as updated in the change summary.

   An item is **not started** when its status is in `status-todo`, and **started** otherwise (In Progress, Done, or a status in no bucket). A started item is never redrafted or rewritten.

   | The spec… | Not started | Started |
   |---|---|---|
   | did not change it | nothing | nothing |
   | changed a Story's sentence | **update**: new sentence, redrafted title and criteria | **held**: comment the sentence change |
   | changed an Epic's name | **update**: the summary | **held**: comment the name change |
   | changed an Epic's membership | **update**: redrafted slice | nothing |
   | moved the Story to another Epic | **re-parent** | **held**: comment the move |

   A removed item is **held** whatever its status, with a "removed from spec" comment. It is never deleted, closed or transitioned, and its key table row stays.
5. **Comments are written once.** One comment per item. A comment holds only approved spec text, never Acceptance Criteria or other drafted text. Each starts with a fixed first line:
   - held (changed, moved, or both): first line `Spec change not applied (item started)`. Then one fenced code block (so Jira keeps the `+`/`-` markers and does not turn URLs into links) holding only what changed: for a sentence, `- <old sentence>` and `+ <new sentence>`; for an Epic's name, `Name: <old> → <new>`; for a move, `Epic: <old key> → <new key> (<name>)`. After a sentence change, one plain line may follow: `Acceptance Criteria on this item were not updated; review them against the new sentence.` Then `Spec Page: <page URL>`.
   - removed: first line `Removed from spec`. Then `This item is no longer in the spec. It was not deleted or closed. Spec Page: <page URL>`

   Read the item's comments with `listJiraIssueComments`. A held comment is already there when one has the same first line and the same lines in its code block: compare each `-`/`+` line's marker as is and the sentence after it as normalised text (step 4; the marker is never stripped as a list marker), and each `Name:` or `Epic:` line normalised. A removed comment is already there when one has the first line `Removed from spec`, whatever follows. Then add no new one. The item is still held.
6. **Change summary.** Show the user a table of what would be created, updated, re-parented, held (with the reason) and removed from spec, after each step 3 candidate pair with the user's answer. If there is nothing to write (no create, update, re-parent or new comment, and the page body and key table read in step 1 already match step 8), say the Tracker is already up to date, make no write, and go to step 9. Otherwise ask the user to go ahead, and wait. If they name an item to redraft (step 4), redraft it, show the summary again and wait. If they decline, write nothing (no comment either) and go to step 9: every item the summary would have written is **declined**, not held.
7. **Write**, one call at a time, parents first: Epics in outline order, then Stories in outline order, then removed items.
   - new: create it as steps 5 and 6 do. A Story's parent is its Epic's key, new or recorded.
   - update: `editJiraIssue` with `fields` `summary` and `description`, and `contentFormat` `markdown`.
   - re-parent: `editJiraIssue` with `fields` `parent` set to the new Epic's key (in the same call as an update, when both apply).
   - held: `addOrEditJiraIssueComment` with the step 5 text, Markdown, and no `commentId`, unless step 5 skipped it.

   Never call a transition, and never delete.
8. **Spec Page.** Start the body from what step 1 read. Change a shared-context section only when the user changed that shared context in this session; then it becomes that section as the user approved it in this session's draft. Otherwise keep the body exactly as read. A `## Plan` section is not shared context: keep it exactly as read, in its place after the shared context and before the key table. Key table rows: the Spec Page; the Epics, then the Stories, in outline order, each with its new outline id, its Work Ref (recorded or new) and its title (the title as read, or the new or redrafted title); then each removed item, with outline id `—` and its title as read; then the kept rows of other kinds, unchanged. Every recorded row stays, and no Work Ref changes. If the body or the key table differs from what step 1 read after normalising, `updateConfluenceContent` as the last call: the Spec Page body followed by the key table.
9. **Return** the map (every key table row), `held` (each item left untouched by the started-item or removed rule, with its reason, whose comment was written or was already there) and `declined` (each item the user declined in step 6; empty otherwise). Tell the user what was created, updated and re-parented, and each held item with its reason. If they declined, tell them nothing was written and list the declined items.

A failed call is handled as in "A call fails after step 1" above.

### Plan publish

Implements `publish` for plan's outline: the Plan section and the Sub-tasks. The outline always names the Spec Page's Work Ref and the ledger's rows. Plan publish never creates the Spec Page, never writes an Epic or Story, and never changes the page's shared context. A Sub-task's Work Ref is its issue key. Never pass a Sprint, backlog, priority, story-point or estimate field. Never call a transition, and never delete.

Read first, then (on a re-run) get one go-ahead, then write. Make no write before the go-ahead. **Every question to the user happens before the first write**: the candidate pairs (step 3), the link direction (once step 4 has classified the items, or right after step 2 on a first plan publish) and the go-ahead (step 6). Once the first write is made, ask nothing more.

1. **Reach Jira** and **format**, as steps 1 and 2 above. If Jira can't be reached, stop and write nothing: tell the user the plan was not published.
2. **Recorded items**, as Re-run step 1: `getConfluenceContent` on the Spec Page, its key table, plus the ledger's rows the table lacks. A Story the outline names as a parent is the recorded Story row with that outline id; its key is the parent.

   Read each recorded Sub-task with `getJiraIssue` (`view: full`, Markdown): its summary, description, status, parent and issue links.
   - Its **blocked-by set**: the recorded Sub-tasks joined to it by a `link-blocks` link in which it is the blocked side (the side the type's inward text, such as "is blocked by", describes).
   - Its **relates set**: the recorded Stories joined to it by a `link-relates` link.
   - Links to items not recorded for this spec are ignored, never compared or removed.

   **Link direction.** Run it once, after the items are matched and classified (step 4; on a first plan publish, right after this step) and before the first write, and only if a `blocks` link will actually be created this run: confirm the link direction as [Links](#links) steps 1–3 say. `relates` links have no direction, and an unchanged re-run writes no links, so neither triggers it. On a re-run, ask it before the change summary. If it can't be determined and the user does not answer, stop and write nothing: tell the user the plan was not published.

   **No Sub-task recorded** means a first plan publish: every outline Sub-task is new. Skip steps 3–6, run the link direction check above, and go to step 7.
3. **Pair** each outline Sub-task with a recorded Sub-task exactly as Re-run step 3 pairs Stories: first the same title (normalised) against the summary, then the same outline id among Sub-task rows, then **ask, never guess** for every remaining candidate pair ("same as <Work Ref>" or "new"). A Sub-task only ever pairs with a Sub-task. A row already marked removed from plan (outline id `—`) is never offered again.
4. **Decide** each paired Sub-task, as Re-run step 4 decides Stories, with the approved plan in place of the approved spec.
   - **Only user-approved plan content is compared.** Both tiers compare its title, parent Story, blocked-by set and relates-to set:
     - its title against the summary
     - its Story against the parent
     - its blocked-by set and relates-to set against the sets read

     The Small tier also compares its approved step list (the plan's `- [ ]` step lines) against the description's `- [ ]` lines. The Large tier compares nothing more: its description is drafted text, kept verbatim.

     Normalise as Re-run step 4. A ticked `[x]` box equals `[ ]`.
   - **Drafted text is kept verbatim as read.** A Large-tier description is drafted by the agent: it is redrafted only on a not-started Sub-task whose title, Story or blocked-by set changed, or that the user names at the go-ahead. Its `Blocked by:` line then names the new blockers. So a not-started Sub-task that gains a blocker is an **update** (the redrafted `Blocked by:` line) as well as a **link**, and the change summary lists both. A Small-tier description is the approved task itself: when the title or step list changed, the new description is the task as approved now. A redraft or new description equal to the text read (after normalising) is no update.

   | The plan… | Not started | Started |
   |---|---|---|
   | did not change it | nothing | nothing |
   | changed its title (Small tier: or its steps) | **update**: summary and description | **held**: comment the change |
   | moved it to another Story | **re-parent** | **held**: comment the move |
   | added a blocker or relates-to Story | **link**: add the link (a blocker, Large tier: also **update**, the `Blocked by:` line) | **held**: comment the change; no link |
   | dropped a blocker or relates-to Story | **held**: the link stays; comment it | **held**: comment the change |

   A recorded Sub-task no longer in the plan is **held** whatever its status, with a "removed from plan" comment. It is never deleted, closed or transitioned, and its key table row stays.
5. **Comments are written once**, as Re-run step 5 for the layout and for a Story or Epic; a Sub-task's repeat is decided by the rule below, not by comparing text. One per item, holding only approved plan text. First lines:
   - held (changed, moved, or a link it could not add or remove): `Plan change not applied (item started)`, or `Plan change not applied (links are never deleted)` when the item is not started and only a dropped link is kept. Then one fenced code block holding only what changed: `- <old title>` and `+ <new title>`; Small tier, `- <step>` for each step removed and `+ <step>` for each step added; `Story: <old key> → <new key>`; `Blocked by: <old keys> → <new keys>`; `Relates to: <old keys> → <new keys>`. Then `Spec Page: <page URL>`.
   - removed: `Removed from plan`. Then `This item is no longer in the plan. It was not deleted or closed. Spec Page: <page URL>`

   **A held change is not re-commented.** A re-plan starts from the plan as read from Jira (the Plan section, and each Sub-task's summary, description and links) and carries only the changes the user asked for in this session, so a held item's change is never in what step 2 read. For a started Sub-task, compare the change the outline carries with the code-block lines of each existing `Plan change not applied (item started)` comment, normalised. If one holds the same change, add no comment and make no write: the item stays `held`. The **same change** means the same title, the same parent Story, the same blocked-by and relates-to edges added or removed, and for steps the same command(s) and expected result, whatever the wording. If this session asks for the earlier-commented change plus a new one, write one new comment holding only the new part. If the user asked for a different change, add one new comment holding only that change. If the outline carries no change for it (the user did not ask again this session), write and comment nothing for it.
6. **Change summary**, as Re-run step 6, listing also each link to add and whether the Plan section changes. If there is nothing to write, say the Tracker is already up to date, make no write, and go to step 9. Otherwise wait for the go-ahead; on a decline, write nothing and list the declined items.
7. **Write**, one call at a time:
   1. Sub-tasks in outline order (blockers first):
      - new: `createJiraIssue`: project `project`, issue type `type-subtask`, `parent` its Story's key, `summary` its title, `contentFormat` `markdown`, `description` as below.
      - update or re-parent: `editJiraIssue` as Re-run step 7.
      - held: `addOrEditJiraIssueComment` with the step 5 text and no `commentId`, unless step 5 found it already there.
   2. Removed Sub-tasks: their comment.
   3. [Links](#links), after every Sub-task exists, in the direction confirmed in the read phase, before any write: each missing `blocks` edge, in outline order of the blocked Sub-task, then each missing `relates` edge.
   4. The Spec Page (step 8), last.

   **Description**, Markdown:
   - Large tier: the ticket's What to build; `## Acceptance criteria` with one `- [ ]` line per criterion; `Blocked by: <the blockers' titles, comma-separated>`, or `Blocked by: None (can start immediately)`; `Spec Page: <page URL>`. No file paths.
   - Small tier: the task's Files, Interfaces and `- [ ]` steps with their commands, exactly as in the approved plan; then `Spec Page: <page URL>`.
8. **Spec Page.** Start from the body step 2 read, and keep its shared context exactly as read.
   - **Plan section**: `## Plan`, after the shared context and before the key table.
     - Small tier: `**Goal:**`, `**Architecture:**` and `**Tech Stack:**` lines, then `### Global Constraints` and `### Review Focus`, as in the approved plan header.
     - Large tier: a table `| ticket | title | Blocked by |`, one row per ticket in outline order (`None` when nothing blocks it).

     If the page already has a `## Plan` section equal to this after normalising, keep it exactly as read. Otherwise write this one in its place.
   - **Key table**: every row read for the Spec Page, Epics and Stories, unchanged; then the Sub-tasks in outline order (`<outline id> | Sub-task | <key> | <title>`, a held Sub-task with its title as read); then each removed Sub-task with outline id `—` and its title as read. Every recorded row stays, and no Work Ref changes.

   If the body or the key table differs from what step 2 read after normalising, `updateConfluenceContent` as the last call: the body (shared context, then Plan section) followed by the key table.
9. **Return** the map (every key table row), `held` and `declined`, as Re-run step 9. Tell the user the Sub-tasks created (keys and parent Stories), updated and re-parented, the links added, each held item with its reason, and whether the Plan section was written.

**A call fails.** As "A call fails after step 1": stop at once, with no retry, no further link and no Spec Page update. Tell the user the plan is only partly published, with a table of what was created (outline id, kind, Work Ref) and a list of what was not (Sub-tasks, links, the Plan section and the key table rows). Return the created Sub-tasks and every recorded item as the map. A re-run finds the created ones through the ledger and pairs them, so nothing is created twice.

### Links

The link types are `link-blocks` and `link-relates` from the `## Tracker` section. A "blocks" link puts the blocker on the side the type's **outward** text describes ("blocks") and the blocked Sub-task on the side its **inward** text describes ("is blocked by"). Direction is easy to get backwards, and this adapter can't delete a wrong link, so confirm it in the read phase ([Plan publish](#plan-publish) step 2), before any write:

1. Call `listJiraIssueLinkTypes` and read the inward and outward text of `link-blocks`.
2. Read `createJiraIssueLink`'s live input schema for which issue parameter the outward text describes. Pass the blocker there and the blocked Sub-task in the other.
3. If the listing and the schema do not settle it, ask the user which parameter takes the issue that "blocks", and wait, before any write. If they do not answer, write nothing.

A `relates` link joins a flagged Sub-task to each other Story it spans; either side will do. Never pass a `comment` with a link.

## pull

Implements [`pull(scope, level)`](tracker.md#pullscope-level).

### `outline`

`scope` is a spec: its Spec Page's Work Ref (the page URL). Reads only, apart from [Replay](#replay).

1. **Reach Jira.** Call `atlassianUserInfo`. If it fails, stop: tell the user Jira can't be reached, so nothing was read, and that `/mcp` reconnects the Rovo MCP server. Then [Replay](#replay) the queue before reading.
2. **Spec Page.** `getConfluenceContent` on the page, with a Markdown body. If there is no such page, stop and report the unknown Work Ref (not an unreachable Tracker): tell the user to check the Work Ref and the ledger's first line. The body holds the shared context, then the `## Plan` section if plan ran, then the `## Work Refs` key table.
3. **Recorded items.** The key table's rows, plus the rows of the ledger whose first line names this Spec Page (`.power-architect/<spec-slug>/progress.md` under the ledger root, see [tracker.md](tracker.md#recordref-event-evidence)) that the table lacks, as publish's Re-run step 1.
4. **Read** each recorded Epic, Story and Sub-task with `getJiraIssue` (`view: full`, Markdown): summary, description, status, parent and issue links.
5. **Return** the Work Outline:
   - the Scope Tier, from the page's Scope Tier section
   - the Spec Page: its Work Ref, title, shared context and Plan section
   - each item with its outline id, kind, Work Ref, summary, description, status and parent. A Story's Acceptance Criteria are the `- [ ]` lines under its `## Acceptance Criteria`. A Sub-task also has its blocked-by and relates sets, as [Plan publish](#plan-publish) step 2 defines them. An item with outline id `—` comes back marked removed.

### `story`

`scope` is a spec: its Spec Page's Work Ref. Reads only, apart from [Replay](#replay).

1. Run `outline` steps 1 to 4: reach Jira, [replay](#replay), read the Spec Page, the recorded items and each Epic, Story and Sub-task. A stop there stops this `pull`, with the same message.
2. **Keep** each Story (a `type-story` row not marked removed) whose status is not in `status-done`, in key table order. Never return a Bug or an Epic.
3. **Sub-tasks.** For each Story, its Sub-tasks are the recorded Sub-task rows (not marked removed from plan) whose parent is that Story. Note each one's status, and list those whose status is not in `status-done` as unfinished. A Story with no such Sub-task is flagged `no Sub-tasks planned`: it is not verifiable.
4. **Return** each Story with its Work Ref (key), title (summary), description, Acceptance Criteria (the `- [ ]` lines under its `## Acceptance Criteria`, text only), status, whether all its Sub-tasks are Done, and its unfinished Sub-tasks (key and status).

### `subtask`

`scope` is `sprint`, or a Work Ref: a Sub-task's, a Bug's or a Story's key. Reads only, apart from [Replay](#replay).

1. **Reach Jira** and [replay](#replay) the queue, as for `outline`. If either stops, stop: tell the user Jira can't be reached, so nothing was read and nothing should be built, and that `/mcp` reconnects the Rovo MCP server.
2. **Candidates.**
   - `sprint`: `getJiraBoardSprintData` with `boardId` the `board` value, with its issues. It reads the active Sprint by default: never pass a `sprintId` or `sprintName`. If `discover` does not find the tool, use `searchJiraIssuesUsingJql` with `project = <project> AND sprint in openSprints() AND issuetype in ("<type-subtask>", "<type-bug>")` (that this JQL works through Rovo is unverified). If there is no active Sprint, stop: tell the user there is no active Sprint to build, and that the Product Owner starts one in Jira. Keep the issues of type `type-subtask` or `type-bug`.
   - A Work Ref: `getJiraIssue` on it. If there is no such issue, stop and report the unknown Work Ref (not an unreachable Tracker): tell the user to check the Work Ref and the ledger's first line. A `type-subtask` or `type-bug` issue is the only candidate. For a `type-story` issue, the candidates are its Sub-tasks: `searchJiraIssuesUsingJql` with `parent = <key>`. For any other type, stop and tell the user build takes a Sub-task, a Bug or a Story.
3. **Drop** each candidate whose status is in `status-done`.
4. **Read** each remaining candidate with `getJiraIssue` (`view: full`, Markdown): summary, description, status, parent and issue links. Its **blockers** are the issues joined to it by a `link-blocks` link in which it is the blocked side, as [Plan publish](#plan-publish) step 2 defines it. Read each blocker that is not a candidate with `getJiraIssue`, for its status.
5. **Spec.** A `type-bug` candidate has no spec, Story, tier or blockers: skip this step and step 6's ordering for it. A candidate's spec is the page its description's `Spec Page: <URL>` line names; that URL is the Spec Page's Work Ref. Read each distinct Spec Page once with `getConfluenceContent` (Markdown): its Scope Tier section gives the tier, and its key table gives each Sub-task's outline id. A candidate with no `Spec Page:` line, or listed neither in its page's key table nor in that spec's ledger `## Work Refs` rows, is not built: put it in `blocked` as "not from a published spec".
6. **Order** the Sub-tasks blockers first. Break ties by key table order, then by spec in the order their items were first read. Then walk the list. A candidate is **ready** when each blocker's status is in `status-done`, or the blocker is a ready candidate earlier in the list. Otherwise move it to `blocked`: "blocked by <key> outside scope" when that blocker is not a candidate, or "blocked by <key>" when it is a candidate that is not ready. A Bug is always ready and goes after every Sub-task, in the order the Sprint listed them.
7. **Return** the ready list, Sub-tasks first, then Bugs, and the `blocked` list. Each Sub-task comes with its Work Ref (key), title (summary), description, status, Story (parent key), Spec Page Work Ref, Scope Tier, and blockers with their status. A Bug comes with only its key, title, description and status: no Story, Spec Page, tier or blockers.

## record

Implements [`record(ref?, event, evidence)`](tracker.md#recordref-event-evidence) for `started`, `done` (a Sub-task, a Bug or a Story), [`shipped`](#shipped) and [`defect`](#defect). One call at a time, passing `cloudId` on each. Never set a resolution, assignee, estimate, or any Sprint, board or backlog field. Never touch a Sprint.

1. **Read** the item with `getJiraIssue`: its status and issue type. `shipped` has no single item: go to [`shipped`](#shipped).
2. **`started`.** If the status is in `status-in-progress` or `status-done`, do nothing (no transition, no comment) and return `ok`. Otherwise [move](#moving-an-item) it to the first status of `status-in-progress`.
3. **`done`** (Sub-task or Bug only; a Story's is below), in this order. A Done item is never pulled again, so a crash between the two steps must leave the comment written and the move still to do:
   1. **Comment.** The evidence comment is exactly this, with the commit lines and the `tests:` line both inside the one fenced block:
      ````
      Done
      ```
      <short SHA> <subject>        (one line per commit, or one line `PR: <URL>`)
      tests: <command> → <result>
      ```
      ````
      Read the item's comments with `listJiraIssueComments`. The comment is already there when one has the first line `Done` and a body containing every evidence commit SHA (or the PR URL) and the `tests:` line (command and result), compared as normalised text (publish [Re-run](#re-run) step 4) wherever those lines sit, inside or outside the fence. Then add none. Otherwise `addOrEditJiraIssueComment` with it, Markdown, and no `commentId`.
   2. **Move** it to the first status of `status-done`, unless its status is already in `status-done`.
4. **Return** `ok`.

**`done` on a Story** (`type-story`; verify's evidence is one line per Acceptance Criterion, `<criterion text> — <command> → <result>`). If its status is in `status-done`, do nothing (no comment, no move) and return `ok`. Otherwise, in this order:
   1. **Comment.** The comment is exactly this, with one `✅` line per evidence line inside the one fenced block. The first line is `Verified`, never `Done`:
      ````
      Verified
      ```
      ✅ <criterion text> — <command> → <result>
      ```
      ````
      Read the item's comments with `listJiraIssueComments`. The comment is already there when one has the first line `Verified` and, for every Acceptance Criterion of the Story (taken from the Story description as read), its criterion text (the part before ` — `), compared as normalised text (publish [Re-run](#re-run) step 4) wherever those lines sit, inside or outside the fence. The command and result are not compared: a new session picks them again. Then add none. Otherwise `addOrEditJiraIssueComment` with it, Markdown, and no `commentId`.
   2. **Move** it to the first status of `status-done`.

   Never touch its Sub-tasks, its Epic or a Sprint, and never set a resolution or an assignee.

### `shipped`

`ref` is the Spec Page's Work Ref and `evidence` is `<link> base <sha>`: the PR URL or merge commit link with the base SHA (the merge-base of the branch with the base branch, captured before the merge or push). It comments the link on each Story this branch delivered, and changes no status.
1. **Delivered Sub-tasks**, from the ledger and git only (no Jira call). Take the spec's ledger (`.power-architect/<spec-slug>/progress.md` under the ledger root, whose first line names the Spec Page). Its `Task <Sub-task ref>: complete (commits a..b, …)` lines whose last commit `b` lies in the range `<sha>..<branch>`, where `<sha>` is the `base` SHA carried in `evidence`, never the base branch name (`git merge-base --is-ancestor b <branch>` and not `git merge-base --is-ancestor b <sha>`) are the delivered Sub-tasks. A commit already on the base branch does not count. Append the ledger line `Shipped: <link> — base <sha> — Sub-tasks <ref>, <ref>` (unless one with the same link is there). With no delivered Sub-task, return `ok` and write nothing.
2. **Stories.** Read each delivered Sub-task with `getJiraIssue`: its parent is a delivered Story. Ignore a parent that is not a `type-story`. Comment nothing on a Bug, an Epic, a Sub-task or a Story with no delivered Sub-task.
3. **Comment** each delivered Story, never repeating one. The comment is exactly the first line `Shipped`, then the link on its own line, as plain Markdown. Read the Story's comments with `listJiraIssueComments`: it is already there when one has the first line `Shipped` and the link, compared as normalised text. Then add none. Otherwise `addOrEditJiraIssueComment`, no `commentId`.
4. Never call a transition. Return `ok`.

### `defect`

`ref` is an item's key, or absent. `evidence` is the labelled lines the phase gives. Never set a priority, estimate, assignee, or any Sprint, board or backlog field, and never touch a Sprint.

- **With a `ref`.** The comment is exactly this, with the evidence lines inside the one fenced block:
  ````
  Defect fixed in this item
  ```
  <evidence lines, one per line>
  ```
  ````
  Read the item's comments with `listJiraIssueComments`. The comment is already there when one has the first line `Defect fixed in this item` and the same evidence lines, compared as normalised text (publish [Re-run](#re-run) step 4). Then add none. Otherwise `addOrEditJiraIssueComment`, Markdown, no `commentId`. Never create a Bug.
- **Without a `ref`.** The symptom line is the `symptom:` evidence line.
  1. **Look for the same defect, before any write.** Search the open Bugs on the symptom's key terms: `searchJiraIssuesUsingJql` with `project = <project> AND issuetype = "<type-bug>" AND statusCategory != Done AND text ~ "<key terms of the symptom>"` (that this JQL works through Rovo is unverified; if the search tool or the JQL fails, read the project's open Bugs and compare them instead). Read each candidate with `getJiraIssue`. A candidate is **the same defect** when it has the same symptom AND the same proven root cause, whatever its wording. Decide this before any write. If you are unsure, ask the user before writing. If one is the same defect, add one comment to it, `Defect seen again` then a fenced block of the evidence lines, unless it already holds the same one (compared as above), and return `ok`. Create nothing.
  2. **Otherwise create the Bug.** `createJiraIssue`: project `project`, issue type `type-bug`, `summary` the plain one-line symptom (the text of the `symptom:` line, without the `symptom:` label), `contentFormat` `markdown`, `description`: `Symptom: …`, `Repro: …`, `Root cause: …`, then the line `Found while working on <the working-on ref>` (or `Found while working on no tracked item` when it is `none`). No `parent`, no priority, assignee or estimate, and no Sprint, board or backlog parameter: the Bug lands in the Backlog.

### Moving an item

`listJiraIssueTransitions` on the item. Pick the transition whose target status is the wanted status. If none leads there, pick one that leads to another status of the same bucket. Call `transitionJiraIssue` with only the item and that transition's id. If no transition leads into the bucket, stop: tell the user which item could not be moved to which status, and recommend checking the status mapping with `/power-architect:setup-tracker jira`.

### Jira unreachable during `record`

Queue, never stop (the [queue rules](tracker.md#recordref-event-evidence) apply).
**A `defect` with no `ref`** has no item to queue behind and may have no spec ledger: queue it in the bugs ledger `<ledger root>/.power-architect/bugs/progress.md` (create it with first line `# Ledger — bugs` if missing) as `- [ ] q<N> | defect | - | <evidence verbatim>`, escaped as below, then return `queued`. Its [replay](#replay) repeats the open-Bug search of [`defect`](#defect) step 1 first, then comments on the same defect or creates the Bug, so it never creates a second Bug. Steps 2, 3 and 4 below apply. An entry with ref `-` never blocks and is never blocked by another entry: each no-ref defect is independent, so an unsent or `[!]` no-ref defect does not hold back a later one, and replay repeats the open-Bug search for each.
1. **Behind an entry.** If the item has an unsent entry (`[ ]` or `[!]`) in any ledger's `## Tracker queue`, queue this event without calling Jira.
2. **Unreachable.** If a Rovo call fails because Jira can't be reached, at any step, queue the whole event, even if an earlier step wrote something (replay does not repeat it: a status already in the target bucket is not moved again, and a `Done`, `Verified` or `Shipped` comment already there is not added again). A refusal that is not "unreachable" (such as no transition into the wanted status) is not queued: [Moving an item](#moving-an-item) stops (during replay, the entry becomes `[!]`).
3. **Queue** it (for `shipped`, step 1 of [`shipped`](#shipped) is done first, because it needs no Jira call): append `- [ ] q<N> | <event> | <ref> | <evidence on one line>` to the ledger's `## Tracker queue` (create the section if missing), then return `queued`. Escape the evidence as the [queue rules](tracker.md#recordref-event-evidence) say (`\` as `\\`, a literal ` | ` as ` \| `, newlines as `\n`). The ledger is the main checkout's, whichever worktree the agent is in. If a ledger is lost, its unsent events are lost: the item then shows as unfinished in the Tracker and a resume rebuilds it. A queued `shipped` is lost for good (nothing rebuilds it): tell the user to post the link on the Stories by hand. So a build never deletes the main checkout's `.power-architect/`. For `done`, `<evidence>` is the commit lines and the `tests:` line (a Story's: its criterion lines), not the comment. For `shipped`, `<ref>` is the Spec Page's Work Ref and `<evidence>` is `<link> base <sha>`.
4. The phase carries on. Say, at the end of the phase, which items' events are queued.

### Replay

First step of every `pull`, after step 1 (Reach Jira) and before anything is read.
1. Collect the `- [ ]` entries of every ledger under the main checkout's `.power-architect/` (never a linked worktree's): ledgers in directory-name order, each in `q` order.
2. Apply each as `record` does for its event, with the stored evidence (`done` writes the Done comment from the evidence, a Story's the Verified comment; `shipped` reads its delivered Sub-tasks from the ledger's `Shipped:` line for that link and derives nothing, base included), skipping an entry whose item has an earlier `- [!]` entry (an entry with ref `-` is never skipped for this reason). Mark it `- [x]` on success.
3. If a call fails because Jira can't be reached, stop replaying and stop the `pull` as its Reach Jira step does: read nothing; the rest stay `- [ ]`.
4. If it fails for any other reason, mark it `- [!] … | failed: <reason>`, tell the user, and go on to the next entry. Say in that message how to clear it: after the cause is fixed, change the entry's marker to `- [ ]` to retry it, or to `- [x]` if it was applied by hand.
5. Then carry on with the `pull`'s read.
