---
name: design
description: Collaborative spec creation via structured brainstorming — enters plan-mode, runs a full brainstorming interview (one question at a time, 2-3 approaches with trade-offs, optional visual companion), and produces an approved spec document. Stops before implementation planning or any code. Use when user says "spec me", "spec this out", "help me spec", or wants to explore and define a feature before planning implementation.
---

# Spec-Me — Collaborative Spec Creation

Produces a hardened spec through collaborative brainstorming. Stops after the spec is written and user-approved — does NOT proceed to implementation planning or code.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **high thinking effort** (`ultrathink`) for all reasoning in this skill.

## Language

Ask all questions in the same language the project/feature description was written in (Romanian or English). Every question and proposed approach must match that language. Internal reasoning and the spec document may stay in English regardless.

## Persistence

Maintain `docs/<idea-slug>-SESSION.md` throughout the session. Creation is handled by ⛔ CHECKPOINT 2 — this section describes upkeep only.

**During the session:** update `Decisions Reached` and `Open Questions` after each major brainstorming checkpoint (approach chosen, design section approved, etc.) — not necessarily after every message.

**When the spec concludes:** append `## Final Spec Path: docs/<idea-slug>-DESIGN.md` to the session file.

## Before Starting

Tell the user: *"Please run `/clear` first to start with a clean context, then re-invoke this skill."*
If the user has already cleared, proceed.

## Process

### Step 1 — Git dirty-state check
Run `git status`. If there are any uncommitted, unstaged, or untracked files, tell the user to commit or stash changes before proceeding. Do NOT continue.

### Step 2 — Enter plan-mode
Call `EnterPlanMode` immediately. All work happens in plan-mode to prevent accidental implementation.

### Step 3 — Identify idea-slug and branch strategy

#### ⛔ CHECKPOINT 1 — Slug approval (MANDATORY, do not skip)

1. From the user's description, derive `<idea-slug>` using these rules:
   - Lowercase, kebab-case
   - Only `a-z`, `0-9`, `-`
   - Replace spaces and punctuation with `-`
   - Collapse multiple `-` into one
   - Trim `-` from start and end
   - Maximum 40 characters
   
   Propose the slug to the user and **wait for explicit confirmation before continuing**. Do NOT proceed until the user approves or corrects it.

#### ⛔ CHECKPOINT 2 — Session file (MANDATORY, do not skip)

Immediately after the slug is confirmed, create `docs/<idea-slug>-SESSION.md`. Do this **now** — before the branch question, before brainstorming, before anything else. Do not defer or skip this because the session feels "short" or "simple": short sessions still get interrupted by context compaction.

```markdown
# Spec: <Idea Name>
Started: <YYYY-MM-DD>

## Summary
<one-paragraph description of what's being specced>

## Decisions Reached
<!-- updated at each brainstorming checkpoint -->

## Open Questions
<!-- updated as new questions surface -->
```

If the file already exists, read it and resume — skip decisions already settled.

#### ⛔ CHECKPOINT 3 — Branch strategy (MANDATORY, do not skip)

2. Present exactly these three options and ask the user to choose one — do not reduce to two:
   - **1. main** — commit directly to the current branch
   - **2. branch** — create and switch to `feature/<idea-slug>`
   - **3. worktree** — create a git worktree at `../<idea-slug>` on branch `feature/<idea-slug>` (isolated workspace, recommended for longer specs)
   
   After the user picks, invoke `superpowers:using-git-worktrees` if option 3 was chosen.
3. Set up the chosen environment before proceeding.

### Step 4 — Run brainstorming
Invoke `superpowers:brainstorming` and follow it exactly, with **two overrides**:

> **OVERRIDE — terminal state:** The final step of brainstorming normally transitions to `writing-plans`. Do NOT do this. The terminal state for spec-me is the user approving the written spec document. Stop there.

> **OVERRIDE — spec writing:** When the spec is ready to be written:
> 1. Write it directly to `docs/<idea-slug>-DESIGN.md` without displaying its full content in the console. Just confirm the path.
> 2. Tell the user: *"Spec written to `docs/<idea-slug>-DESIGN.md`. Please review it and let me know if you have any changes or if you approve."*
> 3. If the user provides feedback, update the file accordingly and ask again.
> 4. When the user explicitly approves, proceed to Step 5.

Follow every other brainstorming step as written: explore project context, offer visual companion if applicable, ask clarifying questions one at a time, propose 2-3 approaches, present design sections, run the spec self-review.

### Step 5 — Commit and confirm stop
After the user approves the spec, propose a git commit — list the files to be staged and ask for confirmation:
- `docs/<idea-slug>-DESIGN.md`
- `docs/<idea-slug>-SESSION.md` (if it exists)

On confirmation, commit with message `docs: <idea-slug> spec approved`. Do NOT push.

Then output this summary:

```
Title:     <feature title>
Slug:      <idea-slug>
Mode:      Branch | Worktree | Main
Branch:    <branch_name>        (omit if Main)
Worktree:  <worktree_path>      (omit unless Worktree)
Spec file: docs/<idea-slug>-DESIGN.md
```

Then say: *"When you're ready to move to implementation planning, run `/sdd:plan` in a new session (after `/clear`)."*

## Output

- `docs/<idea-slug>-SESSION.md` — sesiune persistentă
- `docs/<idea-slug>-DESIGN.md` — spec-ul final, committed în git

## Hard Rules

- Do NOT invoke `writing-plans`, `executing-plans`, or any implementation skill.
- Do NOT write any code.
- Do NOT suggest next steps beyond pointing to `writing-plans` as the user's choice.
