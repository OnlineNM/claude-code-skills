---
name: ppc:update
description: >
  Update an existing Paperclip agent's AGENTS.md system prompt and/or hire config.
  Use when the user calls /ppc:update, wants to modify, revise, improve, extend, or change
  an existing agent's instructions, role charter, working rules, escalation triggers, domain
  lenses, collaboration routes, output bar, safety section, done criteria, or any hire config
  field (adapter type, models, icon, heartbeat, budget). Accepts the current AGENTS.md as a
  file path or pasted inline. The update description can be in Romanian or English.
  Interviews the user only to clarify ambiguous changes. Always writes AGENTS.md in English.
---

# Paperclip Agent Update (`/ppc:update`)

Applies targeted edits to an existing Paperclip agent definition. The user provides the
current AGENTS.md and describes what to change. Read the file, interpret the request, ask
only what's genuinely unclear, confirm the plan, then write.

## Language Rule

Detect the language of the `/ppc:update` prompt:
- Romanian → conduct interview questions and status messages in Romanian
- English (or ambiguous) → use English
- **Always write AGENTS.md in English, regardless of prompt language**

---

## Phase 1 — Parse Inputs

Extract from the user's prompt:
- **File**: path to AGENTS.md, or inline content if pasted directly
- **Changes**: what the user wants to update
- **Output path**: where to write the result (default: overwrite the original)

If the file was pasted inline, ask for the desired save path before writing.
If neither a path nor inline content is provided, ask for it before continuing.

Read (or use) the AGENTS.md and inventory:
- Agent identity: name, company, reporting line
- Sections present: which `##` sections exist and which are missing per the Paperclip baseline
- Config hints: any adapter/model/heartbeat values referenced in the file or prompt

Do not flag missing sections to the user unless they asked to add something — a gap analysis
is for your own reference to avoid creating duplicate sections, not a to-do list to impose.

---

## Phase 2 — Clarify (only when necessary)

Ask only when the request cannot be resolved from the prompt and the file:

| Situation | What to ask |
|---|---|
| Change description is vague ("make it better", "improve it", "make it more thorough", "enhance it", "expand it") | Which section? What specifically should change? |
| A change could apply to multiple sections | "Should this apply to § Role only, or also § Working rules / § Escalation?" |
| New content is required that wasn't provided | "What should the new [lenses / routes / rules] say?" |
| User asks to remove a mandatory element | Explain the constraint; offer to update that section's *content* instead |
| Config field change needs a value not given | "What model should replace the current one?" |

**Hard rule — STOP and ask before writing if the request:**
- uses a quality adjective without naming a section ("better", "more thorough", "improved", "stronger", "cleaner")
- says "improve", "enhance", "expand", "update", or "revise" without specifying what to change
- is shorter than one concrete action (e.g., "fix it", "update the agent")

A vague request answered without clarification produces a rewrite the user didn't ask for. When in doubt, ask — one question is cheaper than a wrong rewrite.

Batch multiple questions into one message. Never ask about something already in the file or prompt.

---

## Phase 3 — Change Plan

Before writing anything, show a concise plan in the prompt language:

> **What will change:**
> - § Role — replace charter to include technical documentation ownership
> - § Collaboration and handoffs — add (currently missing)
>
> **What stays untouched:**
> - § Working rules, § Escalation, § Safety, § Done
> - Hire config (no adapter/model changes requested)
>
> Ready to apply?

If config fields also change, include them:
> - Hire config: `adapterConfig.model` → `claude-opus-4-8`

Wait for confirmation before writing.

---

## Phase 4 — Apply Changes

### Surgical editing rules

Touch only what was explicitly requested. Do not paraphrase, clean up, or "improve"
sections that weren't mentioned — a reader should be unable to identify edited sections
without a diff. The user's trust in this skill depends on it not quietly changing things.

### Immutable lines — never remove, always preserve verbatim

If the user asks to remove one, explain it is a Paperclip architectural requirement
and offer to modify the surrounding section's *content* instead:

```
You are agent <name> (<Job Title>) at <Company Name>.
When you wake up, follow the Paperclip skill. It contains the full heartbeat procedure.
You report to <reporting line>.
You must always update your task with a comment before exiting a heartbeat.
```

### Immutable constraints inside § Working rules

Even when updating this section, preserve these two constraints (they encode fixed
Paperclip architecture, not agent preference):
- "Do not create sub-agents and do not delegate work directly to peer agents."
- "delegation decisions belong to the manager"

### Adding a new section

When adding a section that doesn't currently exist, insert it in canonical position:

1. Role
2. Working rules
3. Escalation
4. Domain lenses *(if present)*
5. Output bar *(if present)*
6. Collaboration and handoffs *(if present)*
7. Safety and permissions
8. Done
9. *(closing line)*

### Language enforcement

AGENTS.md is always in English. If the user asks to update a section that happens to be
in another language, translate that section to English as part of the edit. Leave untouched
sections as-is — do not translate sections that weren't asked about.

---

## Phase 5 — Config Changes (only when triggered)

When the update affects a hire config field (adapter type, model, icon, heartbeat, budget,
desiredSkills) but NOT any AGENTS.md section content, **do not write to or modify any file**.
Do NOT claim to have updated or modified any file — no file was changed.
Output only the changed fields as a JSON snippet — the user merges this into their hire config:

```json
{
  "adapterConfig": {
    "model": "claude-opus-4-8"
  }
}
```

Always tell the user all three of the following:
- **No file was modified.** The snippet above is all that changes.
- Merge these into the full hire config and submit to `PATCH /api/agents/:agentId`
  or include in a fresh `POST /api/companies/:companyId/agent-hires`
- **`cheapModel` may need to be renamed** to match the adapter's actual field name
  (check `/llms/agent-configuration/<adapter>.txt` on your Paperclip instance)

---

## Phase 6 — Write and Confirm

Write the updated AGENTS.md to the output path. Report in the prompt language:

> **Updated:** `/absolute/path/to/AGENTS.md`
>
> **Changed:**
> - § Role — updated charter to include documentation ownership
> - § Collaboration and handoffs — added
>
> **Unchanged:** § Working rules, § Escalation, § Safety, § Done
>
> **Next step:** Resubmit the hire request to push instruction changes to the live agent.
> The API does not auto-sync from the local file.
> `POST /api/companies/:companyId/agent-hires` or `PATCH /api/agents/:agentId`

---

## Scope reference

| Change type | What it touches |
|---|---|
| Section text (charter, rules, lenses, routes, done criteria) | AGENTS.md only |
| Add or remove an optional section | AGENTS.md only |
| Adapter type, model, icon, budget, desiredSkills | Hire config only — output JSON snippet, do not write any file |
| Reporting line | AGENTS.md prose + `reportsTo` config field |
| Heartbeat timer on/off or interval | AGENTS.md § Safety + `runtimeConfig.heartbeat` |
| Agent name | AGENTS.md identity line + `name` config field |
| Company name | AGENTS.md identity line only (no config field) |
