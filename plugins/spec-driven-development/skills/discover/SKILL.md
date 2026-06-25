---
name: discover
description: Extracts confirmed user intent before design. Use when the ask is underspecified ("build me X" without "for whom" or "why now"), when success criteria are missing, or when there is temptation to fill in unspoken assumptions. Produces docs/<slug>-INTENT.md. Handoff goes to sdd:ideate or sdd:design-brainstorm.
---

# Discover — Intent Extraction Before Design

Answers "what do you actually want?" through a structured interview. Does not explore how to build it — only confirms what is being built, for whom, and why now.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **high thinking effort** (`ultrathink`) for all reasoning in this skill.

## Language

Ask all questions in the same language the project/feature description was written in (Romanian or English).

## Before Starting

Tell the user: *"Please run `/clear` first to start with a clean context, then re-invoke this skill."*
If the user has already cleared, proceed.

## Process

### Step 1 — Git dirty-state check

Run `git status`. If there are any uncommitted, unstaged, or untracked files, tell the user to commit or stash changes before proceeding. Do NOT continue.

### Step 2 — Enter plan-mode

Call `EnterPlanMode` immediately. All work happens in plan-mode.

### Step 3 — Identify slug and branch

#### ⛔ CHECKPOINT 1 — Slug approval (MANDATORY, do not skip)

From the user's description, derive `<idea-slug>` using these rules:
- Lowercase, kebab-case
- Only `a-z`, `0-9`, `-`
- Replace spaces and punctuation with `-`
- Collapse multiple `-` into one
- Trim `-` from start and end
- Maximum 40 characters

Propose the slug and **wait for explicit confirmation before continuing**.

#### ⛔ CHECKPOINT 2 — Session file (MANDATORY, do not skip)

Immediately after the slug is confirmed, create `docs/<idea-slug>-SESSION.md`:

```markdown
# Discover: <Idea Name>
Started: <YYYY-MM-DD>

## Summary
<one-paragraph description of what's being discovered>

## Decisions Reached
<!-- updated after each confirmed answer -->

## Open Questions
<!-- updated as new questions surface -->
```

If the file already exists, read it and resume — skip decisions already settled.

#### ⛔ CHECKPOINT 3 — Branch strategy (MANDATORY, do not skip)

Present exactly these three options and ask the user to choose one:
- **1. main** — work directly on the current branch
- **2. branch** — create and switch to `feature/<idea-slug>`
- **3. worktree** — create a git worktree at `../<idea-slug>` on branch `feature/<idea-slug>` (isolated workspace)

After the user picks, invoke `superpowers:using-git-worktrees` if option 3 was chosen.

### Step 4 — Interview loop

Start with a hypothesis, then ask one focused question at a time.

**First message format:**
```
HYPOTHESIS: <one sentence summary of what you think the user wants>
CONFIDENCE: ~X% — missing: <what is still unclear>
```

**Each subsequent question format:**
```
Q: <one focused question>
GUESS: <your current hypothesis with brief reasoning>
```

**Rules:**
- One question per message — never batch multiple questions
- Each question targets the most important unknown
- Push back on vague answers — offer two concrete options if needed

**Stop condition:** You can confidently predict the user's reaction to the next three questions you would ask. At this point, proceed to Step 5.

### Step 5 — Present confirmed restat

Summarize everything confirmed into this structure and **wait for explicit "yes"** before continuing:

```
Outcome:      <one line — what the user wants to achieve>
User:         <one line — who this is for>
Why now:      <one line — why this matters right now>
Success:      <one line — how they'll know it worked>
Constraint:   <one line — the hardest constraint>
Out of scope: <one line — what this explicitly does not include>
```

"Whatever you think" and "sounds good" are NOT a yes. If the user gives a vague confirmation, re-ask by presenting two concrete versions of the restat and asking which is right.

### Step 6 — Write INTENT.md

After explicit "yes", write `docs/<idea-slug>-INTENT.md`:

```markdown
# Intent: <Idea Name>
Confirmed: <YYYY-MM-DD>

## Outcome
<one line>

## User
<one line>

## Why Now
<one line>

## Success Criteria
<one line>

## Constraints
<one line>

## Out of Scope
<one line>
```

### Step 7 — Commit

```bash
git add docs/<idea-slug>-INTENT.md docs/<idea-slug>-SESSION.md
git commit -m "docs: <idea-slug> intent confirmed"
```

### Step 8 — Handoff

Say: *"Intent confirmed and saved to `docs/<idea-slug>-INTENT.md`. Run `/sdd:ideate docs/<idea-slug>-INTENT.md` to explore solutions, or `/sdd:design-brainstorm docs/<idea-slug>-INTENT.md` to go straight to spec."*

## Output

- `docs/<idea-slug>-SESSION.md` — persistent session context
- `docs/<idea-slug>-INTENT.md` — confirmed intent structure

## Hard Rules

- Do NOT write `docs/<idea-slug>-INTENT.md` before the user gives an explicit "yes" to the restat.
- Do NOT ask more than one question per message.
- Do NOT write code or invoke other skills.
- Do NOT proceed past Step 5 until the restat has been explicitly confirmed.
