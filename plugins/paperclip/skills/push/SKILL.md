---
name: ppc:push
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

Do a quick sanity check: the file should start with "You are agent" (the mandatory Paperclip
identity line). If it doesn't, warn the user:

> **Warning: Unexpected format**
> The file does not start with "You are agent …" — this is the required Paperclip identity line.
> Pushing this file will replace the agent's current instructions with content that may be invalid.
> Continue anyway? (yes / no)

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

This retrieves the current agent configuration. Store the full response — you'll need it
to detect the current instructions format and build the correct update payload.

---

## Phase 5 — Show Diff and Ask for Confirmation

Before pushing anything, show the user what will change. The goal is to prevent accidents —
a push to a live agent is immediate and visible to anyone using that agent.

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
> Push these changes? (yes / no)

Keep the diff readable — show added/removed lines, not raw unified diff. If the files are
identical, say so and stop:

> The local file is identical to what's already on the server. Nothing to push.

**Case B — Agent uses a file path reference (`adapterConfig.instructionsFilePath`):**
The agent's instructions aren't embedded in Paperclip — they're a pointer to a local path.
Pushing will switch the agent to an embedded bundle. Warn the user:

> **Note: Format change**
> Agent `<Agent Name>` currently uses a local file reference: `<instructionsFilePath>`
> Pushing will replace this with an embedded AGENTS.md bundle stored in Paperclip.
> After this push, `<instructionsFilePath>` will no longer be read.
>
> Push anyway? (yes / no)

**Case C — Agent has no instructions:**
Push will set the agent's instructions for the first time. Say so:

> **Note: New instructions**
> Agent `<Agent Name>` has no instructions stored in Paperclip yet.
> This push will set its AGENTS.md for the first time.
>
> Push? (yes / no)

---

## Phase 6 — Push

After the user confirms, build the update payload and send it:

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

**On success (2xx):**

> **Pushed successfully**
> Agent: `<Agent Name>` in `<Company Name>`
> The agent's instructions are now live. New heartbeats will pick up the updated AGENTS.md.

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
| Files identical | "Nothing to push" |
| Format change (file path → bundle) | Warning + confirmation |
| Push rejected (400) | Server error message, no change made |

Always name the specific thing that failed. Never show a generic "something went wrong."
