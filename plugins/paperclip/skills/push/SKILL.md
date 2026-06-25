---
name: push
description: >
  Push a local AGENTS.md file to a live Paperclip agent, updating its system prompt on the server.
  Use when the user calls /ppc:push, wants to deploy, upload, sync, or publish a local AGENTS.md
  to Paperclip, or has finished editing an agent's instructions locally (e.g. after /ppc:pull +
  /ppc:update) and wants the changes to go live. The user provides a company name, agent name,
  and the path to the local AGENTS.md. Always use this skill when the user wants to push agent
  instructions back to Paperclip — even if they say "deploy", "sync", "upload", or "publish".
---

# Paperclip Agent Push (`/ppc:push`)

Uploads a local AGENTS.md to a live Paperclip agent, replacing its current system prompt.
Verifies the company and agent exist before touching anything. Shows what will change and
asks for confirmation before making the API call.

## Language Rule

Detect the language of the user's `/ppc:push` prompt:
- Romanian prompt → conduct the entire session in Romanian
- English prompt (or ambiguous) → conduct in English

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
> Set the following environment variables before running `/ppc:push`:
> - `PAPERCLIP_API_URL` — base URL of the Paperclip instance (e.g. `https://app.paperclip.ai`)
> - `PAPERCLIP_API_KEY` — your board-user API key

---

## Phase 1 — Extract from the Initial Prompt

Scan the user's prompt for:

- Company name
- Agent name
- Path to the local AGENTS.md (the file to push)

---

## Phase 2 — Interview for Missing Fields

Ask only for what wasn't given:

| Field | Required | What to ask |
|-------|----------|-------------|
| **Company name** | Yes | Name of the Paperclip company |
| **Agent name** | Yes | Name of the agent to update |
| **AGENTS.md path** | Yes | Path to the local file to push (e.g. `./AGENTS.md`) |

Batch all missing fields into one question. Do not ask for fields already in the prompt.

---

## Phase 3 — Validate Local File

Read the file at the given path.

If the file does not exist:

> **Error: File not found**
> `<path>` does not exist. Check the path and try again.

If the file exists but is empty:

> **Error: Empty file**
> `<path>` is empty. Pushing an empty AGENTS.md would erase the agent's instructions.
> Provide a file with content.

Do a quick sanity check: the file should start with "You are" (the Paperclip identity line).
If it doesn't, warn the user:

> **Warning: Unexpected format**
> The file does not start with "You are …" — this is the expected Paperclip identity line.
> Pushing this file will replace the agent's current instructions with content that may be invalid.
> Continue anyway? (yes / no)

Also extract the agent name from the identity line — you'll use it later to sync the
agent's `name` field if needed. The identity line follows one of these patterns:

- `You are agent <name> (<title>) at <Company>.` → name is the word(s) after "agent " and before " ("
- `You are <name>, the <title>...` → name is everything after "You are " and before the first ","
- `You are <name> (<title>)...` → name is everything after "You are " and before the first "("

Strip "agent " prefix if present, then take everything up to the first `,`, `(`, or newline.

---

## Phase 4 — Resolve via API

### 4.1 Resolve Company ID

```sh
curl -sS "$PAPERCLIP_API_URL/api/companies" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

Match the company by `name` — case-insensitive exact match first, then contains/partial.

**Matching strategy:**
1. Exact match (case-insensitive)
2. Single partial match → use it and note: *"Found `TechCorp` — assuming that's what you meant."*
3. Multiple partial matches → list them and ask the user to confirm
4. No match → error with available companies listed

**On 401/403:**

> **Error: API authentication failed**
> The API key was rejected. Verify `PAPERCLIP_API_URL` and `PAPERCLIP_API_KEY`.

**On network error / 5xx:**

> **Error: Could not reach Paperclip**
> `<raw error>`. Check that `PAPERCLIP_API_URL` is reachable.

Store `companyId`.

### 4.2 Resolve Agent ID

```sh
curl -sS "$PAPERCLIP_API_URL/api/companies/$COMPANY_ID/agents" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

Apply the same matching strategy as 4.1.

**If no match:**

> **Error: Agent not found**
> No agent named `<Agent Name>` was found in company `<Company Name>`. Available agents:
> - `<name>` — `<title>`
> - ...
>
> Check the spelling or use one of the names above.

Store `agentId`.

### 4.3 Fetch Current Configuration

```sh
curl -sS "$PAPERCLIP_API_URL/api/agents/$AGENT_ID/configuration" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

Store the full response. You'll need it to:
- Detect the current instructions format (bundle vs. file path)
- Compare the current `name` field with the name extracted from the local AGENTS.md

---

## Phase 5 — Show Diff and Ask for Confirmation

Before pushing anything, show the user what will change. The goal is to prevent accidents —
a push to a live agent is immediate and visible to anyone using that agent.

Also check whether the agent's `name` field on the server differs from the name extracted
from the local AGENTS.md identity line (Phase 3). If they differ, include this in the summary
so the user knows the name will be synced.

Detect the current instructions format:

**Case A — Agent has an embedded instructionsBundle:**
Extract the current AGENTS.md from `instructionsBundle.files[instructionsBundle.entryFile]`
(or `files["AGENTS.md"]` if `entryFile` is absent). Compare it to the local file and show:

> **Push summary**
> Agent: `<Agent Name>` (`<title>`) in `<Company Name>`
> Local file: `<absolute path>` (`<N>` lines)
>
> **What changes:**
> - Line 6: "implement coding tasks" → "implement coding tasks and own technical documentation"
> - Lines 8–10: added (API docs, changelogs, ADR bullets)
>
> **What stays the same:** all other sections
>
> *(If name differs)* **Name sync:** `<current name>` → `<name from AGENTS.md>`
>
> Push these changes? (yes / no)

Keep the diff readable — show added/removed lines, not raw unified diff. If the files are
identical and the name doesn't need updating, say so and stop:

> The local file is identical to what's already on the server. Nothing to push.

**Case B — Agent uses a file path reference (`adapterConfig.instructionsFilePath`):**
The agent's instructions live on the server's disk. Pushing will switch the agent to
an embedded bundle and clear the file-path configuration — the bundle becomes the
permanent source of truth, surviving restarts. Warn the user about this format change:

> **Note: Format change**
> Agent `<Agent Name>` currently reads instructions from a file on the server's disk:
> `<instructionsFilePath>`
>
> Pushing will embed the AGENTS.md bundle directly in Paperclip and remove the file
> reference. After this push, the bundle is the source of truth — the disk file will
> no longer be read.
>
> *(If name differs)* **Name sync:** `<current name>` → `<name from AGENTS.md>`
>
> Push anyway? (yes / no)

**Case C — Agent has no instructions:**
Push will set the agent's instructions for the first time. Say so:

> **Note: New instructions**
> Agent `<Agent Name>` has no instructions stored in Paperclip yet.
> This push will set its AGENTS.md for the first time.
>
> *(If name differs)* **Name sync:** `<current name>` → `<name from AGENTS.md>`
>
> Push? (yes / no)

---

## Phase 6 — Push

After the user confirms, push the AGENTS.md bundle, then sync the agent name if needed.

### Step 6.1 — Push the bundle

**If the agent uses a file path reference (Case B)** — include null values to clear the
file-path configuration and switch the agent to bundle mode permanently:

```sh
curl -sS -X PATCH "$PAPERCLIP_API_URL/api/agents/$AGENT_ID" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "adapterConfig": {
      "instructionsBundle": {
        "entryFile": "AGENTS.md",
        "files": {
          "AGENTS.md": "<escaped content of local AGENTS.md>"
        }
      },
      "instructionsFilePath": null,
      "instructionsRootPath": null,
      "instructionsEntryFile": null,
      "instructionsBundleMode": null
    }
  }'
```

**If the agent already uses a bundle (Case A or C)** — only update the bundle:

```sh
curl -sS -X PATCH "$PAPERCLIP_API_URL/api/agents/$AGENT_ID" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "adapterConfig": {
      "instructionsBundle": {
        "entryFile": "AGENTS.md",
        "files": {
          "AGENTS.md": "<escaped content of local AGENTS.md>"
        }
      }
    }
  }'
```

Escape the AGENTS.md content as a valid JSON string (newlines → `\n`, quotes → `\"`).

### Step 6.2 — Sync agent name (if needed)

If the name extracted from the AGENTS.md identity line differs from the current `name`
field on the server, patch the name too:

```sh
curl -sS -X PATCH "$PAPERCLIP_API_URL/api/agents/$AGENT_ID" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "<name from AGENTS.md identity line>"}'
```

The agent's display name in the Paperclip board should always match what the AGENTS.md
says the agent is called. Keeping them in sync prevents confusion when the board shows
"CEO" but the agent introduces itself as "Smecherul cel Mare".

### Step 6.3 — Confirm

**On success (2xx for all calls made):**

> **Pushed successfully**
> Agent: `<Agent Name>` in `<Company Name>`
> The agent's instructions are now live. New heartbeats will pick up the updated AGENTS.md.
> *(If name was synced)* Name updated: `<old name>` → `<new name>`

**On 400 (bad request):**

> **Error: Push rejected**
> The server rejected the payload: `<error message from response>`
> The agent's instructions were not changed.

**On 401/403:**

> **Error: Permission denied**
> You don't have permission to update this agent. Verify your API key has write access.

**On 404:**

> **Error: Agent not found on server**
> The agent no longer exists (agentId: `<agentId>`). It may have been deleted since you started.

**On 5xx:**

> **Error: Server error**
> `<raw error>`. The agent's instructions may or may not have been updated — check the board.

---

## Error Reference

| Situation | What to show |
|-----------|-------------|
| Credentials missing | Error with both env var names |
| File not found / empty | Error with exact path |
| Bad format (no identity line) | Warning + confirmation |
| 401/403 | Auth failure — check key |
| Network error / 5xx | Could not reach Paperclip |
| Company not found | Error with available companies |
| Agent not found | Error with available agents |
| Files identical, name in sync | "Nothing to push" |
| File path reference (Case B) | Format-change warning + PATCH clears file-path fields to switch agent to bundle mode |
| Name mismatch | Auto-sync name after bundle push, report in success message |
| Push rejected (400) | Server error message, no change made |

Always name the specific thing that failed. Never show a generic "something went wrong."
