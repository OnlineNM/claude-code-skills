---
name: verify
description: Reviews an implementation against its plan. Reads a PLAN.md or PLAN-N.md, runs feature-dev:code-reviewer to verify plan compliance, then /codex:review for an independent technical check. Use after /implement-me when user says "review me", "review implementation", or wants to validate that a plan was correctly implemented.
---

# Review-Me — Implementation Review Against Plan

Verifies that the code produced by `/implement-me` correctly implements the plan. Two passes: Claude checks plan compliance, Codex checks technical soundness.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **medium thinking effort** for all reasoning in this skill.

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

### Step 4 — Definition of Done

Before consolidating results, apply this checklist to the working tree. Each unchecked item is a blocking defect — add it to the REVISE list.

**Correctness**
- [ ] Behavior verified at runtime, not just compiled or typechecked
- [ ] New behavior is covered by tests that fail without the change
- [ ] Existing tests still pass — no regressions

**Quality**
- [ ] No dead code, debug output, or commented-out blocks
- [ ] Changes are scoped to the task — no unrelated code touched
- [ ] Linting and formatting pass

**Integration**
- [ ] Change works with the rest of the system, not just in isolation
- [ ] Backward compatibility considered for any public interface change

**Ship-readiness**
- [ ] Security implications reviewed for any untrusted input or auth handling
- [ ] Rollback path exists for anything risky

### Step 5 — Consolidate and report

Present a single consolidated summary:

```
## Review: <idea-slug>-PLAN[-N]

### Plan compliance (Claude)
<issues from Step 2, or "No issues found">

### Technical defects (Codex)
<issues from Step 3, or "No issues found">

### Definition of Done
<checklist status — list any unchecked items, or "All items checked">

### Verdict
PASS — implementation matches the plan, no technical defects, and all DoD items are checked.
  or
REVISE — list of items to fix before the implementation can be considered complete.
```

If the verdict is REVISE, list exactly what needs to be fixed. Do NOT fix anything — that is the user's decision.

### Step 6 — Update issue log

Only if the plan file is `docs/<idea-slug>-PLAN-N.md` (an issue-derived plan):

1. Check whether `docs/<idea-slug>-ISSUE-N-LOG.md` exists.
2. If it does not exist, do not create one — just include a note in the consolidated report (Step 5's output, as presented to the user) that the expected log was missing (log creation is `sdd:implement`'s job, not this skill's).
3. If it exists, replace only the `## Verification` section's content (leave `## What's new in the app` and `## What was built` untouched). The first line must be exactly one of:
   - `Not yet verified` — should not normally be written here; this step always sets one of the other three.
   - `Verified` — plan compliance confirmed, no technical defects, all DoD items checked (verdict was PASS with nothing to note).
   - `Verified after fixes` — this run's verdict is PASS, but only after issues found during Steps 2–4 were fixed (whether within this same review session or a prior invocation of this skill on the same plan) before the verdict became PASS — this skill itself never fixes anything, per Hard Rules; add bullets describing the fixes clearly enough that "What was built" (left untouched) isn't misleading on its own.
   - `Discrepancies remain` — verdict is REVISE; add at least one bullet naming the discrepancy and the affected file/behavior.
4. Optional bullets after the status line may summarize what was confirmed, what was fixed, or the discrepancies found in Steps 2–4.

### Step 7 — Offer merge and cleanup (PASS only)

Only when the verdict is PASS, ask the user:

> *"The implementation is validated. Would you like to merge and clean up?"*
> - **Yes** — invoke `sdd:finalize` to commit any pending changes and handle merge into main and branch/worktree cleanup.
> - **No** — stop here. Leave the branch/worktree as-is.

Do NOT proceed with merge or cleanup without explicit user confirmation.

## Hard Rules

- Do NOT fix any issues found during review.
- Do NOT invoke `executing-plans` or any implementation skill.
- Always read the plan file before running any review.
- `/codex:review` is standard review — do NOT use `/codex:adversarial-review` (design decisions are already settled at this stage).
- After a REVISE verdict, check whether `docs/<idea-slug>-DESIGN.md` needs updating to reflect decisions made during implementation before re-running verify.
