# Paperclip Plugin

The Paperclip plugin provides a complete agent workflow for Paperclip companies:

- define a new agent contract and instructions
- deploy a new agent to a live Paperclip instance
- pull an agent's current AGENTS.md from Paperclip
- update an existing AGENTS.md or hire-config fields
- push updated AGENTS.md instructions back to Paperclip

## Plugin Metadata

- Name: `ppc`
- Description: Paperclip agent workflow tools for define, deploy, pull, update, and push operations

## Available Commands

- `/ppc:define`: Interview-driven creation of AGENTS.md plus hire request JSON
- `/ppc:deploy`: Submit a hire request to register a new agent in a company
- `/ppc:pull`: Fetch AGENTS.md from a live agent and save it locally
- `/ppc:update`: Apply targeted edits to AGENTS.md and optionally output config JSON updates
- `/ppc:push`: Upload a local AGENTS.md to update a live agent configuration

## Language Behavior

- Interviews and status messages follow the user's prompt language (Romanian or English)
- Generated AGENTS.md content is always written in English

## Prerequisites

For commands that interact with a live Paperclip API (`/ppc:deploy`, `/ppc:pull`, `/ppc:push`), set:

- `PAPERCLIP_API_URL`
- `PAPERCLIP_API_KEY`

## Typical Workflows

### Create and launch a new agent

1. Run `/ppc:define` to generate AGENTS.md and hire configuration
2. Run `/ppc:deploy` to register the agent in the target company

### Safely edit an existing live agent

1. Run `/ppc:pull` to download the current AGENTS.md
2. Run `/ppc:update` to apply requested changes
3. Run `/ppc:push` to publish the updated AGENTS.md

## Directory Layout

- `skills/define/SKILL.md`
- `skills/deploy/SKILL.md`
- `skills/pull/SKILL.md`
- `skills/update/SKILL.md`
- `skills/push/SKILL.md`
