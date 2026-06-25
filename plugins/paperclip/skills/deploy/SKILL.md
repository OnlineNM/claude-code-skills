---
name: deploy
description: >
  Deploy a new Paperclip agent to a live Paperclip instance by submitting a hire request to the API.
  Use when the user calls /ppc:deploy, wants to register a new agent with a running Paperclip server,
  or has a completed AGENTS.md (from /ppc:define or written manually) and needs to submit it.
  Conducts the interview in the same language as the prompt (Romanian or English).
  Always returns a clear, specific error if the company, manager, or credentials cannot be resolved.
---

# Paperclip Agent Deploy (`/ppc:deploy`)

This skill takes an agent definition and registers it with a live Paperclip instance.

## Language Rule

Detect the language of the user's `/ppc:deploy` prompt:
- Romanian prompt → conduct the entire interview in Romanian
- English prompt (or ambiguous/neutral) → conduct in English

---

## Prerequisites — Check Before Anything Else

Resolve credentials in this order of priority:

**PAPERCLIP_API_URL** — use the first value found:
1. A URL (http:// or https://) explicitly mentioned in the user's prompt
2. The `PAPERCLIP_API_URL` environment variable

**PAPERCLIP_API_KEY** — use the first value found:
1. An API key explicitly mentioned in the user's prompt (matches pattern `pcp_board_...` or similar)
2. The `PAPERCLIP_API_KEY` environment variable

Check environment variables with:

```sh
echo "API URL: ${PAPERCLIP_API_URL:-NOT SET}"
echo "API KEY: ${PAPERCLIP_API_KEY:+SET (redacted)}"
echo "API KEY: ${PAPERCLIP_API_KEY:-NOT SET}"
```

If a value is still missing after checking both sources, stop immediately with this error (translated to the interview language if needed):

> **Error: Missing credentials**
> Could not resolve the following required values from the prompt or environment:
> - `PAPERCLIP_API_URL` — base URL of the Paperclip instance (e.g. `https://app.paperclip.ai`)
> - `PAPERCLIP_API_KEY` — your board-user API key

Do not proceed until both are resolved.

---

## Phase 1 — Extract from the Initial Prompt

Scan the user's prompt for these items and note what is already present:

- AGENTS.md file path
- hire_config.json file path (optional — output of `/ppc:define`)
- Company Name
- Manager name or title
- Working directory (`cwd`) for local adapters
- Any other hire request fields explicitly mentioned

Then **auto-discover config files** in the current directory before asking anything:

```sh
ls hire_config.json AGENTS.md 2>/dev/null
```

- If `hire_config.json` is found and no path was given by the user, use it automatically and tell
  the user: *"Found hire_config.json in the current directory — using it to pre-fill agent config."*
- If `AGENTS.md` is found and no path was given by the user, use it as the default AGENTS.md path.

**Auto-extract deployment target fields** from the files discovered above — do this before asking anything in Phase 2:

- **Company Name**: look inside `hire_config.json`'s `instructionsBundle.files["AGENTS.md"]` content (or the standalone AGENTS.md file) for patterns like `at <Company Name>`, `company: <Company Name>`, or `at <Company Name>.` (sentence-ending). Use the first match found.
- **Manager name/title**: look in the same content for patterns like `You report to the <X>`, `reports to <X>`, `reportsTo: <X>`, or `report directly to the <X>`. Use the first match found.

Only ask for Company Name or Manager in Phase 2 if they could NOT be extracted from the files.

---

## Phase 2 — Mandatory Field Interview

Ask in batches of 2–3 questions. Wait for answers before continuing.

### Batch A — Input files (always ask first)

Only ask about files that were NOT auto-discovered in Phase 1.

| Field | Required | What to ask |
|-------|----------|-------------|
| **AGENTS.md path** | Yes | Path to the AGENTS.md file for this agent |
| **hire_config.json path** | No | Do you have a hire_config.json from `/ppc:define`? If yes, provide the path — it pre-fills all agent config fields |

Validate that the AGENTS.md file exists and is readable before continuing. If it does not exist:

> **Error: AGENTS.md not found**
> The file `<path>` does not exist. Provide the correct path or run `/ppc:define` first to generate it.

### Batch B — Deployment target

Only ask for fields that were NOT already extracted in Phase 1.

| Field | Required | What to ask |
|-------|----------|-------------|
| **Company Name** | Yes — if not extracted from files | The name of the Paperclip company to deploy this agent to |
| **Manager name** | Yes — if not extracted from files | The name or title of the agent this new agent will report to |

### Batch C — Agent config (skip if hire_config.json was provided)

If **no** hire_config.json was provided, also collect:

| Field | Default | What to ask |
|-------|---------|-------------|
| **Agent name** | _(required)_ | Short identifier (e.g. `Coder`, `DataAnalyst`) |
| **Role slug** | _(required)_ | Functional role (e.g. `engineer`, `qa`, `analyst`, `ceo`) |
| **Job title** | _(required)_ | Full title (e.g. `Software Engineer`) |
| **Capabilities** | _(required)_ | One sentence describing what the agent does |
| **Adapter type** | _(required)_ | Runtime adapter (e.g. `claude_local`, `codex_local`, `cursor`) |
| **Primary model** | _(required)_ | Main LLM model for this adapter |
| **Cheap model** | _(required)_ | Lightweight model for this adapter |
| **Working directory (`cwd`)** | _(required for local adapters)_ | Absolute path where the agent will run (skip for non-local adapters like `openclaw`) |
| **Icon** | `star` | Preferred icon (common: `code`, `bug`, `gem`, `crown`, `shield`, `zap`, `star`) |

---

## Phase 3 — Resolve Company and Manager via API

### 3.1 Resolve Company ID

```sh
curl -sS "$PAPERCLIP_API_URL/api/companies" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

Find the company whose `name` matches the provided Company Name (case-insensitive).

**If no match:**

> **Error: Company not found**
> No company named `<Company Name>` was found. Available companies:
> - `<name 1>` (id: `<id>`)
> - `<name 2>` (id: `<id>`)
>
> Check the name spelling or ask the Paperclip board user for the exact company name.

**If the list is empty:**

> **Error: No companies available**
> The API returned no companies for this API key. Verify that `PAPERCLIP_API_KEY` belongs to a board user with access to at least one company.

**If the API call fails (non-2xx):**

> **Error: API authentication failed** (for 401/403)
> The API key was rejected. Verify `PAPERCLIP_API_URL` and `PAPERCLIP_API_KEY`.

> **Error: Could not reach Paperclip** (for network errors or 5xx)
> `<raw error message>`. Check that `PAPERCLIP_API_URL` is reachable.

Store the matching `companyId` for subsequent calls.

### 3.2 Resolve Manager Agent ID

```sh
curl -sS "$PAPERCLIP_API_URL/api/companies/$COMPANY_ID/agents" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

Find the agent whose `name` or `title` matches the provided Manager Name (case-insensitive).

**If no match:**

> **Error: Manager not found**
> No agent named or titled `<Manager Name>` was found in company `<Company Name>`. Available agents:
> - `<name>` — `<title>` (role: `<role>`)
> - ...
>
> Check the name spelling or list agents in the Paperclip board to confirm the exact name.

**If the list is empty:**

> **Error: No agents in company**
> Company `<Company Name>` has no agents yet. The first agent (CEO) must be created via the board before additional agents can be hired.

Store the matching `agentId` as `MANAGER_ID` for the `reportsTo` field.

---

## Phase 4 — Build the Hire Request

### 4.1 Assemble the payload

If a `hire_config.json` was provided, load it and:
- Replace the `instructionsBundle.files["AGENTS.md"]` value with the content of the AGENTS.md file
- Set `reportsTo` to `MANAGER_ID` (resolved in Phase 3)
- Ensure `permissions.canCreateAgents` is `false`

If no `hire_config.json` was provided, build the payload from interview answers:

```json
{
  "name": "<agent name>",
  "role": "<role slug>",
  "title": "<job title>",
  "icon": "<icon>",
  "capabilities": "<capabilities>",
  "reportsTo": "<MANAGER_ID>",
  "adapterType": "<adapter type>",
  "adapterConfig": {
    "cwd": "<working directory (omit for non-local adapters)>",
    "model": "<primary model>",
    "cheapModel": "<cheap model>"
  },
  "permissions": {
    "canCreateAgents": false
  },
  "instructionsBundle": {
    "entryFile": "AGENTS.md",
    "files": {
      "AGENTS.md": "<contents of AGENTS.md file>"
    }
  },
  "runtimeConfig": {
    "heartbeat": {
      "enabled": false,
      "wakeOnDemand": true
    }
  }
}
```

### 4.2 Show a pre-submit summary

Before submitting, display a summary in the interview language:

```
Ready to deploy:
  Agent:    <name> (<title>)
  Company:  <Company Name> (id: <companyId>)
  Reports to: <Manager Name> (id: <managerId>)
  Adapter:  <adapterType> — <primary model> / <cheap model>
  cwd:      <working directory>
```

Ask for final confirmation before submitting.

---

## Phase 5 — Submit Hire Request

```sh
curl -sS -X POST "$PAPERCLIP_API_URL/api/companies/$COMPANY_ID/agent-hires" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '<payload JSON>'
```

### 5.1 On success

Parse the response:

- If `approval` is `null` — agent created directly as `idle`:
  > **Deployed successfully**
  > Agent `<name>` is live in company `<Company Name>`.
  > Agent ID: `<id>`
  > Status: `idle` — ready to receive work.

- If `approval` is present — hire is pending board approval:
  > **Hire request submitted — pending approval**
  > Agent `<name>` is in `pending_approval` state.
  > Agent ID: `<id>`
  > Approval ID: `<approvalId>`
  > The board must approve this hire before the agent can run. To check status:
  > ```sh
  > curl -sS "$PAPERCLIP_API_URL/api/approvals/<approvalId>" \
  >   -H "Authorization: Bearer $PAPERCLIP_API_KEY"
  > ```

### 5.2 On API error

Surface the raw error with context:

> **Error: Hire request failed** (HTTP `<status>`)
> `<error message from API response>`
>
> Common causes:
> - 400: A required field is missing or malformed — check adapter config and model names
> - 403: The API key does not have permission to hire agents in this company
> - 409: An agent with this name already exists in the company
> - 422: The adapter type or model name is not recognised by this Paperclip instance

Do not retry automatically. Show the full error and let the user decide how to proceed.
