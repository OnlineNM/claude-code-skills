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

Maintain a session file at `docs/<idea-slug>-SESSION.md` to survive context compaction during long sessions.

**At the start:** check if the file exists. If yes, read it and resume — don't revisit already-settled decisions. If no, create it:
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

**During the session:** update `Decisions Reached` and `Open Questions` after each major brainstorming checkpoint (approach chosen, design section approved, etc.) — not necessarily after every message.

**When the spec concludes:** append `## Final Spec Path: docs/<idea-slug>-DESIGN.md` to the session file.

## Before Starting

Tell the user: *"Please run `/clear` first to start with a clean context, then re-invoke this skill."*
If the user has already cleared, proceed.

## Process

### Step 1 — Enter plan-mode
Call `EnterPlanMode` immediately. All work happens in plan-mode to prevent accidental implementation.

### Step 2 — Identify idea-slug and branch strategy

1. From the user's description, derive `<idea-slug>`: kebab-case, 2-4 words (e.g. `user-auth-flow`). Propose it to the user and **wait for explicit confirmation before continuing**. Do not proceed to point 2 until the user approves or corrects the slug.
2. Present exactly these three options and ask the user to choose one — do not reduce to two:
   - **1. main** — commit directly to the current branch
   - **2. branch** — create and switch to `feature/<idea-slug>`
   - **3. worktree** — create a git worktree at `../<idea-slug>` on branch `feature/<idea-slug>` (isolated workspace, recommended for longer specs)
   
   After the user picks, invoke `superpowers:using-git-worktrees` if option 3 was chosen.
3. Set up the chosen environment before proceeding.

### Step 3 — Run brainstorming
Invoke `superpowers:brainstorming` and follow it exactly, with **two overrides**:

> **OVERRIDE — terminal state:** The final step of brainstorming normally transitions to `writing-plans`. Do NOT do this. The terminal state for spec-me is the user approving the written spec document. Stop there.

> **OVERRIDE — spec writing & commit:** When the spec is ready to be written:
> 1. Write it directly to `docs/<idea-slug>-DESIGN.md` without displaying its full content in the console. Just confirm the path.
> 2. Tell the user: *"Spec written to `docs/<idea-slug>-DESIGN.md`. Please review it and let me know if you have any changes or if you approve."*
> 3. If the user provides feedback, update the file accordingly and ask again.
> 4. Only commit to git when the user **explicitly approves** (e.g. "looks good", "approve", "done", "ok"). Do NOT commit automatically.

Follow every other brainstorming step as written: explore project context, offer visual companion if applicable, ask clarifying questions one at a time, propose 2-3 approaches, present design sections, run the spec self-review.

### Step 4 — Confirm stop
After the user approves the spec, say:

> *"Spec complete and saved to `docs/<idea-slug>-DESIGN.md`. When you're ready to move to implementation planning, run `/writing-plans` in a new session (after `/clear`)."*

## Output

- `docs/<idea-slug>-SESSION.md` — sesiune persistentă
- `docs/<idea-slug>-DESIGN.md` — spec-ul final, committed în git

## Hard Rules

- Do NOT invoke `writing-plans`, `executing-plans`, or any implementation skill.
- Do NOT write any code.
- Do NOT suggest next steps beyond pointing to `writing-plans` as the user's choice.
