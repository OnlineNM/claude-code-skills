---
name: ppc:define
description: >
  Define a new Paperclip AI agent by interviewing the user and generating a complete AGENTS.md system
  prompt file plus a hire request JSON config. Use when the user calls /ppc:define, wants to create
  or configure a new Paperclip agent, or needs help writing an AGENTS.md or agent hire request.
  Conducts the interview in the same language as the prompt (Romanian or English).
  Always produces the final AGENTS.md in English.
---

# Paperclip Agent Definition (`/ppc:define`)

This skill guides you through defining a new Paperclip agent. It extracts information from the user's
prompt, interviews them for anything missing, and generates two artifacts:

1. **`AGENTS.md`** — the agent's system prompt (always in English)
2. **Hire request config** — a JSON snippet ready for the Paperclip API

## Language Rule

Detect the language of the user's initial `/ppc:define` prompt:
- Romanian prompt → conduct the entire interview in Romanian
- English prompt (or ambiguous/neutral) → conduct in English
- **Always write `AGENTS.md` and the hire config JSON in English, regardless of interview language**

---

## Phase 1 — Extract from the Initial Prompt

Before asking anything, scan the user's prompt for information already present. Extract and note each
of the following that you can determine:

- Agent name
- Company name
- Job title / role
- Adapter type
- LLM models (primary / cheap)
- Reporting line (who the agent reports to)
- What the agent does (capabilities / charter)
- Collaboration routes (which peer agents this agent hands off to and for what)
- Any mentioned tools or company skills

List what you found and what is still missing. Then move to Phase 2.

---

## Phase 2 — Mandatory Field Interview

You must collect all mandatory fields before generating any output. Ask in batches of 2–3 related
questions — never dump the full list at once. After each batch, wait for the user's answers before
continuing. Mark each field as you collect it.

### Mandatory fields

| # | Field | What to collect |
|---|-------|-----------------|
| 1 | **Agent name** | Short identifier used in Paperclip (e.g. `Coder`, `MarketingLead`, `DataAnalyst`) |
| 2 | **Job title** | Full human-readable title (e.g. `Software Engineer`, `QA Lead`, `Product Designer`) |
| 3 | **Adapter type** | Runtime adapter name. Confirmed supported: `claude_local`, `codex_local`, `opencode_local`, `gemini_local`, `cursor`, `openclaw_gateway`, `http`, `process` |
| 4 | **Primary model** | The main LLM model for this adapter. Format depends on adapter — see model format table below. |
| 5 | **Cheap model** | The lightweight/cheap LLM model from the same adapter. Same format rules as primary model. |
| 6 | **Role slug** | Functional role identifier (e.g. `engineer`, `qa`, `designer`, `ceo`, `manager`, `analyst`) |
| 7 | **Company name** | The Paperclip company this agent belongs to |
| 8 | **Reporting line** | Who this agent reports to (title or agent name, e.g. `the CTO`, `the CEO`) |
| 9 | **Capabilities** | One sentence: what this agent does end-to-end |
| 10 | **Role charter** | What this agent owns, what problem it solves, and what is explicitly out of scope |

### Model format by adapter

| Adapter | Model format | Example |
|---------|-------------|---------|
| `claude_local` | plain model ID | `claude-sonnet-4-6`, `claude-haiku-4-5` |
| `codex_local` | plain model ID | `gpt-5.5`, `o4`, `o4-mini` |
| `opencode_local` | `provider/model` | `opencode/deepseek-v4-flash-free`, `anthropic/claude-sonnet-4-5` |
| `gemini_local` | plain model ID | `gemini-2.5-pro`, `gemini-2.5-flash` |
| `cursor` | plain model ID | `auto`, `gpt-5.3-codex` |
| `openclaw_gateway` | N/A | no `model` field — uses WebSocket URL config instead |
| `http` / `process` | N/A | no `model` field |

When the user names a model without a provider prefix and the adapter is `opencode_local`, ask which
provider serves it (e.g. `opencode`, `anthropic`, `openai`) or look it up from a peer agent in the
same company that uses the same adapter.

Suggested batching:
- **Batch A**: fields 1, 2 (agent name + job title — always collected first, never skipped)
- **Batch B**: fields 3, 4, 5 (infrastructure)
- **Batch C**: fields 6, 7, 8 (org chart position)
- **Batch D**: fields 9, 10 (what the agent actually does)

If a field can be confidently inferred from the user's prompt, pre-fill it and confirm ("I'm assuming
X — is that right?") rather than asking from scratch.

---

## Phase 3 — Optional Field Interview

After all mandatory fields are confirmed, offer to collect optional fields. Tell the user they can
skip any or all of them and sensible defaults will be used.

| Field | Default if skipped | What to ask |
|-------|--------------------|-------------|
| **Icon** | `star` | Preferred icon? Common: `code`, `bug`, `gem`, `crown`, `shield`, `zap`, `star` |
| **Company skills** | _(none)_ | Any Paperclip company skills this agent needs from day one? |
| **Heartbeat timer** | off (wake on demand only) | Should this agent run on a scheduled timer, or only wake when assigned work? |
| **Heartbeat interval** | 300s (if timer enabled) | How often should the timer fire? (seconds) |
| **Monthly budget** | _(none)_ | Is there a monthly cost cap for this agent? (in USD cents, e.g. 10000 = $100) |
| **Collaboration routes** | _(none)_ | Which peer agents should this agent hand work off to, and for what? (e.g. "browser tests → QA", "security changes → SecurityEngineer") |
| **Domain lenses** | _(omit for narrow operational roles)_ | 5–15 named judgment lenses specific to this role — required for expert/specialist roles (engineer, designer, analyst, security, QA), optional for narrow operational agents |
| **Escalation triggers** | _(none specified)_ | In which situations should this agent escalate to its manager? (e.g. work outside scope, blocked, needs specialist input) |
| **Done criteria** | _(generic comment + status update)_ | How does this agent verify work before marking a task done? |
| **Source issue ID** | _(none)_ | Was this hire triggered by a Paperclip issue? If so, what's the issue ID? |

**Domain lens examples** (for reference when asking):
- Security engineer: OWASP Top 10, least-privilege, blast radius, defence in depth, secrets hygiene
- UX designer: Nielsen's 10, Gestalt proximity, Fitts's Law, WCAG POUR, Kano Model
- Data engineer: idempotency, backpressure, schema evolution, cost-per-query, lineage
- Coder: test coverage, commit hygiene, complexity budget, CI-green-before-merge, rollback path

---

## Phase 4 — Confirm and Generate

Once all mandatory fields are collected (and optionals are either provided or skipped), briefly
summarize the agent configuration to the user and ask for a final confirmation before generating.

Example summary (in the interview language):
> "Here's what I'll generate:
> - **Name**: MarketingLead | **Role**: manager | **Adapter**: claude_local (claude-sonnet-4-6 / claude-haiku-4-5)
> - **Reports to**: CEO | **Company**: Acme Corp
> - Ready to generate AGENTS.md?"

After confirmation, generate both artifacts.

---

## Phase 5 — Generate Artifacts

### A. Hire Request Config (JSON)

Output a code block with the hire request payload. Use `cheapModel` as the field name for the
secondary model inside `adapterConfig` — the adapter's own documentation may use a different name,
so note this to the user.

```json
{
  "name": "<agent name>",
  "role": "<role slug>",
  "title": "<job title>",
  "icon": "<icon>",
  "capabilities": "<one-sentence capabilities>",
  "adapterType": "<adapter type>",
  "adapterConfig": {
    "model": "<primary model>",
    "cheapModel": "<cheap model>"
  },
  "instructionsBundle": {
    "files": {
      "AGENTS.md": "<contents of AGENTS.md>"
    }
  },
  "permissions": {
    "canCreateAgents": false
  },
  "runtimeConfig": {
    "heartbeat": {
      "enabled": <true if timer requested, else false>,
      "intervalSec": <interval or omit if not enabled>,
      "wakeOnDemand": true
    }
  },
  "budgetMonthlyCents": <budget or omit if not provided>,
  "desiredSkills": [<skill list or omit if empty>],
  "sourceIssueId": "<source issue ID or omit>"
}
```

Omit optional fields (`budgetMonthlyCents`, `desiredSkills`, `sourceIssueId`) when not provided.

### B. AGENTS.md Content

Generate the AGENTS.md following the Paperclip baseline role guide. Fill every section with
role-specific content — never use placeholder text like `[describe X here]` in the final output.

**Always include these mandatory sections:**

```markdown
You are agent <name> (<Job Title>) at <Company Name>.

When you wake up, follow the Paperclip skill. It contains the full heartbeat procedure.

You report to <reporting line>. Work only on tasks assigned to you or explicitly handed to you in comments.

## Role

<Role charter: what this agent owns, what problem it solves, what is out of scope.
One paragraph plus a bullet list. Be specific — name the artifacts, decisions, or surfaces this agent
is accountable for. A good charter lets the agent say no to off-scope work.>

## Working rules

Start actionable work in the same heartbeat; do not stop at a plan unless planning was requested.
Leave durable progress with a clear next action. Use child issues for long or parallel delegated
work instead of polling. Mark blocked work with owner and action. Respect budget, pause/cancel,
approval gates, and company boundaries.

Do not create sub-agents and do not delegate work directly to peer agents. When a task requires
input or action from another specialist, escalate to <reporting line> with a clear description of
what is needed and why — delegation decisions belong to the manager.

<Add 3–5 role-specific operating rules here: what scope means for this role, what a progress comment
must include, when to escalate vs. proceed independently, etc.>

## Escalation

<List the situations in which this agent escalates to its manager, and what information to include
when escalating. Only list triggers that apply to this specific role.
Format: "- [Situation] → escalate to <reporting line> with [what context to include]"

Examples of good escalation triggers:
- Work requires access or permissions this agent does not have
- Task is outside the agent's role charter
- Input is needed from another specialist before proceeding
- A decision has significant cost, risk, or strategic implications>

## Safety and permissions

<Least-privilege defaults for this role. State what the agent may and may not do. Cover:
- cannot create sub-agents (canCreateAgents: false)
- cannot delegate tasks directly to peer agents — all cross-agent routing goes through the manager
- secrets handling
- timer heartbeat (default off — only enable if requested with justification)
- any elevated permissions this role needs
- what never ships without explicit approval>

## Done

<How this agent verifies its own work before marking a task done or handing to a reviewer.
Be concrete: the smallest check that proves the work, what evidence goes in the final comment,
who the task is reassigned to on completion.>

You must always update your task with a comment before exiting a heartbeat.
```

**Include `## Collaboration and handoffs` whenever the agent has peer routes (include for most non-CEO roles):**

```markdown
## Collaboration and handoffs

<List only the handoff routes that apply to this specific role.
Format: "- [Trigger] → hand off to <AgentName>: [what to include in the handoff]"

Examples:
- Browser or user-facing verification needed → hand off to QA: steps to reproduce, expected behaviour, test scope
- Security-sensitive change (auth, secrets, permissions, input validation) → hand off to SecurityEngineer: diff, threat surface, urgency
- UX or visual design needed → hand off to UXDesigner: user need, constraints, existing patterns to respect
- Runtime or infrastructure decision → escalate to CTO: options considered, trade-offs, recommendation>
```

**Include `## Domain lenses` for all expert/specialist roles (engineer, designer, analyst, security, QA). Omit for narrow operational agents:**

```markdown
## Domain lenses

<5–15 named lenses this agent applies when making judgment calls. Short label + one-line explanation.
The agent should cite lenses by name in task comments.>
```

**Include `## Output bar` for all roles that produce a deliverable (code, designs, reports, specs):**

```markdown
## Output bar

<What a good deliverable looks like for this role. Concrete: shape of output, what it must include,
what "not done" looks like, what never ships.>
```

### C. Write the Files

Save both files to the **current working directory** — no directory exploration, no path selection.

Before writing, check only whether either file already exists:

```sh
ls AGENTS.md hire_config.json 2>/dev/null
```

If one or both files already exist, **stop and warn the user** (in the interview language):

> **Warning: file(s) already exist**
> The following files already exist in the current directory:
> - `AGENTS.md` _(if present)_
> - `hire_config.json` _(if present)_
>
> Overwrite?

Wait for the user's confirmation before writing. Do not ask for a different directory.

Once confirmed (or if neither file exists), write directly:

1. **`AGENTS.md`** — the system prompt content generated above
2. **`hire_config.json`** — the full hire request JSON generated above, including `instructionsBundle`

Tell the user both full paths. Explain that `hire_config.json` will be auto-loaded by `/ppc:deploy`
so they will not need to re-enter any agent config fields, even after `/clear` or a new session.

Also tell the user:
- Which optional fields used defaults (and what those defaults were)
- That `cheapModel` in `adapterConfig` may need to be renamed to match the adapter's actual field name
  (they can check `/llms/agent-configuration/<adapter>.txt` on their Paperclip instance)
- How to submit the hire request: `POST /api/companies/:companyId/agent-hires`
- That `permissions.canCreateAgents: false` is always set — agents defined with this skill are
  individual contributors and never create or hire other agents
- That cross-agent collaboration is always routed through the manager (Escalation section), not
  directly to peer agents — this is a fixed architectural constraint, not a per-agent choice
