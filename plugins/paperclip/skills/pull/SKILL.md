---
name: pull
description: >
  Pull an agent's AGENTS.md system prompt from a live Paperclip instance and save it locally.
  Use when the user calls /ppc:pull, wants to fetch, download, or retrieve an agent's instructions
  from Paperclip, or needs to sync a local AGENTS.md with what's stored on the server.
  Conducts the interview in the same language as the prompt (Romanian or English).
---

# Paperclip Agent Pull (`/ppc:pull`)

Fetches an agent's AGENTS.md from a live Paperclip instance and saves it to disk.

## Language Rule

Detect the language of the user's `/ppc:pull` prompt:
- Romanian prompt → conduct the entire interview in Romanian
- English prompt (or ambiguous/neutral) → conduct in English

---

## Prerequisites — Check Before Anything Else

Verify both environment variables are set:

```sh
echo "API URL: ${PAPERCLIP_API_URL:-NOT SET}"
echo "API KEY: ${PAPERCLIP_API_KEY:+SET (redacted)}"
echo "API KEY: ${PAPERCLIP_API_KEY:-NOT SET}"
```

If either is missing, stop immediately:

> **Error: Missing credentials**
> Set the following environment variables before running `/ppc:pull`:
> - `PAPERCLIP_API_URL` — base URL of the Paperclip instance (e.g. `https://app.paperclip.ai`)
> - `PAPERCLIP_API_KEY` — your board-user API key

Do not proceed until both are set.

---

## Phase 1 — Extract from the Initial Prompt

Scan the user's prompt for:

- Company name
- Agent name (the agent whose AGENTS.md to pull)
- Output path (where to save the file locally — optional)

---

## Phase 2 — Mandatory Interview

Ask in batches. Wait for answers before continuing.

### Batch A — Identity (always collected first)

| Field | Required | What to ask |
|-------|----------|-------------|
| **Company name** | Yes | Name of the Paperclip company |
| **Agent name** | Yes | Name of the agent (the `name` field as shown in the board, e.g. `CTO`, `Coder`, `DataAnalyst`) |

### Batch B — Output path (ask only if not specified in prompt)

| Field | Default | What to ask |
|-------|---------|-------------|
| **Output path** | `./AGENTS.md` | Where to save the file? (press enter to use `./AGENTS.md`) |

If the user does not specify a path, use `./AGENTS.md` in the current working directory without asking — only ask Batch B if there is a reason to (e.g. the user seems to be pulling multiple agents, or a file already exists at the default path).

---

## Phase 3 — Resolve via API

### 3.1 Resolve Company ID

```sh
curl -sS "$PAPERCLIP_API_URL/api/companies" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

Match the company by `name` — case-insensitive exact match first, then contains/partial match.

**Matching strategy:**
1. Exact match (case-insensitive): `"TechCorp"` matches `"techcorp"` or `"TECHCORP"`
2. If no exact match: look for companies where the name contains the input string
3. If exactly one partial match: use it and note: *"Found `TechCorp` — assuming that's what you meant."*
4. If multiple partial matches: list them and ask the user to confirm which one

**If no match at all:**

> **Error: Company not found**
> No company named `<Company Name>` was found. Available companies:
> - `<name 1>`
> - `<name 2>`
>
> Check the spelling or ask the Paperclip board user for the exact company name.

**If the list is empty:**

> **Error: No companies available**
> The API returned no companies for this API key. Verify that `PAPERCLIP_API_KEY` belongs to a board user with access to at least one company.

**On 401/403:**

> **Error: API authentication failed**
> The API key was rejected. Verify `PAPERCLIP_API_URL` and `PAPERCLIP_API_KEY`.

**On network error or 5xx:**

> **Error: Could not reach Paperclip**
> `<raw error>`. Check that `PAPERCLIP_API_URL` is reachable and the server is running.

Store the matching `companyId`.

### 3.2 Resolve Agent ID

```sh
curl -sS "$PAPERCLIP_API_URL/api/companies/$COMPANY_ID/agents" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

Match the agent by `name` — apply the same matching strategy as in 3.1 (exact match first, then partial).

**If no match:**

> **Error: Agent not found**
> No agent named `<Agent Name>` was found in company `<Company Name>`. Available agents:
> - `<name>` — `<title>` (role: `<role>`)
> - ...
>
> Check the spelling or use one of the names above.

**If the list is empty:**

> **Error: No agents in company**
> Company `<Company Name>` has no agents. Nothing to pull.

Store the matching `agentId`.

### 3.3 Fetch Instructions Bundle Metadata

```sh
curl -sS "$PAPERCLIP_API_URL/api/agents/$AGENT_ID/instructions-bundle" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

This returns bundle metadata including `entryFile` and a `files` array with path and size per file.
The `files` array contains metadata only — not file content.

If this returns 404, fall back to the configuration endpoint:

```sh
curl -sS "$PAPERCLIP_API_URL/api/agents/$AGENT_ID/configuration" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

Store `entryFile` (default `"AGENTS.md"` if absent) and the list of file paths from `files[].path`.

### 3.4 Fetch File Content

For each file to pull (at minimum the entryFile), fetch its content:

```sh
curl -sS "$PAPERCLIP_API_URL/api/agents/$AGENT_ID/instructions-bundle/file?path=AGENTS.md" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

The response is a JSON object with a `content` field containing the file's text.

---

## Phase 4 — Extract and Save

### 4.1 Determine what instructions are stored

Inspect the bundle metadata response:

**Case A — bundle metadata returned with files array:**
→ Use the `entryFile` field (default `"AGENTS.md"`) to identify the main file.
→ Fetch its content via `/api/agents/$AGENT_ID/instructions-bundle/file?path=<entryFile>` and extract the `content` field.
→ If the bundle contains additional files beyond the entryFile, note them to the user.

**Case B — bundle metadata not available (404), configuration endpoint used instead:**

Check the configuration response:
- If `instructionsBundle.files` is present with string values → extract content directly from `files[entryFile]`.
- If only `adapterConfig.instructionsFilePath` is set → try fetching via the bundle file endpoint anyway:
  ```
  GET /api/agents/$AGENT_ID/instructions-bundle/file?path=AGENTS.md
  ```
  If that succeeds, extract `content`. If it also fails (404), stop and report:

> **Note: Instructions not accessible via API**
> Agent `<Agent Name>` stores its instructions at:
> `<instructionsFilePath>`
>
> The content could not be retrieved via the API. To get a copy:
> - Read the file directly from that path on the server, or
> - Run `/ppc:define` to create a new AGENTS.md and re-deploy with an embedded bundle.

**Case C — no instructions found anywhere:**

> **Error: No AGENTS.md found**
> Agent `<Agent Name>` has no instructions bundle stored in Paperclip.
> This can happen if the agent was created without an AGENTS.md (e.g. via the board UI without a file),
> or if the instructions were cleared.
>
> Run `/ppc:define` to write a new AGENTS.md, then `/ppc:deploy` to push it to the agent.

### 4.2 Determine the output path

Use the path provided by the user, or `./AGENTS.md` as the default.

If a file already exists at the output path:

> **Warning: File already exists**
> `<path>` already exists. Overwrite it? (yes / no / enter a new path)

Do not overwrite without confirmation.

### 4.3 Write the file

Write the extracted AGENTS.md content to the output path.

### 4.4 Confirm

Report success:

> **Pulled successfully**
> Agent: `<Agent Name>` (`<title>`) in `<Company Name>`
> Saved to: `<absolute path>`
>
> ```
> <first 5 lines of AGENTS.md as preview>
> ...
> ```

If there were additional bundled files (beyond AGENTS.md), list them:

> **Note:** This agent's bundle also contains: `<file1>`, `<file2>`
> These were not saved locally. Ask if you need them pulled too.

---

## Error Reference

| Situation | What to show |
|-----------|-------------|
| Credentials missing | Error with both `PAPERCLIP_API_URL` and `PAPERCLIP_API_KEY` named |
| 401/403 from any call | API auth failure — check key |
| Network error / 5xx | Could not reach Paperclip — check URL |
| Company not found | Company-not-found error with available companies listed |
| Agent not found | Agent-not-found error with available agents listed |
| File path reference | Explain it's a local pointer, show the path, suggest alternatives |
| No instructions stored | Explain no bundle exists, suggest /ppc:define |
| Output file exists | Warn and ask before overwriting |

Always name the specific thing that failed (which company, which agent, which file). Never show a generic "something went wrong" message.
