---
name: prd
description: Transforms a DESIGN.md spec into a PRD document and one markdown file per issue — all saved locally, no GitHub required. The user must pass the DESIGN.md path explicitly. Use when user says "prd-me", "create prd from spec", or wants to convert a spec file into a PRD and issues without pushing to GitHub.
---

# PRD-Me — Spec to PRD + Issues

Reads a DESIGN.md file and produces a structured PRD and one markdown file per issue.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **medium thinking effort** for all reasoning in this skill.

## Language

Conduct all dialogue with the user — questions, seam confirmations, granularity choices, status updates — exclusively in Romanian, regardless of the language `DESIGN.md` was written in.

All deliverables this skill writes (`docs/<idea-slug>-PRD.md`, `docs/<idea-slug>-ISSUE-N.md`, commit messages) must always be written in English, independent of the Romanian dialogue above.

## Dialog Log

Maintain `docs/<idea-slug>-DIALOG.md` throughout the session — a verbatim, human-readable record of the seam confirmation, the PRD feedback rounds, and the issue-breakdown granularity choice and approval. This file is an explicit exception to the English-deliverables rule above: it exists to document the actual Romanian dialogue, so its content stays in Romanian, matching what was really said.

Creation is handled by `steps/00-read-and-explore.md`, right after `<idea-slug>` is derived. Append an entry after each dialogue point in `steps/01-seams.md`, `steps/02-write-prd.md`, and `steps/03-issue-breakdown.md`. Use this format:

```markdown
# Dialog: <Idea Name>
Început: <YYYY-MM-DD>

## <Subiect — ex. "Confirmare seams", "Feedback PRD", "Granularitate issue-uri">

**Întrebare:** <întrebarea/opțiunile prezentate>
**Răspuns:** <răspunsul utilizatorului>

**Decizie:** <ce s-a stabilit, dacă e cazul>

---
```

## Invocation

The user must pass the DESIGN.md file path explicitly:

> `/prd-me docs/<idea-slug>-DESIGN.md`

If no path is provided, stop and ask: *"Please specify the DESIGN.md file path, e.g. `docs/auth-forms-DESIGN.md`."*

## Process

Read and follow each file in `steps/` **in numeric order**. Each step file is mandatory context, not optional background — do not skip a step file or rely on the index summary alone.

1. `steps/00-read-and-explore.md` — read DESIGN.md, explore codebase
2. `steps/01-seams.md` — identify and confirm testing seams
3. `steps/02-write-prd.md` — write PRD.md (Scope Boundary: What, Not How)
4. `steps/03-issue-breakdown.md` — upfront granularity choice, draft issue breakdown
5. `steps/04-write-issues.md` — write issue files, commit
6. `steps/05-handoff.md` — confirm

## Output

- `docs/<idea-slug>-DIALOG.md` — verbatim record of questions asked and decisions made (Romanian)
- `docs/<idea-slug>-PRD.md` — structured PRD
- `docs/<idea-slug>-ISSUE-1.md` … `docs/<idea-slug>-ISSUE-N.md` — one file per vertical slice

## Hard Rules

- Do NOT proceed without reading the DESIGN.md file first.
- Do NOT push anything to GitHub.
- Do NOT write code.
- Do NOT invoke `writing-plans` or any implementation skill.
