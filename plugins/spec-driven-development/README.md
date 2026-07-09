# spec-driven-development

A plugin of Claude Code skills for hardening plans and designs before writing code. Skills live at `plugins/spec-driven-development/skills/<name>/SKILL.md` and are invoked via the `Skill` tool.

## Workflow

```
design → ideate → spec → prd → plan → implement → verify ⇄ revise → finalize
```

`verify` and `revise` loop: a REVISE verdict from `verify` hands off to `revise`, which fixes confirmed issues and recommends re-running `verify`.

## Skill Catalog

| Skill | Purpose |
|-------|---------|
| `sdd:design` | Extracts confirmed user intent before design — produces `docs/<slug>-DESIGN.md` |
| `sdd:ideate` | Divergent/convergent exploration of solution space — produces `docs/<slug>-IDEATE.md` |
| `spec` | Collaborative spec brainstorming + Codex adversarial review of the spec (Act 1 + Act 2) — produces an approved `SPEC.md` |
| `prd` | Transforms `SPEC.md` into a PRD + `ISSUE-N.md` files |
| `plan` | Transforms `SPEC.md` or `ISSUE-N.md` into a TDD implementation plan saved as `docs/<slug>-PLAN.md` |
| `implement` | Executes a plan file step by step, verifies all tests pass |
| `verify` | Reviews implementation against its plan — produces `PASS` or `REVISE` verdict |
| `revise` | Confirms and fixes issues from a `REVISE` verdict — updates plan/log, adds tests, fixes code, re-runs the suite |
| `finalize` | Commits pending changes and guides the merge/PR flow |

## Codex Review Loop (Act 2) — Prerequisites

- Codex CLI ≥ 0.130: `npm install -g @openai/codex@latest`
- Authenticated: `codex login` (ChatGPT account — Free/Plus/Pro/Max all work)
- Do **not** pin a model in config; ChatGPT-account auth rejects `gpt-5.x-codex` variants

The loop runs until `VERDICT: APPROVED` or the `MAX_ROUNDS` cap is hit. Codex always runs read-only — it never writes files.

## Skill File Structure

Each skill lives at `skills/<name>/SKILL.md` with YAML frontmatter:

```markdown
---
name: skill-name
description: one-line description shown in skill picker
---

Skill body content…
```

Supporting files sit alongside `SKILL.md` in the same directory and are referenced from the skill body.
