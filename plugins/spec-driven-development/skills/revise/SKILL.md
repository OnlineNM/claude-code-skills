---
name: revise
description: Confirms and fixes issues reported by sdd:verify's REVISE verdict — updates the plan and issue log, adds regression tests, fixes the implementation, and re-runs the full test suite. Reads the problem from the immediately preceding sdd:verify conversation, or from a pasted problem description. Use right after /sdd:verify returns REVISE, when the user says "fix this", "revise the plan", or pastes a review finding to resolve.
---

# Revise — Fix a REVISE Verdict from Verify

Takes a problem reported by `/sdd:verify` (or pasted directly by the user), confirms it's real against the current codebase, then fixes it: updates the plan, adds a regression test, repairs the implementation, and re-runs the full test suite.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **medium thinking effort** for all reasoning in this skill.

## Language

Conduct all dialogue with the user — status updates, the consolidated report, the recommendation to re-verify — exclusively in Romanian, regardless of the language the problem description was pasted in.

All deliverables this skill writes or updates (`docs/<slug>-PLAN[-N].md`, `docs/<slug>-ISSUE-N-LOG.md`, code, code comments, commit messages) must always be written in English, independent of the Romanian dialogue above. Subagent dispatch prompts (Steps 2a and 2c) also stay in English — they are instructions to other Claude agents, not user-facing dialogue.

## Invocation

> `/sdd:revise`
> `/sdd:revise <pasted problem description>`

No plan file path is required as an argument — the plan is deduced from context (see Step 1). If a problem description is pasted, it is used as-is; otherwise the skill looks at the conversation.

## Before Starting

Unlike other `sdd:*` skills, do **not** ask the user to run `/clear` first. This skill is meant to run in the same session, immediately after `/sdd:verify`, because Step 1 depends on reading the REVISE verdict directly from the conversation. Asking to clear would destroy the only reliable source for the problem list.

## Process

### Step 1 — Gather the problem(s) to fix

Look at the conversation for the most recent `/sdd:verify` REVISE output (the consolidated issue list from its Steps 2–4).

If none is found in context, check whether the user's invocation prompt contains a pasted problem description.

If neither source yields a problem, stop and tell the user explicitly:

> *"I didn't receive any problem to fix. Paste the issue from verify's REVISE output, or run this right after `/sdd:verify` in the same session."*

Also deduce the plan file path (`docs/<slug>-PLAN.md` or `docs/<slug>-PLAN-N.md`) from context — `/sdd:verify`'s own invocation in this conversation references it. If it cannot be deduced, ask the user explicitly: *"Which plan file is this for, e.g. `docs/auth-forms-PLAN.md` or `docs/auth-forms-PLAN-1.md`?"*

### Step 2 — Process each problem, one at a time

Handle problems sequentially — confirm and fix one completely before moving to the next. Do not batch them into a single subagent dispatch.

#### 2a — Confirm the problem is real

Use the `Agent` tool to dispatch a read-only investigation subagent:

> Investigate the current codebase and determine whether the following problem is real:
>
> `<problem description>`
>
> Do NOT modify any files. Report back REAL or NOT REAL, with your reasoning and the specific file/line evidence you found.

#### 2b — If NOT REAL

Report this to the user, clearly stating why the subagent concluded the problem doesn't hold up. Make no changes to the plan, the issue log, the code, or the tests for this problem. Move on to the next problem — do not count this one toward the end-of-run recommendation to re-verify.

#### 2c — If REAL

1. Update the plan file (`docs/<slug>-PLAN[-N].md`) to reflect the fix or the new requirement being made.
2. Use the `Agent` tool to dispatch a fix subagent — same pattern as `sdd:implement`'s Steps 2/4: write a failing regression test first (following `superpowers:test-driven-development`), then fix the implementation to make it pass. Do NOT modify the test to make it pass — fix the implementation instead.
3. If the plan is issue-derived and `docs/<slug>-ISSUE-N-LOG.md` exists, update it:
   - `## Verification` — new status reflecting the fix (e.g. `Verified after fixes`), with a bullet naming what was wrong and what changed.
   - `## What was built` — only if the fix touched files, models, routes, or contracts that a future issue may depend on.
   - Leave `## What's new in the app` untouched unless the fix changed user-facing behavior.

### Step 3 — Run the full test suite

After all problems have been processed, use the `Agent` tool to dispatch a separate testing subagent to run the **full** test suite, including any regression tests added in Step 2c.

If the testing subagent reports failures:
1. Dispatch a new fix subagent with the failure output.
2. Re-dispatch the testing subagent.
3. Repeat until all tests pass.

### Step 4 — Report and recommend next step

Present a consolidated summary:

```
## Revise: <idea-slug>

### Problems addressed
<for each problem: REAL (fixed) or NOT REAL (no changes made), with a one-line reason>

### Test suite
<PASS — all tests including new regression tests, or the fix loop that got it there>
```

Only if at least one problem was confirmed real and fixed, end with:

> *"Run `/sdd:verify` again to validate these fixes."*

If every problem turned out to be a false positive, skip this recommendation — nothing changed that needs re-verification.

## Hard Rules

- Never modify the plan, issue log, code, or tests for a problem the confirmation subagent judged NOT REAL.
- Fixing and testing always happen in dispatched subagents via the `Agent` tool — never inline in the main context.
- Never skip the confirmation step, even when a problem looks obviously real.
- Do NOT ask the user to run `/clear` before this skill — that would destroy the context this skill depends on.
- Do NOT modify tests to make them pass — fix the implementation instead.
- Process problems one at a time — confirm and fully resolve one before starting the next.
