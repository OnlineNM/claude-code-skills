---
name: plan
description: Transforms a DESIGN.md or ISSUE-N.md into a concrete TDD implementation plan saved as docs/<idea-slug>-PLAN.md (or PLAN-N.md for issues). Enters plan-mode, invokes writing-plans, stops before execution. Use when user says "plan me", "plan this", "make a plan from", or wants to turn a spec or issue into a step-by-step implementation plan.
---

# Plan-Me — Spec or Issue to Implementation Plan

Reads a DESIGN.md or ISSUE-N.md file and produces a TDD implementation plan saved locally. Stops before execution.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **high thinking effort** (`ultrathink`) for all reasoning in this skill.

## Invocation

Pass the input file path explicitly:

> `/plan-me docs/<idea-slug>-DESIGN.md`
> `/plan-me docs/<idea-slug>-ISSUE-N.md`

If no path is provided, stop and ask: *"Please specify the input file path, e.g. `docs/auth-forms-DESIGN.md` or `docs/auth-forms-ISSUE-1.md`."*

## Before Starting

Tell the user: *"Please run `/clear` first to start with a clean context, then re-invoke this skill."*
If the user has already cleared, proceed.

## Process

### Step 1 — Read the input file

Read the file at the provided path. If it does not exist, stop and tell the user.

Extract `<idea-slug>` and determine the output path:
- `docs/auth-forms-DESIGN.md` → slug = `auth-forms`, output = `docs/auth-forms-PLAN.md`
- `docs/auth-forms-ISSUE-1.md` → slug = `auth-forms`, issue = `1`, output = `docs/auth-forms-PLAN-1.md`

### Step 2 — Enter plan-mode

Call `EnterPlanMode` immediately. All work happens in plan-mode to prevent accidental execution.

### Step 3 — Run writing-plans

Use the `Skill` tool to invoke `superpowers:writing-plans` with these overrides:

> **OVERRIDE 1 — input:** The feature description comes from the file read in Step 1, not from conversation context.
>
> **OVERRIDE 2 — output:** Save the final plan to `docs/<idea-slug>-PLAN.md` (or `docs/<idea-slug>-PLAN-N.md` for an issue input). Do NOT use the default plan file location.
>
> **OVERRIDE 3 — tests:** For each implementation step, include the specific tests or verification commands that confirm that step is complete. Write tests before implementation code (TDD order).
>
> **OVERRIDE 4 — terminal state:** Stop after the plan is written and approved. Do NOT proceed to `executing-plans` or any implementation step.
>
> **OVERRIDE 6 — agentic worker instruction:** In the generated plan document, replace any "For agentic workers" line with exactly:
> `**For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task. Each task must follow superpowers:test-driven-development.`
> Do NOT mention superpowers:executing-plans anywhere in the plan.
>
> **OVERRIDE 5 — plan writing & review:** When the plan is ready to be written:
> 1. Write it directly to `docs/<idea-slug>-PLAN.md` (or `PLAN-N.md`) without displaying its full content in the console. Just confirm the path.
> 2. Tell the user: *"Plan written to `docs/<idea-slug>-PLAN.md`. Please review it and let me know if you have any changes or if you approve."*
> 3. If the user provides feedback, update the file accordingly and ask again.
> 4. When the user explicitly approves (e.g. "looks good", "approve", "done", "ok"), return control — do NOT commit here.

Follow every other writing-plans step as written.

### Step 4 — Commit

After `writing-plans` returns (user has approved the plan):

1. `git add docs/<idea-slug>-PLAN.md` (or `PLAN-N.md`)
2. `git commit -m "docs: add implementation plan for <idea-slug>"`

Do NOT push. Do NOT skip this step. Do NOT wait for additional user input — approval in Step 3 is sufficient.

### Step 5 — Confirm stop

After committing, say:

> *"Plan saved to `docs/<idea-slug>-PLAN.md`. To implement, run `/implement` with the plan file path."*

## Output

- `docs/<idea-slug>-PLAN.md` — TDD implementation plan derived from a DESIGN.md
- `docs/<idea-slug>-PLAN-N.md` — TDD implementation plan for a single vertical slice, derived from an ISSUE-N.md

## Hard Rules

- Do NOT invoke `executing-plans` or any implementation skill.
- Do NOT write code.
- Do NOT start executing — that is the user's decision in a new session.
- Always read the input file before invoking writing-plans.
- Always commit after user approves — do NOT skip Step 4. Do NOT push.
