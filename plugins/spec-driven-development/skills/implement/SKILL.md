---
name: implement
description: Implements a TDD plan from a PLAN.md or PLAN-N.md file. Requires /clear and Bypass Permissions mode before starting. Invokes executing-plans and verifies all tests pass. Use when user says "implement me", "implement this plan", or wants to execute a plan file produced by /plan-me.
---

# Implement-Me — Plan to Working Code

Reads a PLAN.md or PLAN-N.md file and implements it step by step, verifying tests after each step.

## Invocation

Pass the plan file path explicitly:

> `/implement-me docs/<idea-slug>-PLAN.md`
> `/implement-me docs/<idea-slug>-PLAN-N.md`

If no path is provided, stop and ask: *"Please specify the plan file path, e.g. `docs/auth-forms-PLAN.md` or `docs/auth-forms-PLAN-1.md`."*

## Before Starting

Two prerequisites that the user must complete manually before re-invoking this skill:

1. **Run `/clear`** — start with a clean context so the full context window is available for implementation.
2. **Enable Bypass Permissions** — activate via the shield icon in the Claude Code UI, or pass `--dangerously-skip-permissions` when launching Claude Code from the CLI. This allows uninterrupted execution without permission prompts on every file write or command.

Tell the user:
> *"Before I start: have you run `/clear` and enabled Bypass Permissions (shield icon or `--dangerously-skip-permissions`)? Confirm and I'll proceed."*

If the user confirms, proceed. If not, wait.

## Process

### Step 1 — Read the plan file

Read the file at the provided path. If it does not exist, stop and tell the user.

Extract `<idea-slug>` from the filename:
- `docs/auth-forms-PLAN.md` → slug = `auth-forms`
- `docs/auth-forms-PLAN-1.md` → slug = `auth-forms`, plan = `1`

### Step 2 — Run executing-plans

Use the `Skill` tool to invoke `superpowers:executing-plans` with this override:

> **OVERRIDE — input:** The plan comes from the file read in Step 1, not from conversation context or a default plan file location.

Follow every other executing-plans step as written.

### Step 3 — Verify tests

After executing-plans completes, run all tests defined in the plan file. Every test must pass before declaring the implementation done.

If any test fails:
1. Identify the failing test and its error output.
2. Fix the implementation (minimal change — do not alter the test).
3. Re-run the failing test.
4. Repeat until all tests pass.

### Step 4 — Confirm

When all tests pass, say:

> *"Implementation complete. All tests defined in `docs/<idea-slug>-PLAN.md` pass."*

## Hard Rules

- Do NOT start without user confirmation of `/clear` and Bypass Permissions.
- Do NOT modify tests to make them pass — fix the implementation instead.
- Do NOT skip the test verification step even if executing-plans reports success.
