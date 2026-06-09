---
name: verify
description: Reviews an implementation against its plan. Reads a PLAN.md or PLAN-N.md, runs feature-dev:code-reviewer to verify plan compliance, then /codex:review for an independent technical check. Use after /implement-me when user says "review me", "review implementation", or wants to validate that a plan was correctly implemented.
---

# Review-Me — Implementation Review Against Plan

Verifies that the code produced by `/implement-me` correctly implements the plan. Two passes: Claude checks plan compliance, Codex checks technical soundness.

## Invocation

Pass the plan file path explicitly:

> `/review-me docs/<idea-slug>-PLAN.md`
> `/review-me docs/<idea-slug>-PLAN-N.md`

If no path is provided, stop and ask: *"Please specify the plan file path, e.g. `docs/auth-forms-PLAN.md` or `docs/auth-forms-PLAN-1.md`."*

## Before Starting

Tell the user: *"Please run `/clear` first to start with a clean context, then re-invoke this skill."*
If the user has already cleared, proceed.

## Process

### Step 1 — Read the plan file

Read the file at the provided path. If it does not exist, stop and tell the user.

Extract `<idea-slug>` from the filename:
- `docs/auth-forms-PLAN.md` → slug = `auth-forms`
- `docs/auth-forms-PLAN-1.md` → slug = `auth-forms`, plan = `1`

Hold the plan content in context — it is the reference for the review.

### Step 2 — Plan compliance review (Claude)

Use the `Skill` tool to invoke `feature-dev:code-reviewer` with this override:

> **OVERRIDE — focus:** Review the git diff (unstaged changes) against the plan read in Step 1. For each issue found, explicitly state which part of the plan it violates or misses. Ignore issues unrelated to the plan scope.

Report only issues with confidence ≥ 80, as per the skill's standard threshold.

### Step 3 — Technical review (Codex)

Run `/codex:review --wait` to get an independent technical check from Codex on the same working tree.

This pass catches defects that Claude may have missed — it has no plan context and reviews purely for technical correctness.

### Step 4 — Consolidate and report

Present a single consolidated summary:

```
## Review: <idea-slug>-PLAN[-N]

### Plan compliance (Claude)
<issues from Step 2, or "No issues found">

### Technical defects (Codex)
<issues from Step 3, or "No issues found">

### Verdict
PASS — implementation matches the plan and no technical defects found.
  or
REVISE — list of items to fix before the implementation can be considered complete.
```

If the verdict is REVISE, list exactly what needs to be fixed. Do NOT fix anything — that is the user's decision.

### Step 5 — Offer merge and cleanup (PASS only)

Only when the verdict is PASS, ask the user:

> *"The implementation is validated. Would you like to merge and clean up?"*
> - **Yes** — invoke `superpowers:finishing-a-development-branch` to handle merge into main and branch/worktree cleanup.
> - **No** — stop here. Leave the branch/worktree as-is.

Do NOT proceed with merge or cleanup without explicit user confirmation.

## Hard Rules

- Do NOT fix any issues found during review.
- Do NOT invoke `executing-plans` or any implementation skill.
- Always read the plan file before running any review.
- `/codex:review` is standard review — do NOT use `/codex:adversarial-review` (design decisions are already settled at this stage).
