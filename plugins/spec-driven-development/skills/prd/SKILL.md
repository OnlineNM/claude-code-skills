---
name: prd
description: Transforms a DESIGN.md spec into a PRD document and one markdown file per issue — all saved locally, no GitHub required. The user must pass the DESIGN.md path explicitly. Use when user says "prd-me", "create prd from spec", or wants to convert a spec file into a PRD and issues without pushing to GitHub.
---

# PRD-Me — Spec to PRD + Issues

Reads a DESIGN.md file and produces a structured PRD and one markdown file per issue.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **medium thinking effort** for all reasoning in this skill.

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

- `docs/<idea-slug>-PRD.md` — structured PRD
- `docs/<idea-slug>-ISSUE-1.md` … `docs/<idea-slug>-ISSUE-N.md` — one file per vertical slice

## Hard Rules

- Do NOT proceed without reading the DESIGN.md file first.
- Do NOT push anything to GitHub.
- Do NOT write code.
- Do NOT invoke `writing-plans` or any implementation skill.
