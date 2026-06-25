---
name: hire-config
description: >
  Generate a hire_config.json for an existing AGENTS.md file without creating or modifying the AGENTS.md itself.
  Use when the user calls /ppc:hire-config, has an AGENTS.md already written or imported from another system,
  and needs to create the Paperclip hire request config to deploy it. Interviews the user only for
  infrastructure fields (adapter type, models, role slug, cwd) — not for agent content already in AGENTS.md.
  Conducts the interview in the same language as the prompt (Romanian or English).
---

# Paperclip Hire Config (`/ppc:hire-config`)

This skill generates a `hire_config.json` for an existing `AGENTS.md` file.
Use it when the agent's system prompt already exists and you only need the deployment configuration.

The output is a single file: `hire_config.json`, saved in the same directory as `AGENTS.md`.
This file is auto-loaded by `/ppc:deploy`, so no config fields need to be re-entered.

## Language Rule

Detect the language of the user's prompt:
- Romanian → conduct the entire interview in Romanian
- English (or ambiguous) → conduct in English
- Always write `hire_config.json` in English regardless of interview language.

---

## Phase 1 — Locate AGENTS.md

If the user provided a path to `AGENTS.md` in their prompt, use it directly.

Otherwise, check the current directory:

```sh
ls AGENTS.md 2>/dev/null
```

If found, confirm: *"Found AGENTS.md in the current directory — using it."*

If not found and no path was given, ask for the path.

Validate the file exists and is readable. If it doesn't:

> **Error: AGENTS.md not found**
> The file `<path>` does not exist. Check the path and try again.

---

## Phase 2 — Auto-Extract from AGENTS.md

Read the file and extract these fields before asking anything:

| Field | Pattern |
|-------|---------|
| **Agent name** | `You are agent <Name>` or `You are <Name>` at the start of the file |
| **Job title** | `(<Job Title>)` on the same intro line, e.g. `You are agent Coder (Software Engineer) at ...` |
| **Company name** | `at <Company Name>` — end of the intro line or elsewhere |
| **Capabilities** | First sentence of the `## Role` section body |
| **Reporting line** | `You report to the <X>`, `reports to <X>`, or `report directly to the <X>` |

After extracting, show the user what was found and ask them to confirm or correct:

> "I extracted the following from your AGENTS.md — confirm or correct:
> - **Name**: `<name>`
> - **Title**: `<title>`
> - **Company**: `<company>`
> - **Capabilities**: `<capabilities>`
> - **Reports to**: `<reporting line>`"

If a field could not be extracted, mark it as missing and collect it in Phase 3.

---

## Phase 3 — Mandatory Field Interview

Collect only the fields that AGENTS.md did not provide. Ask in batches of 2–3 related questions — never all at once.

### Batch A — Role identity (only if not fully extracted)

| Field | What to collect |
|-------|-----------------|
| **Agent name** | Short identifier used in Paperclip (e.g. `Coder`, `DataAnalyst`) |
| **Job title** | Full human-readable title (e.g. `Software Engineer`) |
| **Capabilities** | One sentence: what this agent does end-to-end |
| **Role slug** | Functional role identifier (e.g. `engineer`, `qa`, `designer`, `ceo`, `manager`, `analyst`) — always ask this, it is never in AGENTS.md |

### Batch B — Infrastructure

| Field | What to collect |
|-------|-----------------|
| **Adapter type** | Runtime adapter. Confirmed supported: `claude_local`, `codex_local`, `opencode_local`, `gemini_local`, `cursor`, `openclaw_gateway`, `http`, `process` |
| **Primary model** | Main LLM model for this adapter (format depends on adapter — see table below) |
| **Cheap model** | Lightweight model for the same adapter |
| **Working directory (`cwd`)** | Absolute path where the agent will run. Required for local adapters (`claude_local`, `codex_local`, `opencode_local`, `gemini_local`, `cursor`). Skip for `openclaw_gateway`, `http`, `process`. |

### Model format by adapter

| Adapter | Format | Example |
|---------|--------|---------|
| `claude_local` | plain model ID | `claude-sonnet-4-6`, `claude-haiku-4-5` |
| `codex_local` | plain model ID | `gpt-5.5`, `o4-mini` |
| `opencode_local` | `provider/model` | `opencode/deepseek-v4-flash-free`, `anthropic/claude-sonnet-4-5` |
| `gemini_local` | plain model ID | `gemini-2.5-pro`, `gemini-2.5-flash` |
| `cursor` | plain model ID | `auto`, `gpt-5.3-codex` |
| `openclaw_gateway` | N/A | no `model` field |
| `http` / `process` | N/A | no `model` field |

When the user gives a model name without a provider prefix and the adapter is `opencode_local`, ask which provider serves it.

---

## Phase 4 — Optional Field Interview

After mandatory fields are confirmed, offer optional fields. Tell the user they can skip any or all and sensible defaults will be used.

| Field | Default | What to ask |
|-------|---------|-------------|
| **Icon** | `star` | Preferred icon? Common: `code`, `bug`, `gem`, `crown`, `shield`, `zap`, `star` |
| **Heartbeat timer** | off | Should this agent run on a scheduled timer, or only wake when assigned work? |
| **Heartbeat interval** | 300s (if enabled) | How often? (in seconds) |
| **Monthly budget** | _(none)_ | Monthly cost cap in USD cents? (e.g. `10000` = $100) |
| **Company skills** | _(none)_ | Any Paperclip company skills this agent needs from day one? |
| **Source issue ID** | _(none)_ | Was this hire triggered by a Paperclip issue? If so, what's the issue ID? |

---

## Phase 5 — Confirm and Generate

Summarize the full configuration and ask for confirmation:

> "Here's what I'll generate:
> - **Name**: `<name>` | **Role**: `<role>` | **Title**: `<title>`
> - **Adapter**: `<adapterType>` — `<primary model>` / `<cheap model>`
> - **cwd**: `<working directory>`
> - **Output**: `<directory of AGENTS.md>/hire_config.json`
> Ready to generate?"

---

## Phase 6 — Write hire_config.json

### Check for existing file

```sh
ls "<directory of AGENTS.md>/hire_config.json" 2>/dev/null
```

If it exists, stop and warn:

> **Warning: hire_config.json already exists**
> `<path>` already exists. Overwrite?

Wait for confirmation before writing.

### Payload structure

```json
{
  "name": "<agent name>",
  "role": "<role slug>",
  "title": "<job title>",
  "icon": "<icon>",
  "capabilities": "<one-sentence capabilities>",
  "adapterType": "<adapter type>",
  "adapterConfig": {
    "cwd": "<working directory>",
    "model": "<primary model>",
    "cheapModel": "<cheap model>"
  },
  "instructionsBundle": {
    "entryFile": "AGENTS.md",
    "files": {
      "AGENTS.md": "<full contents of the AGENTS.md file>"
    }
  },
  "permissions": {
    "canCreateAgents": false
  },
  "runtimeConfig": {
    "heartbeat": {
      "enabled": false,
      "wakeOnDemand": true
    }
  }
}
```

Field rules:
- Omit `cwd` from `adapterConfig` for `openclaw_gateway`, `http`, `process`
- Omit `model` and `cheapModel` for `openclaw_gateway`, `http`, `process`
- Add `"intervalSec": <N>` inside `heartbeat` only if the user enabled the timer
- Add `"budgetMonthlyCents": <N>` at the top level only if the user provided a budget
- Add `"desiredSkills": [...]` at the top level only if the user listed skills
- Add `"sourceIssueId": "<id>"` at the top level only if a source issue was provided

### Write the file

Save `hire_config.json` to the same directory as the AGENTS.md file.

After writing, tell the user:
- Full path of `hire_config.json`
- Which optional fields used defaults (and what those defaults were)
- That `cheapModel` in `adapterConfig` may need to be renamed to match the adapter's actual field name (check `/llms/agent-configuration/<adapter>.txt` on their Paperclip instance)
- That this file will be auto-loaded by `/ppc:deploy` — no re-entry needed
- Next step: run `/ppc:deploy` to register the agent on a live Paperclip instance
