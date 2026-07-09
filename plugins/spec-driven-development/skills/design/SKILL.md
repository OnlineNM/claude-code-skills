---
name: design
description: Extracts confirmed user intent before design. Use when the ask is underspecified ("build me X" without "for whom" or "why now"), when success criteria are missing, or when there is temptation to fill in unspoken assumptions. Produces docs/<slug>-DESIGN.md. Handoff goes to sdd:ideate or sdd:spec.
---

# Design — Intent Extraction Before Design

Answers "what do you actually want?" through a structured interview. Does not explore how to build it — only confirms what is being built, for whom, and why now.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **high thinking effort** (`ultrathink`) for all reasoning in this skill.

## Language

Conduct all dialogue with the user — questions, confirmations, status updates — exclusively in Romanian, regardless of the language the project/feature description was written in.

All deliverables this skill writes (`docs/<idea-slug>-SESSION.md`, `docs/<idea-slug>-DESIGN.md`) must always be written in English. When the confirmed restat is captured in `DESIGN.md`, translate it into English rather than copying the Romanian wording verbatim.

## Output and Context Rules

This skill talks to the user a lot (interview) and touches only two small files — the failure mode here isn't "too many search results," it's re-printing content that already lives on disk. Apply these rules throughout:

- Ask exactly one question per message. Keep each message to the question plus the minimal context needed to answer it — not a recap of prior answers.
- Do not restate the full conversation history in any message. If you need to reference an earlier answer, name it in one short clause, not a quote block.
- If the user's initial description is long, extract only what maps to Outcome / User / Why Now / Success Criteria / Constraints / Out of Scope. Do not quote the raw description back verbatim.
- When resuming from an existing `docs/<idea-slug>-SESSION.md`, read only the `Decisions Reached` and `Open Questions` sections needed to resume — do not print the file's contents back to the user.
- Present the final restat (`steps/03-confirm.md`) exactly once, as six one-line fields (Outcome, User, Why Now, Success Criteria, Constraints, Out of Scope). Do not pad it into paragraphs or repeat it if the user asks a clarifying question about only one field — answer about that field alone.
- After writing `docs/<idea-slug>-DESIGN.md` (`steps/04-write-and-handoff.md`), do not print its contents in the console. Confirm only the file path, per that step's instructions.
- Between steps, give a one-line status update (e.g., "Slug confirmat — încep interviul.") — not a summary of what just happened.
- Read files under `steps/` one at a time, immediately before executing that step — not all five upfront. If the session ends early (user abandons or context resets), you should not have paid the context cost of unused later steps.
- Never dump raw file contents, git output, or command logs into the conversation. If a command's output is needed to make a decision, state the one-line conclusion, not the raw output.
- If ever unsure how much detail to show the user, default to the shorter option — a one-line confirmation beats a restated block.

## Before Starting

Tell the user: *"Please run `/clear` first to start with a clean context, then re-invoke this skill."*
If the user has already cleared, proceed.

## Process

Read and follow each file in `steps/` **one at a time, in numeric order, immediately before executing it**. Each step file is mandatory context for its own step — do not pre-load later step files, and do not rely on the index summary below as a substitute for reading the step file itself.

1. `steps/00-setup.md` — git dirty-state check, enter plan-mode
2. `steps/01-slug-and-branch.md` — slug confirmation, session file, branch strategy (Checkpoints 1-3)
3. `steps/02-interview.md` — structured interview loop
4. `steps/03-confirm.md` — present and confirm the restat
5. `steps/04-write-and-handoff.md` — write DESIGN.md, commit, handoff

## Output

- `docs/<idea-slug>-DESIGN.md` — confirmed intent structure. Written once, not echoed back to the user after writing.
- `docs/<idea-slug>-SESSION.md` — scratch file used only to survive context compaction mid-session; deleted (not committed) once DESIGN.md is written. Never printed to the user.

## Hard Rules

- Do NOT write `docs/<idea-slug>-DESIGN.md` before the user gives an explicit "yes" to the restat.
- Do NOT ask more than one question per message.
- Do NOT write code or invoke other skills.
- Do NOT proceed past 03-confirm.md until the restat has been explicitly confirmed.
- Do NOT print full file contents (DESIGN.md, SESSION.md, git output, command logs) in the conversation unless the user explicitly asks to see them.
- Do NOT restate the full interview history or the full restat more than once per confirmation cycle.
