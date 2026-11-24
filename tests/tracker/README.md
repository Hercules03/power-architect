# Tracker scenarios

The skill is Markdown, so its tests are **dry runs**. A fresh subagent plays an agent running one phase against a fixed starting state. It writes out what it would do. A reviewer compares that trace with the scenario's **Then**. These scenarios prove the Tracker contract (`skills/power-architect/references/tracker.md`) and each Tracker Adapter.

These files live outside `skills/`, so they are never installed with the skill.

## Scenario format

One file per scenario, `NN-short-name.md`:

```md
# NN: <behaviour in one line>

**Phase:** /power-architect:<phase> [args]

## Given
- Repo instructions file (AGENTS.md or CLAUDE.md): <its `## Tracker` section verbatim, or "no `## Tracker` section">
- Tracker state: <"none", or a stubbed Rovo table (see below)>
- Ledger / local files: <anything else the phase would find>

## When
<the user action, e.g. "the user runs the phase and approves the gate">

## Then
- <ordered, checkable expectations: files read or written, Tracker operations with their results, MCP calls made, and what the agent tells the user>
- <explicit negatives, e.g. "never reads tracker-jira.md", "no Sprint operation">
```

## Stubbed Rovo table format

Stands in for the Atlassian Rovo MCP server. Each row is a tool the adapter may call and the response the stub returns. Any tool not listed returns `error: not stubbed`, and the dry run reports that.

```md
| Tool | Called with (match) | Returns |
|---|---|---|
| getVisibleJiraProjects | any | [{key: "PA", name: "Power Architect"}] |
| createJiraIssue | issueType=Story | {key: "PA-<n>"} (n increments from 10) |
| * | any | UNREACHABLE |
```

`UNREACHABLE` simulates Jira being down, for that tool or (with `*`) for every tool.

## Running a scenario (dry run)

Dispatch a fresh general-purpose subagent with this prompt, filling in the scenario path:

```
You are dry-running the power-architect skill at <repo>/skills/power-architect.
Read the scenario at <scenario path>. Act as an agent who has just been asked to
run its **Phase**, following the skill's files exactly (start at SKILL.md and
open only what the files tell you to open). Treat its **Given** as the complete
state of the world: the repo instructions file, Tracker, ledger and files are
exactly as described. Make no real tool calls, file edits or MCP calls. For every
MCP tool you would call, use the stubbed Rovo table's response.

If the scenario's **When** gives the user's replies, use them in order and carry
on. Stop at the first question the When does not answer, or when the phase ends.
Report the trace as an ordered list:
- each skill file you opened, in order
- each Tracker operation (publish / pull / record) with its arguments and result
- each MCP call with its arguments and stubbed result
- each file you would write, with a one-line summary
- what you would say to the user
Do not read the scenario's **Then** as instructions. Report only what the skill
files led you to do.
```

The reviewer marks each **Then** line ✅ or ❌, quoting the trace line that shows it. A scenario passes only if every line is ✅.

## Locality check

The Tracker contract and every phase file must stay tracker-neutral. Only a Tracker Adapter may name its tracker's tools or formats. Run from the repo root:

```sh
grep -rniE 'jira|rovo|mcp__|atlassian|confluence|\bADF\b' skills/ \
  | grep -v 'skills/power-architect/references/tracker-jira.md'
```

**Pass:** no output. Any line printed names a tracker detail outside its adapter.
