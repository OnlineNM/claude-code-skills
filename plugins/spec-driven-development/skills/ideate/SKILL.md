---
name: ideate
description: Divergent/convergent exploration of the solution space before writing a spec. Use when intent is known but direction is unclear. Reads DESIGN.md if available. Produces docs/<slug>-IDEATE.md. Handoff goes to sdd:spec.
---

# Ideate — Solution Space Exploration

Answers "how might this look?" through three structured phases: diverge, converge, sharpen. Does not write a spec — only narrows direction before design.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **high thinking effort** (`ultrathink`) for all reasoning in this skill.

## Language

Conduct all dialogue with the user — questions, confirmations, status updates — exclusively in Romanian, regardless of the language the input document or user description was written in.

All deliverables this skill writes (`docs/<idea-slug>-SESSION.md`, `docs/<idea-slug>-IDEATE.md`) must always be written in English. When a confirmed direction is captured in `IDEATE.md`, translate it into English rather than copying the Romanian wording verbatim.

## Invocation

```
/sdd:ideate docs/<slug>-DESIGN.md    ← recommended: starts from confirmed intent
/sdd:ideate                           ← no input: derive slug interactively
```

## Output and Context Rules

This skill generates lists (variations, directions) — the risk here is genuine volume, not just echoed files. Apply these rules throughout:

- Phase 1 (diverge): generate at most 5–8 variations, never more. Each variation is one label + one line — not a paragraph. Do not justify every variation at length; a single sharp sentence per idea is enough.
- Phase 2 (converge): cluster into at most 2–3 directions. Present each direction's stress-test (user value, feasibility, differentiation) and hidden assumptions as short bullets, not prose paragraphs — one line per bullet.
- Phase 3 (sharpen): keep "Recommended Direction" to 2–3 paragraphs max, as already specified in `steps/05-sharpen.md`. Do not restate the full Phase 1/2 history inside IDEATE.md — only the confirmed outcome.
- When reading an upstream `docs/<slug>-DESIGN.md` (`steps/02-read-upstream.md`), do not print its contents back to the user — announce that it was found and used as seed, nothing more.
- After writing `docs/<idea-slug>-IDEATE.md`, do not print its full contents in the console — the review request already points the user at the file path.
- Read files under `steps/` one at a time, immediately before executing that step — not all seven upfront.
- Never dump raw file contents, git output, or command logs into the conversation. State the one-line conclusion instead.
- Between phases, give a one-line status update, not a recap of everything generated so far.
- If ever unsure how much detail to show, default to the shorter option — fewer, sharper items beat an exhaustive list.

## Before Starting

Tell the user: *"Please run `/clear` first to start with a clean context, then re-invoke this skill."*
If the user has already cleared, proceed.

## Process

Read and follow each file in `steps/` **one at a time, in numeric order, immediately before executing it**. Each step file is mandatory context for its own step — do not pre-load later step files, and do not rely on the index summary below as a substitute for reading the step file itself.

1. `steps/00-setup.md` — git dirty-state check, enter plan-mode
2. `steps/01-slug-and-branch.md` — slug confirmation, session file, branch detection (Checkpoints 1-3)
3. `steps/02-read-upstream.md` — read upstream DESIGN.md if available
4. `steps/03-diverge.md` — Phase 1: Diverge
5. `steps/04-converge.md` — Phase 2: Converge
6. `steps/05-sharpen.md` — Phase 3: Sharpen, write IDEATE.md
7. `steps/06-commit-and-handoff.md` — commit, handoff

## Output

- `docs/<idea-slug>-IDEATE.md` — structured direction document. Written once, not echoed back to the user after writing.
- `docs/<idea-slug>-SESSION.md` — scratch file used only to survive context compaction mid-session; deleted (not committed) once IDEATE.md is written. Never printed to the user.

## Hard Rules

- Do NOT skip Phase 1 and 2 and jump straight to Phase 3
- Do NOT validate weak ideas without pushing back
- Do NOT write `docs/<idea-slug>-IDEATE.md` before Phase 2 direction is confirmed by the user
- Do NOT write code or invoke other skills
- Do NOT generate more than 5–8 variations in Phase 1 or more than 2–3 directions in Phase 2
- Do NOT print full file contents (DESIGN.md, IDEATE.md, SESSION.md, git output, command logs) in the conversation unless the user explicitly asks to see them
