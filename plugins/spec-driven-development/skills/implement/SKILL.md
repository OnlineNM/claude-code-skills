---
name: implement
description: Implements a TDD plan from a PLAN.md or PLAN-N.md file. Requires /clear and Bypass Permissions mode before starting. Invokes executing-plans and verifies all tests pass. Use when user says "implement me", "implement this plan", or wants to execute a plan file produced by /plan-me.
---

# Implement-Me — Plan to Working Code

Reads a PLAN.md or PLAN-N.md file and implements it step by step, verifying tests after each step.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **medium thinking effort** for all reasoning in this skill.

## Invocation

Pass the plan file path explicitly:

> `/implement-me docs/<idea-slug>-PLAN.md`
> `/implement-me docs/<idea-slug>-PLAN-N.md`

If no path is provided, stop and ask: *"Please specify the plan file path, e.g. `docs/auth-forms-PLAN.md` or `docs/auth-forms-PLAN-1.md`."*

## Before Starting

One prerequisite that the user must complete manually before re-invoking this skill:

1. **Enable Bypass Permissions** — activate via the shield icon in the Claude Code UI, or pass `--dangerously-skip-permissions` when launching Claude Code from the CLI. This allows uninterrupted execution without permission prompts on every file write or command.

Tell the user:
> *"Before I start: have you enabled Bypass Permissions (shield icon or `--dangerously-skip-permissions`)? Confirm and I'll proceed."*

If the user confirms, proceed. If not, wait.

## Process

### Step 1 — Read the plan file

Read the file at the provided path. If it does not exist, stop and tell the user.

Extract `<idea-slug>` from the filename:
- `docs/auth-forms-PLAN.md` → slug = `auth-forms`
- `docs/auth-forms-PLAN-1.md` → slug = `auth-forms`, plan = `1`

### Step 2 — Dispatch implementation subagent

**Always** dispatch implementation to a subagent — never run it inline, regardless of plan size. A clean, uncontaminated context is required for reliable implementation.

Use the `Agent` tool to spawn a subagent with this prompt (substitute actual plan content):

```
You are implementing a TDD plan. Read this plan carefully and execute it step by step.

<plan>
<PLAN_CONTENT>
</plan>

Instructions:
- Use the `superpowers:subagent-driven-development` skill to implement this plan task-by-task.
- Each task must follow `superpowers:test-driven-development`.
- Do NOT skip any step.
- Do NOT modify tests to make them pass — fix the implementation instead.
- For framework-specific patterns (React hooks, routing, auth, database ORM, etc.), verify against official documentation before implementing.
- After all tasks are complete, run the full test suite and confirm all tests pass.
- Report back: which tasks were completed, which tests passed, and any issues encountered.
```

Replace `<PLAN_CONTENT>` with the full content of the plan file read in Step 1.

Wait for the implementation subagent to complete before proceeding.

### Step 3 — Spec divergence check

After the implementation subagent completes, read `docs/<idea-slug>-DESIGN.md` and run `git diff` to compare the current working tree against the spec.

For each divergence (architectural decision changed, scope adjusted, data model differs from what the spec describes), propose a concrete edit to `docs/<idea-slug>-DESIGN.md`. Present each proposed edit to the user individually and wait for approval or rejection before continuing.

Only after the user has reviewed all proposed spec edits (or confirmed there are none), proceed to the testing subagent.

### Step 4 — Dispatch testing subagent

After the implementation subagent completes, dispatch a **separate** testing subagent — never run tests inline. A separate subagent ensures the test run happens with a clean context, independent of implementation decisions.

Use the `Agent` tool to spawn a subagent with this prompt:

```
You are verifying an implementation against a TDD plan. Do NOT modify any code.

<plan>
<PLAN_CONTENT>
</plan>

Instructions:
- Read the test commands and verification steps defined in the plan above.
- Run every test and verification command.
- Report: which tests passed, which failed (with error output), and an overall PASS / FAIL verdict.
- Do NOT fix anything — only report what you find.
```

Replace `<PLAN_CONTENT>` with the full content of the plan file.

If the testing subagent reports any failures:
1. Spawn a new **fix subagent** using the Agent tool, giving it the failing test output and the plan content. Instruct it to fix only the failing implementation (minimal change, do not alter tests).
2. Re-dispatch the testing subagent.
3. Repeat until all tests pass.

### Step 5 — Confirm

When the testing subagent reports all tests pass, say:

> *"Implementation complete. All tests defined in `docs/<idea-slug>-PLAN.md` pass."*

### Step 6 — Write issue log

Only if the plan file is `docs/<idea-slug>-PLAN-N.md` (an issue-derived plan, not a plain `docs/<idea-slug>-PLAN.md`):

Write `docs/<idea-slug>-ISSUE-N-LOG.md` (overwrite if it already exists — regenerate the whole file, do not merge with a prior version):

```markdown
# Issue N Log: <issue title>

## What's new in the app
<bulleted, non-technical, user-facing capabilities added — scannable by a
non-technical reviewer. If this issue has no user-facing change (infra,
tests, refactor), write "No user-facing change.">

## What was built
<files created/modified, models/schema changes, routes/endpoints added,
public contracts, migrations, and any other decision a future issue may
depend on. Keep concise — target well under ~100 lines unless the issue
genuinely requires more detail.>

## Verification
Not yet verified
```

Base `<issue title>` and the content on the actual final code/worktree state produced by Steps 2–4 — not the plan's intended work — in case implementation diverged from the plan (this is what Step 3's divergence check already surfaces).

If the plan is a plain `docs/<idea-slug>-PLAN.md` (DESIGN- or PRD-derived, no issue number), skip Step 6 entirely — no log file is written.

## Hard Rules

- Do NOT start without user confirmation of Bypass Permissions.
- Do NOT run implementation or tests inline — always dispatch to subagents via the Agent tool.
- Do NOT modify tests to make them pass — fix the implementation instead.
- Do NOT offer to merge, create a PR, or clean up branches/worktrees — that belongs in `/verify`, after the implementation has been validated.
