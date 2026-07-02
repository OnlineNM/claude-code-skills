---
name: discover
description: Extracts confirmed user intent before design. Use when the ask is underspecified ("build me X" without "for whom" or "why now"), when success criteria are missing, or when there is temptation to fill in unspoken assumptions. Produces docs/<slug>-INTENT.md. Handoff goes to sdd:ideate or sdd:design-adversarial.
---

# Discover — Intent Extraction Before Design

Answers "what do you actually want?" through a structured interview. Does not explore how to build it — only confirms what is being built, for whom, and why now.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **high thinking effort** (`ultrathink`) for all reasoning in this skill.

## Language

Ask all questions in the same language the project/feature description was written in (Romanian or English).

## Before Starting

Tell the user: *"Please run `/clear` first to start with a clean context, then re-invoke this skill."*
If the user has already cleared, proceed.

## Process

Read and follow each file in `steps/` **in numeric order**. Each step file is mandatory context, not optional background — do not skip a step file or rely on the index summary alone.

1. `steps/00-setup.md` — git dirty-state check, enter plan-mode
2. `steps/01-slug-and-branch.md` — slug confirmation, session file, branch strategy (Checkpoints 1-3)
3. `steps/02-interview.md` — structured interview loop
4. `steps/03-confirm.md` — present and confirm the restat
5. `steps/04-write-and-handoff.md` — write INTENT.md, commit, handoff

## Output

- `docs/<idea-slug>-SESSION.md` — persistent session context
- `docs/<idea-slug>-INTENT.md` — confirmed intent structure

## Hard Rules

- Do NOT write `docs/<idea-slug>-INTENT.md` before the user gives an explicit "yes" to the restat.
- Do NOT ask more than one question per message.
- Do NOT write code or invoke other skills.
- Do NOT proceed past 03-confirm.md until the restat has been explicitly confirmed.
