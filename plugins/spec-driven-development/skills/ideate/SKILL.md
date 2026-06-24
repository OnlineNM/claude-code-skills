---
name: ideate
description: Divergent/convergent exploration of the solution space before writing a spec. Use when intent is known but direction is unclear. Reads INTENT.md if available. Produces docs/<slug>-IDEATE.md. Handoff goes to sdd:design.
---

# Ideate — Solution Space Exploration

Answers "how might this look?" through three structured phases: diverge, converge, sharpen. Does not write a spec — only narrows direction before design.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **high thinking effort** (`ultrathink`) for all reasoning in this skill.

## Language

Ask all questions in the same language the input document or user description was written in (Romanian or English).

## Invocation

```
/sdd:ideate docs/<slug>-INTENT.md    ← recommended: starts from confirmed intent
/sdd:ideate                           ← no input: derive slug interactively
```

## Before Starting

Tell the user: *"Please run `/clear` first to start with a clean context, then re-invoke this skill."*
If the user has already cleared, proceed.

## Process

### Step 0 — Git dirty-state check + Enter plan-mode

Run `git status`. If there are any uncommitted, unstaged, or untracked files, tell the user to commit or stash before proceeding.

Call `EnterPlanMode` immediately.

### Step 1 — Identify slug and branch

#### ⛔ CHECKPOINT 1 — Slug confirmation (MANDATORY, do not skip)

If an INTENT.md path was passed as argument, derive the slug from the filename (e.g. `docs/auth-forms-INTENT.md` → `auth-forms`). Propose it and wait for explicit confirmation.

If no argument was passed, ask the user to describe what they want to explore, then derive the slug from their description. Propose it and wait for confirmation.

#### ⛔ CHECKPOINT 2 — Session file (MANDATORY, do not skip)

Immediately after the slug is confirmed, create or resume `docs/<idea-slug>-SESSION.md`:

```markdown
# Ideate: <Idea Name>
Started: <YYYY-MM-DD>

## Summary
<one-paragraph description of what's being ideated>

## Decisions Reached
<!-- updated after each phase completes -->

## Open Questions
<!-- updated as new questions surface -->
```

#### Branch detection

Check whether `feature/<idea-slug>` already exists:
- If yes: announce *"Branch `feature/<idea-slug>` detected — reusing it."* Switch to it.
- If no: run **CHECKPOINT 3** — present the same three options as `sdd:discover` (main / branch / worktree) and set up the chosen environment.

### Step 2 — Read upstream artifact (if available)

If an INTENT.md path was passed, read it and announce:
*"Found `docs/<slug>-INTENT.md` — starting from confirmed intent."*

Use the INTENT.md content as the seed for Phase 1.

### Step 3 — Phase 1: Diverge (Understand & Expand)

- Reframe the problem as a "How Might We" statement:
  > "How might we [verb] [outcome] for [user] without [constraint]?"
- Ask 3–5 sharpening questions, one at a time, to confirm the problem framing before generating ideas
- Generate 5–8 variations using these lenses (label each):
  - **Inversion** — what if we did the opposite?
  - **Constraint removal** — what if the hardest constraint didn't exist?
  - **Audience shift** — what if the user were completely different?
  - **Simplification** — what is the minimum version?
  - **10× version** — what if this had to be 10× more impactful?
  - **Expert lens** — how would a domain expert approach this?
- Push back on weak ideas with specificity — do not validate every option

### Step 4 — Phase 2: Converge (Evaluate & Narrow)

- Cluster the Phase 1 ideas into 2–3 meaningfully distinct directions
- For each direction, stress-test against:
  - **User value:** painkiller or vitamin?
  - **Feasibility:** what is the hardest part to build?
  - **Differentiation:** why would someone switch to this?
- Surface hidden assumptions for each direction:
  - What we are betting is true (unvalidated)
  - What could kill this idea
  - What we are choosing to ignore, and why that is acceptable for now
- Present the 2–3 directions to the user and ask which to pursue. Wait for confirmation before Phase 3.

### Step 5 — Phase 3: Sharpen

After the user confirms a direction, write `docs/<idea-slug>-IDEATE.md`:

```markdown
# Ideate: <Idea Name>
Date: <YYYY-MM-DD>

## Problem Statement
<"How Might We" framing — one sentence>

## Recommended Direction
<The chosen direction and why — 2–3 paragraphs max>

## Key Assumptions to Validate
- [ ] <Assumption — how to test it>
- [ ] <Assumption — how to test it>

## MVP Scope
<Minimum version that tests the core assumption. What's in, what's out.>

## Not Doing (and Why)
- <Thing> — <reason>
- <Thing> — <reason>

## Open Questions
- <Question that needs answering before building>
```

Tell the user: *"IDEATE.md written to `docs/<idea-slug>-IDEATE.md`. Please review it and let me know if you have any changes or if you approve."*

If the user provides feedback, update the file and ask again. When they explicitly approve, commit.

### Step 6 — Commit

```bash
git add docs/<idea-slug>-IDEATE.md docs/<idea-slug>-SESSION.md
git commit -m "docs: <idea-slug> ideation complete"
```

### Step 7 — Handoff

Say: *"Ideation complete. Run `/sdd:design docs/<idea-slug>-IDEATE.md` to begin the spec."*

## Output

- `docs/<idea-slug>-SESSION.md` — persistent session context
- `docs/<idea-slug>-IDEATE.md` — structured direction document

## Hard Rules

- Do NOT skip Phase 1 and 2 and jump straight to Phase 3
- Do NOT validate weak ideas without pushing back
- Do NOT write `docs/<idea-slug>-IDEATE.md` before Phase 2 direction is confirmed by the user
- Do NOT write code or invoke other skills
