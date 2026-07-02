---
name: ideate
description: Divergent/convergent exploration of the solution space before writing a spec. Use when intent is known but direction is unclear. Reads INTENT.md if available. Produces docs/<slug>-IDEATE.md. Handoff goes to sdd:design-adversarial.
---

# Ideate — Solution Space Exploration

Answers "how might this look?" through three structured phases: diverge, converge, sharpen. Does not write a spec — only narrows direction before design.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **high thinking effort** (`ultrathink`) for all reasoning in this skill.

## Language

Ask all questions in the same language the input document or user description was written in (Romanian or English).

## Invocation

```
/sdd:ideate docs/<slug>-INTENT.md    ← recommended: starts from confirmed intent
/sdd:ideate                           ← no input: derive slug interactively
```

## Before Starting

Tell the user: *"Please run `/clear` first to start with a clean context, then re-invoke this skill."*
If the user has already cleared, proceed.

## Process

Read and follow each file in `steps/` **in numeric order**. Each step file is mandatory context, not optional background — do not skip a step file or rely on the index summary alone.

1. `steps/00-setup.md` — git dirty-state check, enter plan-mode
2. `steps/01-slug-and-branch.md` — slug confirmation, session file, branch detection (Checkpoints 1-3)
3. `steps/02-read-upstream.md` — read upstream INTENT.md if available
4. `steps/03-diverge.md` — Phase 1: Diverge
5. `steps/04-converge.md` — Phase 2: Converge
6. `steps/05-sharpen.md` — Phase 3: Sharpen, write IDEATE.md
7. `steps/06-commit-and-handoff.md` — commit, handoff

## Output

- `docs/<idea-slug>-SESSION.md` — persistent session context
- `docs/<idea-slug>-IDEATE.md` — structured direction document

## Hard Rules

- Do NOT skip Phase 1 and 2 and jump straight to Phase 3
- Do NOT validate weak ideas without pushing back
- Do NOT write `docs/<idea-slug>-IDEATE.md` before Phase 2 direction is confirmed by the user
- Do NOT write code or invoke other skills
