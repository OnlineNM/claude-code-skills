---
name: prd
description: Transforms a SPEC.md spec into a PRD document and one markdown file per issue — all saved locally, no GitHub required. The user must pass the SPEC.md path explicitly. Use when user says "prd-me", "create prd from spec", or wants to convert a spec file into a PRD and issues without pushing to GitHub.
---

# PRD-Me — Spec to PRD + Issues

Reads a SPEC.md file and produces a structured PRD and one markdown file per issue.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **medium thinking effort** for all reasoning in this skill.

## Language

Conduct all dialogue with the user — questions, seam confirmations, granularity choices, status updates — exclusively in Romanian, regardless of the language `SPEC.md` was written in.

All deliverables this skill writes (`docs/<idea-slug>-PRD.md`, `docs/<idea-slug>-ISSUE-N.md`, commit messages) must always be written in English, independent of the Romanian dialogue above.

## Invocation

The user must pass the SPEC.md file path explicitly:

> `/prd-me docs/<idea-slug>-SPEC.md`

If no path is provided, stop and ask: *"Please specify the SPEC.md file path, e.g. `docs/auth-forms-SPEC.md`."*

## Output and Context Rules

These rules govern everything this skill prints to the main conversation, across all steps in `steps/`.

- **Never paste full file contents into the chat.** SPEC.md, PRD.md, and ISSUE-N.md are written directly to disk and referenced by path (already the rule in `02-write-prd.md` and `04-write-issues.md`) — extend the same discipline to codebase exploration in `00-read-and-explore.md`: summarize what you found, don't quote whole files.
- **Explore the codebase with targeted reads, not exhaustive ones.** Grep/search for the relevant seams first; read only the files or sections that inform the PRD, not entire directories.
- **Issue and breakdown lists stay compact.** The numbered breakdown in `03-issue-breakdown.md` shows title/type/blocked-by only — no restating of PRD content per issue.
- **Status updates are one line each** ("PRD written to `docs/<idea-slug>-PRD.md`", "3 issue files written") — no recap of prior steps.
- **Default to the minimal useful output.** If unsure how much detail to show in dialogue, show less and offer to expand on request.

## Process

Read and follow each file in `steps/` **one at a time, in numeric order, immediately before executing it** — not all six upfront. Each step file is mandatory context for its own step, not optional background — do not skip a step file or rely on the index summary alone as a substitute for reading it.

1. `steps/00-read-and-explore.md` — read SPEC.md, explore codebase
2. `steps/01-seams.md` — identify and confirm testing seams
3. `steps/02-write-prd.md` — write PRD.md (Scope Boundary: What, Not How)
4. `steps/03-issue-breakdown.md` — upfront granularity choice, draft issue breakdown
5. `steps/04-write-issues.md` — write issue files, commit
6. `steps/05-handoff.md` — confirm

## Output

- `docs/<idea-slug>-PRD.md` — structured PRD
- `docs/<idea-slug>-ISSUE-1.md` … `docs/<idea-slug>-ISSUE-N.md` — one file per vertical slice

## Hard Rules

- Do NOT proceed without reading the SPEC.md file first.
- Do NOT push anything to GitHub.
- Do NOT write code.
- Do NOT invoke `writing-plans` or any implementation skill.
