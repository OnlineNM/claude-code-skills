---
name: discover
description: Extracts confirmed user intent before design. Use when the ask is underspecified ("build me X" without "for whom" or "why now"), when success criteria are missing, or when there is temptation to fill in unspoken assumptions. Produces docs/<slug>-INTENT.md. Handoff goes to sdd:ideate or sdd:design-adversarial.
---

# Discover — Intent Extraction Before Design

Answers "what do you actually want?" through a structured interview. Does not explore how to build it — only confirms what is being built, for whom, and why now.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **high thinking effort** (`ultrathink`) for all reasoning in this skill.

## Language

Conduct all dialogue with the user — questions, confirmations, status updates — exclusively in Romanian, regardless of the language the project/feature description was written in.

All deliverables this skill writes (`docs/<idea-slug>-SESSION.md`, `docs/<idea-slug>-INTENT.md`) must always be written in English. When the confirmed restat is captured in `INTENT.md`, translate it into English rather than copying the Romanian wording verbatim.

## Dialog Log

Maintain `docs/<idea-slug>-DIALOG.md` throughout the session — a verbatim, human-readable record of the interview: every question asked and the user's answer, plus the decisions reached. This file is an explicit exception to the English-deliverables rule above: it exists to document the actual Romanian dialogue, so its content stays in Romanian, matching what was really said.

Creation is handled by `steps/01-slug-and-branch.md`'s CHECKPOINT 2, alongside `SESSION.md`. Append a new entry after each confirmed question/answer in `steps/02-interview.md`, and after the final restat confirmation in `steps/03-confirm.md`. Use this format — one heading per topic, one paragraph per question/answer pair:

```markdown
# Dialog: <Idea Name>
Început: <YYYY-MM-DD>

## <Subiect — ex. "Ipoteza inițială", "Întrebarea N">

**Întrebare:** <întrebarea pusă>
**Răspuns:** <răspunsul utilizatorului>

**Decizie:** <ce s-a stabilit, dacă e cazul>

---
```

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
- `docs/<idea-slug>-DIALOG.md` — verbatim record of questions asked and decisions made (Romanian)
- `docs/<idea-slug>-INTENT.md` — confirmed intent structure

## Hard Rules

- Do NOT write `docs/<idea-slug>-INTENT.md` before the user gives an explicit "yes" to the restat.
- Do NOT ask more than one question per message.
- Do NOT write code or invoke other skills.
- Do NOT proceed past 03-confirm.md until the restat has been explicitly confirmed.
