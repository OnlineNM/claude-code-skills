# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A collection of Claude Code skills (slash commands) for hardening plans and designs before writing code. Skills live at the repo root (`<name>/SKILL.md`) and are invoked via the `Skill` tool.

## Skill Catalog

### Workflow (root-level)

| Skill | Purpose |
|-------|---------|
| `design-brainstorm` | Collaborative spec creation via brainstorming — produces an approved `DESIGN.md` |
| `design-adversarial` | `design-brainstorm` + Codex adversarial review of the spec (Act 1 + Act 2) |
| `design-review` | Act 2 only — Codex stress-tests an existing spec |
| `prd` | Transforms `DESIGN.md` into a PRD + `ISSUE-N.md` files |
| `plan` | Transforms `DESIGN.md` or `ISSUE-N.md` into a TDD implementation plan |
| `implement` | Executes a `PLAN.md` step by step, verifies all tests pass |
| `verify` | Reviews implementation against its plan — produces `PASS` or `REVISE` verdict |

## Codex Review Loop (Act 2) — Prerequisites

- Codex CLI ≥ 0.130: `npm install -g @openai/codex@latest`
- Authenticated: `codex login` (ChatGPT account — Free/Plus/Pro/Max all work)
- Do **not** pin a model in config; ChatGPT-account auth rejects `gpt-5.x-codex` variants

The loop writes `PLAN.md` (final plan) and `PLAN-REVIEW-LOG.md` (round-by-round argument). Codex always runs read-only — it never writes files. Default cap is 5 rounds.

## Skill File Structure

Each skill lives at `<name>/SKILL.md` with YAML frontmatter:

```markdown
---
name: skill-name
description: one-line description shown in skill picker
---

Skill body content…
```

Supporting files (e.g. `ADR-FORMAT.md`, `CONTEXT-FORMAT.md`) sit alongside `SKILL.md` in the same directory and are referenced from the skill body.
