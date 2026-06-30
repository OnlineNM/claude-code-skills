---
name: plan
description: Transforms a DESIGN.md, PRD.md, or ISSUE-N.md into a concrete TDD implementation plan saved as docs/<idea-slug>-PLAN.md (or PLAN-N.md for issues). Enters plan-mode, invokes writing-plans, stops before execution. When invoked with a PRD.md or ISSUE-N.md (complex workflow after /prd), first confirms slug and sets up a branch or worktree before planning. Use when user says "plan me", "plan this", "make a plan from", or wants to turn a spec, PRD, or issue into a step-by-step implementation plan.
---

# Plan-Me — Spec, PRD, or Issue to Implementation Plan

Reads a DESIGN.md, PRD.md, or ISSUE-N.md file and produces a TDD implementation plan saved locally. Stops before execution.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **high thinking effort** (`ultrathink`) for all reasoning in this skill.

## Invocation

Pass the input file path explicitly:

> `/plan-me docs/<idea-slug>-DESIGN.md`
> `/plan-me docs/<idea-slug>-PRD.md`
> `/plan-me docs/<idea-slug>-ISSUE-N.md`

If no path is provided, stop and ask: *"Please specify the input file path, e.g. `docs/auth-forms-DESIGN.md`, `docs/auth-forms-PRD.md`, or `docs/auth-forms-ISSUE-1.md`."*

## Before Starting

Tell the user: *"Please run `/clear` first to start with a clean context, then re-invoke this skill."*
If the user has already cleared, proceed.

## Process

### Step 1 — Read the input file

Read the file at the provided path. If it does not exist, stop and tell the user.

Determine the **input type** and extract `<idea-slug>` and the output path:
- `docs/auth-forms-DESIGN.md` → type = DESIGN, slug = `auth-forms`, output = `docs/auth-forms-PLAN.md`
- `docs/auth-forms-PRD.md` → type = PRD, slug = `auth-forms`, output = `docs/auth-forms-PLAN.md`
- `docs/auth-forms-ISSUE-1.md` → type = ISSUE, slug = `auth-forms`, issue = `1`, output = `docs/auth-forms-PLAN-1.md`

### Step 2 — Branch setup (PRD and ISSUE inputs only)

**Skip this step entirely if the input is a DESIGN.md** — the branch or worktree was already established by `/design-brainstorm` or `/design-adversarial`.

When invoked with a PRD.md or ISSUE-N.md, the session is on the main branch because `/prd` merges back before handing off. Before planning, establish the workspace.

#### ⛔ CHECKPOINT 1 — Slug confirmation (MANDATORY, do not skip)

The slug was extracted from the filename. Propose it to the user and **wait for explicit confirmation before continuing**. The user may correct it if the filename doesn't reflect the right slug. Do NOT proceed until the user approves or corrects it.

#### ⛔ CHECKPOINT 2 — Branch strategy (MANDATORY, do not skip)

Present exactly these three options and ask the user to choose one — do not reduce to two:
- **1. main** — plan directly on the current branch
- **2. branch** — create and switch to `feature/<idea-slug>` (or `feature/<idea-slug>-<N>` for an ISSUE input)
- **3. worktree** — create a git worktree at `../<idea-slug>` on branch `feature/<idea-slug>` (isolated workspace, recommended for larger plans)

After the user picks, invoke `superpowers:using-git-worktrees` if option 3 was chosen. Set up the chosen environment before proceeding.

### Step 3 — Enter plan-mode

Call `EnterPlanMode` immediately. All work happens in plan-mode to prevent accidental execution.

### Step 4 — Run writing-plans

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

> **OVERRIDE 7 — granularity:** Before writing-plans drafts steps, present exactly these three options in chat and wait for the user's choice:
> - **1. Fewer, larger steps** — faster execution, less intermediate validation
> - **2. Balanced** (default — recommend this unless the input suggests otherwise) — one step per logical unit of work
> - **3. More, smaller steps** — maximum checkpoints, more context-switch overhead
>
> Include the user's choice **verbatim** in the override text handed to `superpowers:writing-plans` (e.g. "OVERRIDE 7 — granularity: the user chose 'Balanced — one step per logical unit of work'; size all plan steps accordingly"), since writing-plans is an invoked skill, not a typed API — the constraint only takes effect if it is literally present in the prompt.
>
> Wording must differ by input type: when the input is `ISSUE-N.md` (already a single vertical slice from `prd`), the three options size **implementation tasks within that slice**, not features — replace "steps" wording with "implementation tasks" in the ISSUE-N.md case to avoid re-litigating PRD-level decomposition.

Follow every other writing-plans step as written.

### Step 5 — Commit

After `writing-plans` returns (user has approved the plan):

1. `git add docs/<idea-slug>-PLAN.md` (or `PLAN-N.md`)
2. `git commit -m "docs: add implementation plan for <idea-slug>"`

Do NOT push. Do NOT skip this step. Do NOT wait for additional user input — approval in Step 4 is sufficient.

### Step 6 — Confirm stop

After committing, say:

> *"Plan saved to `docs/<idea-slug>-PLAN.md`. To implement, run `/implement` with the plan file path."*

⛔ **HARD STOP — do not continue past this point.** ExitPlanMode approval is approval of the plan document only — it is NOT authorization to implement. The plan file is the only deliverable of this skill. Return control to the user immediately after Step 6.

## Output

- `docs/<idea-slug>-PLAN.md` — TDD implementation plan derived from a DESIGN.md or PRD.md
- `docs/<idea-slug>-PLAN-N.md` — TDD implementation plan for a single vertical slice, derived from an ISSUE-N.md

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll figure it out as I go" | That's how you get a tangled mess and rework. 10 minutes of planning saves hours. |
| "The tasks are obvious, no need to write them" | Writing tasks surfaces hidden dependencies and forgotten edge cases. |
| "Planning is overhead" | Planning is the task. Implementation without a plan is just typing. |
| "I can hold it all in my head" | Context windows are finite. Written plans survive session boundaries and compaction. |

## Hard Rules

- Do NOT invoke `executing-plans` or any implementation skill.
- Do NOT write code.
- Do NOT start executing — that is the user's decision in a new session.
- Always read the input file before invoking writing-plans.
- Always run Step 2 (branch setup) for PRD and ISSUE inputs — do NOT skip it even if you think the branch already exists.
- Always commit after user approves — do NOT skip Step 5. Do NOT push.
