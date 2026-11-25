# 48: With no `## Tracker` section, a to-spec re-run rewrites the spec file as today and never reads the Tracker files

**Phase:** /power-architect:to-spec

## Given
- Repo instructions file (AGENTS.md): exists, with no `## Tracker` section
- Tracker state: none
- Ledger / local files:
  - Today is 2026-11-24. The feature's slug is `team-invites`. There are no ADRs. `GLOSSARY.md` exists. There is no `.power-architect/` directory.
  - `docs/specs/2026-11-24-team-invites.md` exists from an earlier to-spec run today: spec "Team invites", Scope Tier Large, user stories 1–4: 1. As an org admin, I want to invite a teammate by email, so that they can join my organization. 2. As an invitee, I want to accept an invite from the email link, so that I join the organization. 3. As an org admin, I want to remove a member, so that ex-employees lose access. 4. As a member, I want to leave an organization, so that I stop seeing its work.
  - Conversation so far: the user re-ran `/power-architect:grill`, which dropped user story 4, and now re-runs to-spec. The settled test seam is the public HTTP API.

## When
The user runs `/power-architect:to-spec` and replies in order:
1. confirms the proposed test seam;
2. accepts the Large tier;
3. to any builder-check questions: "your call on all of them";
4. at the spec gate: "approved".

## Then
- The agent checks for a `## Tracker` section, finds none, and uses Local Files
- The agent never opens `references/tracker.md` or any `references/tracker-*.md`
- The spec is written to `docs/specs/2026-11-24-team-invites.md` using the spec template, with user stories 1–3 and the Scope Tier Large
- The agent asks the user to approve the spec, with no Epic grouping table, no question about Epics, and no change summary of created / updated / held items
- No Tracker operation (publish / pull / record) is attempted, and no MCP call is made
- Nothing is written under `.power-architect/` (no `spec-draft.md`, no ledger)
- After approval, the agent recommends `/power-architect:plan`
