# SDD Skill Improvements Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task. Each task must follow superpowers:test-driven-development.

**Goal:** Modularize `discover`, `ideate`, and `prd` into step-files; add "propose default, then confirm" interaction style to `discover`, `ideate`, `design-brainstorm`; add upfront granularity choice to `plan` and `prd`; add a "what vs how" scope boundary to `prd`'s PRD.md output — all within `plugins/spec-driven-development/skills/`.

**Architecture:** Pure documentation/skill-content restructuring. No code, no new tools, no new output formats. `discover` is modularized and dry-run validated first (staged rollout gate); `ideate` and `prd` are modularized only after that gate passes. `design-brainstorm` and `plan` keep their monolithic SKILL.md and get targeted text insertions instead.

**Tech Stack:** Markdown skill files (SKILL.md, steps/*.md) under the Claude Code plugin skill format.

## Global Constraints

- Base commit SHA must be recorded before any skill file edit (Task 0).
- Moved content must be verbatim from the pre-split monolithic SKILL.md — structural move only, not a rewrite. Permitted deltas: new Reads/Does/Checkpoint invariants/Stop condition/Hands-off framing, plus the specific Item 2–4 text additions.
- No `AskUserQuestion` tool dependency — interaction stays chat-text based.
- No changes to `design-adversarial`, `design-review`, `adversarial`, `implement`, `verify`, `finalize`.
- No changes to `superpowers:brainstorming` or `superpowers:writing-plans` themselves — only to override blocks `design-brainstorm`/`plan` pass into them.
- "What vs how" boundary applies to PRD.md only, not ISSUE-N.md or DESIGN.md.
- Staged rollout: `ideate`/`prd` modularization (Tasks 4–5) may not begin until Task 3's dry-run gate is explicitly approved by the user.

---

### Task 0: Record base commit and verify branch state

**Files:** None (verification only).

- [ ] **Step 1: Confirm branch and clean state**

Run: `git branch --show-current && git status --short`
Expected: `feature/sdd-skill-improvements` printed, no status lines (clean tree).

- [ ] **Step 2: Record base SHA**

Run: `git rev-parse HEAD`
Expected: a commit SHA. Write it down — call it `<BASE_SHA>`. Every later verification task diffs against `git show <BASE_SHA>:<path>`.

- [ ] **Step 3: Snapshot pre-split SKILL.md content for discover**

Run: `git show <BASE_SHA>:plugins/spec-driven-development/skills/discover/SKILL.md > /tmp/discover-base.md`
Expected: file created, 162 lines.

---

### Task 1: Modularize `discover` into step-files (Item 1 + Item 2 inline)

**Files:**
- Create: `plugins/spec-driven-development/skills/discover/steps/00-setup.md`
- Create: `plugins/spec-driven-development/skills/discover/steps/01-slug-and-branch.md`
- Create: `plugins/spec-driven-development/skills/discover/steps/02-interview.md`
- Create: `plugins/spec-driven-development/skills/discover/steps/03-confirm.md`
- Create: `plugins/spec-driven-development/skills/discover/steps/04-write-and-handoff.md`
- Modify: `plugins/spec-driven-development/skills/discover/SKILL.md`

**Interfaces:**
- Consumes: `/tmp/discover-base.md` (Task 0 snapshot) as the verbatim source for moved content.
- Produces: `docs/<idea-slug>-SESSION.md` and `docs/<idea-slug>-INTENT.md` (unchanged output contract — same file shapes as before).

- [ ] **Step 1: Write verification script before content move**

Create a throwaway check script the engineer runs after each step file is written:

```bash
# verify-discover-split.sh
set -e
echo "--- checking no old step-number refs remain in SKILL.md ---"
if grep -nE "Step [0-9]" plugins/spec-driven-development/skills/discover/SKILL.md; then
  echo "FAIL: old step-number reference found in trimmed SKILL.md"; exit 1
fi
echo "--- checking all 5 step files exist ---"
for f in 00-setup 01-slug-and-branch 02-interview 03-confirm 04-write-and-handoff; do
  test -f "plugins/spec-driven-development/skills/discover/steps/${f}.md" || { echo "FAIL: missing ${f}.md"; exit 1; }
done
echo "--- checking step files read in numeric order instruction present ---"
grep -q "in numeric order" plugins/spec-driven-development/skills/discover/SKILL.md || { echo "FAIL: missing numeric-order instruction"; exit 1; }
echo "PASS"
```

Run: `bash verify-discover-split.sh` now — expected FAIL (`missing 00-setup.md`), confirming the check actually detects absence before content exists.

- [ ] **Step 2: Create `steps/00-setup.md`**

Source: `/tmp/discover-base.md` Step 1 (git dirty-state check, lines 25-27) + Step 2 (enter plan-mode, lines 29-31).

```markdown
# Step 00 — Setup

**Reads:** Nothing — this is the first step.

**Does:**

### Git dirty-state check

Run `git status`. If there are any uncommitted, unstaged, or untracked files, tell the user to commit or stash changes before proceeding. Do NOT continue.

### Enter plan-mode

Call `EnterPlanMode` immediately. All work happens in plan-mode.

**Stop condition:** `git status` is clean AND plan-mode is active.

**Hands off:** Clean working tree, plan-mode active, control to `01-slug-and-branch.md`.
```

- [ ] **Step 3: Create `steps/01-slug-and-branch.md`**

Source: `/tmp/discover-base.md` Step 3 (Checkpoints 1-3, lines 33-74).

```markdown
# Step 01 — Slug and Branch

**Reads:** Nothing new — continues from `00-setup.md`.

**Does:**

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

**Checkpoint invariant:** If `docs/<idea-slug>-SESSION.md` already exists, read it and resume — skip decisions already settled. Do not re-ask Checkpoint 1 or 2 if the session file shows them already resolved.

#### ⛔ CHECKPOINT 3 — Branch strategy (MANDATORY, do not skip)

Present exactly these three options and ask the user to choose one:
- **1. main** — work directly on the current branch
- **2. branch** — create and switch to `feature/<idea-slug>`
- **3. worktree** — create a git worktree at `../<idea-slug>` on branch `feature/<idea-slug>` (isolated workspace)

After the user picks, invoke `superpowers:using-git-worktrees` if option 3 was chosen.

**Stop condition:** Slug confirmed, session file created/resumed, branch strategy chosen and applied.

**Hands off:** Confirmed `<idea-slug>`, an existing or freshly created `docs/<idea-slug>-SESSION.md`, and the chosen workspace (main/branch/worktree) to `02-interview.md`.
```

- [ ] **Step 4: Create `steps/02-interview.md` with Item 2 Interaction Style inline**

Source: `/tmp/discover-base.md` Step 4 (lines 76-97), plus new Interaction Style section and `GUESS:` clarification from the design (Item 2).

```markdown
# Step 02 — Interview Loop

**Reads:** `<idea-slug>` and `docs/<idea-slug>-SESSION.md` from `01-slug-and-branch.md`.

**Does:**

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

## Interaction Style

Where a reasonable default can be inferred from context already gathered, propose it and ask for confirmation or correction, instead of asking an open question. State the default plainly, e.g.: "Default: <X>. Confirm or tell me what to change." Reserve fully open questions for inputs with no inferable default (e.g. the raw idea description, the problem statement, or the first question of an interview before any context exists). This does not relax any existing explicit-confirmation requirement: a default still requires a clear yes or an explicit alternative choice from the user — passive agreement ("sounds good", "whatever you think") is still rejected per the restat rule in `03-confirm.md`, and the same standard applies wherever this style is used.

This interview loop keeps "one question per message" as a hard rule. The default-proposal style applies to the `GUESS:` line already present in the format — `GUESS:` should commit to a specific default the user can simply confirm, not a vague restatement.

**Stop condition:** You can confidently predict the user's reaction to the next three questions you would ask.

**Hands off:** A set of confirmed answers (recorded in `docs/<idea-slug>-SESSION.md` under Decisions Reached) to `03-confirm.md`.
```

- [ ] **Step 5: Create `steps/03-confirm.md`**

Source: `/tmp/discover-base.md` Step 5 (lines 99-112).

```markdown
# Step 03 — Confirm Restat

**Reads:** Confirmed interview answers from `02-interview.md`.

**Does:**

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

**Stop condition:** Explicit "yes" received on the restat.

**Hands off:** The confirmed restat structure to `04-write-and-handoff.md`.
```

- [ ] **Step 6: Create `steps/04-write-and-handoff.md`**

Source: `/tmp/discover-base.md` Step 6 (lines 114-139) + Step 7 (lines 141-146) + Step 8 (lines 148-150).

```markdown
# Step 04 — Write INTENT.md, Commit, Handoff

**Reads:** Confirmed restat from `03-confirm.md`.

**Does:**

### Write INTENT.md

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

### Commit

```bash
git add docs/<idea-slug>-INTENT.md docs/<idea-slug>-SESSION.md
git commit -m "docs: <idea-slug> intent confirmed"
```

### Handoff

Say: *"Intent confirmed and saved to `docs/<idea-slug>-INTENT.md`. Run `/sdd:ideate docs/<idea-slug>-INTENT.md` to explore solutions, or `/sdd:design-brainstorm docs/<idea-slug>-INTENT.md` to go straight to spec."*

**Stop condition:** INTENT.md written and committed.

**Hands off:** Terminal step — control returns to the user.
```

- [ ] **Step 7: Trim `SKILL.md` to step-file index**

Replace the `## Process` section (current lines 23-150) with:

```markdown
## Process

Read and follow each file in `steps/` **in numeric order**. Each step file is mandatory context, not optional background — do not skip a step file or rely on the index summary alone.

1. `steps/00-setup.md` — git dirty-state check, enter plan-mode
2. `steps/01-slug-and-branch.md` — slug confirmation, session file, branch strategy (Checkpoints 1-3)
3. `steps/02-interview.md` — structured interview loop
4. `steps/03-confirm.md` — present and confirm the restat
5. `steps/04-write-and-handoff.md` — write INTENT.md, commit, handoff
```

Keep frontmatter, the title/overview paragraph, `## Model & Thinking`, `## Language`, `## Before Starting` unchanged. Keep `## Output` and `## Hard Rules` unchanged in content, but rewrite any old step-number reference:

- `"Do NOT write docs/<idea-slug>-INTENT.md before the user gives an explicit 'yes' to the restat."` — unchanged (no step number).
- `"Do NOT proceed past Step 5 until the restat has been explicitly confirmed."` → `"Do NOT proceed past 03-confirm.md until the restat has been explicitly confirmed."`

- [ ] **Step 8: Run verification script**

Run: `bash verify-discover-split.sh`
Expected: `PASS`

- [ ] **Step 9: Diff moved content against base snapshot**

Run:
```bash
for f in 00-setup 01-slug-and-branch 02-interview 03-confirm 04-write-and-handoff; do
  echo "=== $f ==="
  diff <(grep -v -E "^(# Step|^\*\*Reads|^\*\*Does|^\*\*Stop condition|^\*\*Hands off|^\*\*Checkpoint invariant)" "plugins/spec-driven-development/skills/discover/steps/${f}.md") /tmp/discover-base.md | head -30
done
```
Expected: only the Item 2 Interaction Style block (in `02-interview.md`) and the new framing lines appear as additions — no other content drift. Manually eyeball each diff block; this is a sanity check, not an automated gate (full content reordering makes a strict diff noisy by design).

- [ ] **Step 10: Commit**

```bash
git add plugins/spec-driven-development/skills/discover/
git commit -m "docs: modularize discover skill into step-files, add Interaction Style"
```

---

### Task 2: Dry-run `discover` end-to-end (staged rollout gate)

**Files:** None — this is a live skill invocation, not a file edit.

- [ ] **Step 1: Invoke discover on a trivial throwaway description**

Run the `discover` skill (via `/sdd:discover` or equivalent) with a deliberately trivial, low-stakes feature description (e.g. "add a `--verbose` flag to a CLI script"). Walk through `00-setup.md` → `01-slug-and-branch.md` → `02-interview.md`.

- [ ] **Step 2: Deliberately interrupt mid-flow**

Mid-interview (after at least one confirmed answer is recorded in the session file's Decisions Reached), stop the session (simulate compaction/restart by re-invoking discover fresh, pointing at the same slug).

- [ ] **Step 3: Verify session-file resume**

Confirm `01-slug-and-branch.md`'s Checkpoint invariant fires correctly: re-invocation reads `docs/<throwaway-slug>-SESSION.md`, does not re-ask Checkpoint 1/2, and resumes the interview from where it left off without re-litigating already-confirmed decisions.

- [ ] **Step 4: Complete the flow**

Continue through `02-interview.md` → `03-confirm.md` → `04-write-and-handoff.md`. Confirm `docs/<throwaway-slug>-INTENT.md` is written with the expected structure and committed.

- [ ] **Step 5: Clean up throwaway artifacts**

```bash
git log --oneline -1   # note the throwaway commit
git revert --no-edit HEAD   # revert the throwaway INTENT.md/SESSION.md commit
```

- [ ] **Step 6: Gate — require explicit user approval**

Report the dry-run results to the user (setup ✅, checkpoints ✅, interview loop ✅, restat confirmation ✅, write+commit ✅, mid-flow interruption + resume ✅). **Do not proceed to Task 3 until the user explicitly approves moving on to `ideate`/`prd` modularization.** Both the full exercise AND explicit approval are required — neither alone is sufficient.

---

### Task 3: Modularize `ideate` into step-files (Item 1 + Item 2 inline)

**Gate:** Do not start until Task 2's user approval is received.

**Files:**
- Create: `plugins/spec-driven-development/skills/ideate/steps/00-setup.md`
- Create: `plugins/spec-driven-development/skills/ideate/steps/01-slug-and-branch.md`
- Create: `plugins/spec-driven-development/skills/ideate/steps/02-read-upstream.md`
- Create: `plugins/spec-driven-development/skills/ideate/steps/03-diverge.md`
- Create: `plugins/spec-driven-development/skills/ideate/steps/04-converge.md`
- Create: `plugins/spec-driven-development/skills/ideate/steps/05-sharpen.md`
- Create: `plugins/spec-driven-development/skills/ideate/steps/06-commit-and-handoff.md`
- Modify: `plugins/spec-driven-development/skills/ideate/SKILL.md`

**Interfaces:**
- Consumes: `git show <BASE_SHA>:plugins/spec-driven-development/skills/ideate/SKILL.md` as verbatim source.
- Produces: `docs/<idea-slug>-SESSION.md`, `docs/<idea-slug>-IDEATE.md` (unchanged contract).

- [ ] **Step 1: Snapshot pre-split content**

Run: `git show <BASE_SHA>:plugins/spec-driven-development/skills/ideate/SKILL.md > /tmp/ideate-base.md`

- [ ] **Step 2: Write verification script**

```bash
# verify-ideate-split.sh
set -e
if grep -nE "Step [0-9]" plugins/spec-driven-development/skills/ideate/SKILL.md; then
  echo "FAIL: old step-number reference in trimmed SKILL.md"; exit 1
fi
for f in 00-setup 01-slug-and-branch 02-read-upstream 03-diverge 04-converge 05-sharpen 06-commit-and-handoff; do
  test -f "plugins/spec-driven-development/skills/ideate/steps/${f}.md" || { echo "FAIL: missing ${f}.md"; exit 1; }
done
grep -q "in numeric order" plugins/spec-driven-development/skills/ideate/SKILL.md || { echo "FAIL: missing numeric-order instruction"; exit 1; }
echo "PASS"
```

Run it now — expected FAIL.

- [ ] **Step 3: Create `steps/00-setup.md`**

Source: `/tmp/ideate-base.md` Step 0 (lines 32-36).

```markdown
# Step 00 — Setup

**Reads:** Nothing — first step.

**Does:**

Run `git status`. If there are any uncommitted, unstaged, or untracked files, tell the user to commit or stash before proceeding.

Call `EnterPlanMode` immediately.

**Stop condition:** Clean tree, plan-mode active.

**Hands off:** Control to `01-slug-and-branch.md`.
```

- [ ] **Step 4: Create `steps/01-slug-and-branch.md`**

Source: `/tmp/ideate-base.md` Step 1 (lines 38-73).

```markdown
# Step 01 — Slug and Branch

**Reads:** Optional `docs/<slug>-INTENT.md` path passed as invocation argument.

**Does:**

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

**Checkpoint invariant:** If the session file already exists, read it and resume — skip decisions already settled (e.g. a phase already confirmed).

#### Branch detection

Check whether `feature/<idea-slug>` already exists:
- If yes: announce *"Branch `feature/<idea-slug>` detected — reusing it."* Switch to it.
- If no: run **CHECKPOINT 3** — present exactly these three options and ask the user to choose one:
  - **1. main** — work directly on the current branch
  - **2. branch** — create and switch to `feature/<idea-slug>`
  - **3. worktree** — create a git worktree at `../<idea-slug>` on branch `feature/<idea-slug>` (isolated workspace)

  After the user picks, invoke `superpowers:using-git-worktrees` if option 3 was chosen.

**Stop condition:** Slug confirmed, session file ready, branch resolved.

**Hands off:** Confirmed `<idea-slug>` and workspace state to `02-read-upstream.md`.
```

- [ ] **Step 5: Create `steps/02-read-upstream.md`**

Source: `/tmp/ideate-base.md` Step 2 (lines 75-80).

```markdown
# Step 02 — Read Upstream Artifact

**Reads:** `<idea-slug>` from `01-slug-and-branch.md`; optional `docs/<slug>-INTENT.md`.

**Does:**

If an INTENT.md path was passed, read it and announce: *"Found `docs/<slug>-INTENT.md` — starting from confirmed intent."*

Use the INTENT.md content as the seed for Phase 1.

**Stop condition:** Upstream content read (or confirmed absent).

**Hands off:** Seed content (or none) to `03-diverge.md`.
```

- [ ] **Step 6: Create `steps/03-diverge.md`**

Source: `/tmp/ideate-base.md` Step 3 / Phase 1 (lines 82-94).

```markdown
# Step 03 — Phase 1: Diverge (Understand & Expand)

**Reads:** Seed content from `02-read-upstream.md` (INTENT.md or raw description).

**Does:**

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

**Stop condition:** 5-8 labeled variations generated, problem framing confirmed.

**Hands off:** The HMW statement and variation set to `04-converge.md`.
```

- [ ] **Step 7: Create `steps/04-converge.md` with Item 2 Interaction Style inline**

Source: `/tmp/ideate-base.md` Step 4 / Phase 2 (lines 96-107), plus Item 2's direction-ranking formalization.

```markdown
# Step 04 — Phase 2: Converge (Evaluate & Narrow)

**Reads:** Variation set from `03-diverge.md`.

**Does:**

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

## Interaction Style

Where a reasonable default can be inferred from context already gathered, propose it and ask for confirmation or correction, instead of asking an open question. State the default plainly, e.g.: "Default: <X>. Confirm or tell me what to change." This does not relax any existing explicit-confirmation requirement: a default still requires a clear yes or an explicit alternative choice from the user — passive agreement is rejected.

Present each direction as "Direction A (default: best fit per stress-test)" rather than three unranked options — formalize that the stress-test result names a default, not just three equally-weighted choices.

**Stop condition:** User confirms which direction to pursue.

**Hands off:** The confirmed direction to `05-sharpen.md`.
```

- [ ] **Step 8: Create `steps/05-sharpen.md`**

Source: `/tmp/ideate-base.md` Step 5 / Phase 3 (lines 109-140).

```markdown
# Step 05 — Phase 3: Sharpen

**Reads:** Confirmed direction from `04-converge.md`.

**Does:**

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

If the user provides feedback, update the file and ask again. When they explicitly approve, proceed.

**Stop condition:** User explicitly approves the IDEATE.md content.

**Hands off:** Approved `docs/<idea-slug>-IDEATE.md` to `06-commit-and-handoff.md`.
```

- [ ] **Step 9: Create `steps/06-commit-and-handoff.md`**

Source: `/tmp/ideate-base.md` Step 6 (lines 142-147) + Step 7 (lines 149-151).

```markdown
# Step 06 — Commit and Handoff

**Reads:** Approved `docs/<idea-slug>-IDEATE.md` from `05-sharpen.md`.

**Does:**

```bash
git add docs/<idea-slug>-IDEATE.md docs/<idea-slug>-SESSION.md
git commit -m "docs: <idea-slug> ideation complete"
```

Say: *"Ideation complete. Run `/sdd:design-brainstorm docs/<idea-slug>-IDEATE.md` to begin the spec."*

**Stop condition:** Committed.

**Hands off:** Terminal step — control returns to the user.
```

- [ ] **Step 10: Trim `SKILL.md` to step-file index**

Replace `## Process` (current lines 30-151) with:

```markdown
## Process

Read and follow each file in `steps/` **in numeric order**. Each step file is mandatory context, not optional background — do not skip a step file or rely on the index summary alone.

1. `steps/00-setup.md` — git dirty-state check, enter plan-mode
2. `steps/01-slug-and-branch.md` — slug confirmation, session file, branch detection (Checkpoints 1-3)
3. `steps/02-read-upstream.md` — read upstream INTENT.md if available
4. `steps/03-diverge.md` — Phase 1: Diverge
5. `steps/04-converge.md` — Phase 2: Converge
6. `steps/05-sharpen.md` — Phase 3: Sharpen, write IDEATE.md
7. `steps/06-commit-and-handoff.md` — commit, handoff
```

Keep frontmatter, overview, `## Model & Thinking`, `## Language`, `## Invocation`, `## Before Starting`, `## Output` unchanged. Update Hard Rules step-number references:

- `"Do NOT skip Phase 1 and 2 and jump straight to Phase 3"` — unchanged (phase names, not step numbers).
- `"Do NOT write docs/<idea-slug>-IDEATE.md before Phase 2 direction is confirmed by the user"` — unchanged.

(No literal "Step N" cross-references exist in ideate's Hard Rules — confirm via grep in Step 11.)

- [ ] **Step 11: Run verification script and diff check**

Run: `bash verify-ideate-split.sh` — expected `PASS`.

Run the same diff-against-base pattern as Task 1 Step 9, substituting `ideate` paths and `/tmp/ideate-base.md`. Confirm only the Item 2 addition in `04-converge.md` and framing lines differ.

- [ ] **Step 12: Commit**

```bash
git add plugins/spec-driven-development/skills/ideate/
git commit -m "docs: modularize ideate skill into step-files, add Interaction Style"
```

---

### Task 4: Modularize `prd` into step-files (Item 1 + Item 3 + Item 4 inline)

**Files:**
- Create: `plugins/spec-driven-development/skills/prd/steps/00-read-and-explore.md`
- Create: `plugins/spec-driven-development/skills/prd/steps/01-seams.md`
- Create: `plugins/spec-driven-development/skills/prd/steps/02-write-prd.md`
- Create: `plugins/spec-driven-development/skills/prd/steps/03-issue-breakdown.md`
- Create: `plugins/spec-driven-development/skills/prd/steps/04-write-issues.md`
- Create: `plugins/spec-driven-development/skills/prd/steps/05-handoff.md`
- Modify: `plugins/spec-driven-development/skills/prd/SKILL.md`

**Interfaces:**
- Consumes: `git show <BASE_SHA>:plugins/spec-driven-development/skills/prd/SKILL.md` as verbatim source.
- Produces: `docs/<idea-slug>-PRD.md`, `docs/<idea-slug>-ISSUE-N.md` files (same shape as before, plus the new Scope Boundary constraint on PRD.md prose).

- [ ] **Step 1: Snapshot pre-split content**

Run: `git show <BASE_SHA>:plugins/spec-driven-development/skills/prd/SKILL.md > /tmp/prd-base.md`

- [ ] **Step 2: Write verification script**

```bash
# verify-prd-split.sh
set -e
if grep -nE "Step [0-9]" plugins/spec-driven-development/skills/prd/SKILL.md; then
  echo "FAIL: old step-number reference in trimmed SKILL.md"; exit 1
fi
for f in 00-read-and-explore 01-seams 02-write-prd 03-issue-breakdown 04-write-issues 05-handoff; do
  test -f "plugins/spec-driven-development/skills/prd/steps/${f}.md" || { echo "FAIL: missing ${f}.md"; exit 1; }
done
grep -q "in numeric order" plugins/spec-driven-development/skills/prd/SKILL.md || { echo "FAIL: missing numeric-order instruction"; exit 1; }
grep -q "Scope Boundary: What, Not How" plugins/spec-driven-development/skills/prd/steps/02-write-prd.md || { echo "FAIL: missing what-vs-how boundary"; exit 1; }
grep -q "Fewer, larger slices" plugins/spec-driven-development/skills/prd/steps/03-issue-breakdown.md || { echo "FAIL: missing upfront granularity choice"; exit 1; }
echo "PASS"
```

Run it now — expected FAIL.

- [ ] **Step 3: Create `steps/00-read-and-explore.md`**

Source: `/tmp/prd-base.md` Step 1 (lines 24-30) + Step 2 (lines 32-34).

```markdown
# Step 00 — Read Spec and Explore Codebase

**Reads:** The DESIGN.md path passed at invocation.

**Does:**

### Read the spec

Read the file at the provided path. Extract `<idea-slug>` from the filename:
- `docs/auth-forms-DESIGN.md` → `idea-slug` = `auth-forms`
- `docs/youtube-funnel-DESIGN.md` → `idea-slug` = `youtube-funnel`

If the file does not exist, stop and tell the user.

### Explore the codebase

Explore the repo to understand current state. Use the project's domain glossary vocabulary throughout. Respect any ADRs in the area being touched.

**Stop condition:** DESIGN.md read, codebase explored.

**Hands off:** `<idea-slug>`, DESIGN.md content, and codebase context to `01-seams.md`.
```

- [ ] **Step 4: Create `steps/01-seams.md`**

Source: `/tmp/prd-base.md` Step 3 (lines 36-40).

```markdown
# Step 01 — Identify Seams

**Reads:** DESIGN.md content and codebase context from `00-read-and-explore.md`.

**Does:**

Sketch out the testing seams for this feature. Prefer existing seams over new ones. Use the highest seam possible.

Check with the user that these seams match their expectations before proceeding.

**Stop condition:** User confirms the seams.

**Hands off:** Confirmed seam list to `02-write-prd.md`.
```

- [ ] **Step 5: Create `steps/02-write-prd.md` with Item 4 Scope Boundary inline**

Source: `/tmp/prd-base.md` Step 4 (lines 42-89), plus Item 4's "What vs How" scope boundary.

```markdown
# Step 02 — Write the PRD

**Reads:** Confirmed seams from `01-seams.md`.

**Does:**

Write directly to `docs/<idea-slug>-PRD.md` without displaying its full content in the console. Just confirm the path. Then tell the user: *"PRD written to `docs/<idea-slug>-PRD.md`. Please review it and let me know if you have any changes before we move on to the issues breakdown."* If the user provides feedback, update the file and ask again. Proceed to `03-issue-breakdown.md` only after the user approves the PRD.

The PRD structure to use:

```markdown
# <Feature Name> — PRD

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

1. As a <actor>, I want <feature>, so that <benefit>

## Implementation Decisions

- Modules that will be built/modified
- Interface changes
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include file paths or code snippets unless a prototype snippet encodes a decision
more precisely than prose (state machine, schema, type shape) — inline it and note it came
from a prototype.

## Testing Decisions

- What makes a good test for this feature
- Which modules will be tested
- Prior art for the tests in the codebase

## Out of Scope

Explicit list of what this PRD does not cover.

## Further Notes

Any additional context.
```

## Scope Boundary: What, Not How

Applies to `docs/<slug>-PRD.md` only — NOT to `docs/<slug>-ISSUE-N.md` files, which may continue to inline a prototype snippet per the existing rule ("unless a prototype snippet encodes a decision more precisely than prose").

In the Problem Statement, Solution, and User Stories sections: no code snippets, no method/function names, no file paths, no internal module names. User-facing or third-party platform/integration names ARE allowed where the user genuinely interacts with them (e.g. "sign in with Google", "export to Notion") — the boundary is *implementation technology* (how it's built), not *product surface* (what the user sees and touches).

Example — disallowed: "calls `validateSession()` in `auth/middleware.ts` using JWT." Example — allowed: "the user stays signed in across page reloads."

The Implementation Decisions section may name modules, schemas, and API contracts per the existing template, but only for contracts that are externally relevant (e.g. a public API shape another team integrates with) — not internal file/module references. Before writing the PRD, scan the draft against this rule and strip violations.

**Stop condition:** User explicitly approves the PRD content (after the Scope Boundary scan).

**Hands off:** Approved `docs/<idea-slug>-PRD.md` to `03-issue-breakdown.md`.
```

- [ ] **Step 6: Create `steps/03-issue-breakdown.md` with Item 3 granularity choice inline**

Source: `/tmp/prd-base.md` Step 5 (lines 91-107), with the current after-the-fact "Does the granularity feel right?" question replaced by Item 3's upfront 3-option pattern.

```markdown
# Step 03 — Draft the Issue Breakdown

**Reads:** Approved `docs/<idea-slug>-PRD.md` from `02-write-prd.md`.

**Does:**

Break the PRD into vertical slices (tracer bullets). Each slice cuts through ALL integration layers end-to-end.

**Before drafting the breakdown**, present exactly these three options and wait for the user's choice — sized for **issue/slice count**, not implementation tasks (task-level granularity belongs to `/sdd:plan`):
- **1. Fewer, larger slices** — fewer handoffs, larger PRs
- **2. Balanced** (default) — one slice per end-to-end user-visible behavior
- **3. More, smaller slices** — maximum AFK-friendly granularity, more sequencing overhead

Then present the proposed breakdown to the user as a numbered list showing: title, type (AFK/HITL), blocked by. Ask:
- Are the dependency relationships correct?
- Should any slices be merged or split, given the chosen granularity?

Iterate until the user approves.

**Slice rules:**
- Each slice delivers a narrow but complete path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- AFK = implementable by an agent without human interaction
- HITL = requires a human decision or design review
- Prefer many thin slices over few thick ones (within the chosen granularity option)

**Stop condition:** User approves the breakdown (granularity option + dependency graph).

**Hands off:** Approved issue list to `04-write-issues.md`.
```

- [ ] **Step 7: Create `steps/04-write-issues.md`**

Source: `/tmp/prd-base.md` Step 6 (lines 109-131).

```markdown
# Step 04 — Write Issue Files

**Reads:** Approved issue list from `03-issue-breakdown.md`.

**Does:**

Write issues in dependency order (blockers first). For each approved issue, write directly to `docs/<idea-slug>-ISSUE-N.md` without displaying its full content in the console. After all files are written, tell the user: *"N issue files written to `docs/<idea-slug>-ISSUE-1.md` … `docs/<idea-slug>-ISSUE-N.md`. Please review them and let me know if you have any changes or if you approve."* If the user provides feedback, update the relevant files and ask again. Only commit all docs (PRD + issues) to git when the user **explicitly approves** (e.g. "looks good", "approve", "done", "ok"). Do NOT commit automatically.

Issue structure:

```markdown
# <Feature Name> — Issue N: <Title>

**Type:** AFK / HITL
**Blocked by:** None / `<idea-slug>-ISSUE-N.md`

## What to build

Concise description of this vertical slice — end-to-end behavior, not layer-by-layer.
Avoid file paths or code snippets unless a prototype snippet encodes a decision more
precisely than prose — inline it and note it came from a prototype.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
```

**Stop condition:** User explicitly approves all issue files; PRD + issues committed.

**Hands off:** Committed PRD and issue files to `05-handoff.md`.
```

- [ ] **Step 8: Create `steps/05-handoff.md`**

Source: `/tmp/prd-base.md` Step 7 (lines 133-136).

```markdown
# Step 05 — Confirm

**Reads:** Commit confirmation from `04-write-issues.md`.

**Does:**

After the commit, tell the user:
> *"PRD and issues committed. To implement, pass each issue file to `/plan-me`."*

**Stop condition:** Message delivered.

**Hands off:** Terminal step — control returns to the user.
```

- [ ] **Step 9: Trim `SKILL.md` to step-file index**

Replace `## Process` (current lines 22-136) with:

```markdown
## Process

Read and follow each file in `steps/` **in numeric order**. Each step file is mandatory context, not optional background — do not skip a step file or rely on the index summary alone.

1. `steps/00-read-and-explore.md` — read DESIGN.md, explore codebase
2. `steps/01-seams.md` — identify and confirm testing seams
3. `steps/02-write-prd.md` — write PRD.md (Scope Boundary: What, Not How)
4. `steps/03-issue-breakdown.md` — upfront granularity choice, draft issue breakdown
5. `steps/04-write-issues.md` — write issue files, commit
6. `steps/05-handoff.md` — confirm
```

Keep frontmatter, overview, `## Model & Thinking`, `## Invocation`, `## Output` unchanged. Update Hard Rules — no literal "Step N" references exist in prd's Hard Rules (confirm via grep in Step 10); leave as-is if grep finds none.

- [ ] **Step 10: Run verification script and diff check**

Run: `bash verify-prd-split.sh` — expected `PASS`.

Run the diff-against-base pattern (Task 1 Step 9 style) for `prd`, substituting paths and `/tmp/prd-base.md`. Confirm only the Item 3 addition in `03-issue-breakdown.md`, the Item 4 addition in `02-write-prd.md`, and framing lines differ.

- [ ] **Step 11: Commit**

```bash
git add plugins/spec-driven-development/skills/prd/
git commit -m "docs: modularize prd skill into step-files, add granularity choice and scope boundary"
```

---

### Task 5: Add Interaction Style + default-selection override to `design-brainstorm`

**Files:**
- Modify: `plugins/spec-driven-development/skills/design-brainstorm/SKILL.md`

**Interfaces:**
- Consumes: nothing from prior tasks (design-brainstorm is independent, not modularized).
- Produces: an updated override block consumed by `superpowers:brainstorming` at invocation time.

- [ ] **Step 1: Write verification check**

```bash
grep -q "OVERRIDE — default selection" plugins/spec-driven-development/skills/design-brainstorm/SKILL.md || echo "FAIL: missing default-selection override"
grep -q "## Interaction Style" plugins/spec-driven-development/skills/design-brainstorm/SKILL.md || echo "FAIL: missing Interaction Style section"
```

Run it now — expected both FAIL lines.

- [ ] **Step 2: Insert `## Interaction Style` section**

In `plugins/spec-driven-development/skills/design-brainstorm/SKILL.md`, after the existing `## Persistence` section (ends at line 24, before `## Before Starting` at line 26), insert:

```markdown

## Interaction Style

Where a reasonable default can be inferred from context already gathered, propose it and ask for confirmation or correction, instead of asking an open question. State the default plainly, e.g.: "Default: <X>. Confirm or tell me what to change." Reserve fully open questions for inputs with no inferable default (e.g. the raw idea description, the problem statement, or the first question of an interview before any context exists). This does not relax any existing explicit-confirmation requirement: a default still requires a clear yes or an explicit alternative choice from the user — passive agreement ("sounds good", "whatever you think") is still rejected, and the same standard applies wherever this style is used.
```

- [ ] **Step 3: Append the fourth override to Step 4's override list**

In the same file, locate the three existing overrides inside `### Step 4 — Run brainstorming` (currently `OVERRIDE — terminal state`, `OVERRIDE — success criteria`, `OVERRIDE — spec writing`, ending around line 123 right before `Follow every other brainstorming step as written:`). Insert a fourth override block immediately after the `OVERRIDE — spec writing` block and before the "Follow every other brainstorming step..." line:

```markdown

> **OVERRIDE — default selection:** When presenting 2-3 approaches, mark one as "(Recommended)" with a one-line reason, consistent with this project's `AskUserQuestion`-style default-first convention.
```

- [ ] **Step 4: Run verification check**

Run the Step 1 grep commands again — expected no FAIL output (both greps succeed silently).

- [ ] **Step 5: Commit**

```bash
git add plugins/spec-driven-development/skills/design-brainstorm/SKILL.md
git commit -m "docs: add Interaction Style and default-selection override to design-brainstorm"
```

---

### Task 6: Add granularity choice (OVERRIDE 7) to `plan`

**Files:**
- Modify: `plugins/spec-driven-development/skills/plan/SKILL.md`

**Interfaces:**
- Consumes: nothing from prior tasks (plan is independent, not modularized).
- Produces: OVERRIDE 7 text consumed by `superpowers:writing-plans` at invocation time.

- [ ] **Step 1: Write verification check**

```bash
grep -q "OVERRIDE 7 — granularity" plugins/spec-driven-development/skills/plan/SKILL.md || echo "FAIL: missing OVERRIDE 7"
grep -q "implementation tasks" plugins/spec-driven-development/skills/plan/SKILL.md || echo "FAIL: missing ISSUE-N.md task-wording distinction"
```

Run it now — expected both FAIL lines.

- [ ] **Step 2: Insert OVERRIDE 7 after OVERRIDE 6**

In `plugins/spec-driven-development/skills/plan/SKILL.md`, locate `### Step 4 — Run writing-plans`. After the `OVERRIDE 6 — agentic worker instruction` block (currently ends right before `> **OVERRIDE 5 — plan writing & review:**` — note OVERRIDE 5 appears after OVERRIDE 6 in current file order, lines 75-83) and before the `Follow every other writing-plans step as written.` line (line 85), insert:

```markdown

> **OVERRIDE 7 — granularity:** Before writing-plans drafts steps, present exactly these three options in chat and wait for the user's choice:
> - **1. Fewer, larger steps** — faster execution, less intermediate validation
> - **2. Balanced** (default — recommend this unless the input suggests otherwise) — one step per logical unit of work
> - **3. More, smaller steps** — maximum checkpoints, more context-switch overhead
>
> Include the user's choice **verbatim** in the override text handed to `superpowers:writing-plans` (e.g. "OVERRIDE 7 — granularity: the user chose 'Balanced — one step per logical unit of work'; size all plan steps accordingly"), since writing-plans is an invoked skill, not a typed API — the constraint only takes effect if it is literally present in the prompt.
>
> Wording must differ by input type: when the input is `ISSUE-N.md` (already a single vertical slice from `prd`), the three options size **implementation tasks within that slice**, not features — replace "steps" wording with "implementation tasks" in the ISSUE-N.md case to avoid re-litigating PRD-level decomposition.
```

- [ ] **Step 3: Run verification check**

Run the Step 1 grep commands again — expected no FAIL output.

- [ ] **Step 4: Commit**

```bash
git add plugins/spec-driven-development/skills/plan/SKILL.md
git commit -m "docs: add upfront granularity choice override to plan"
```

---

### Task 7: Final structural-fidelity verification

**Files:** None — read-only verification across all modified skills.

- [ ] **Step 1: Verify discover, ideate, prd against base SHA**

For each of the three modularized skills, run the per-task diff check (already executed in Tasks 1/3/4 Step 9-ish) one more time as a combined final pass:

```bash
for skill in discover ideate prd; do
  echo "=== $skill ==="
  git diff <BASE_SHA> -- plugins/spec-driven-development/skills/$skill/ | grep -E "^\+" | grep -vE "^\+\+\+" | grep -viE "reads:|does:|stop condition|hands off|checkpoint invariant|^\+# Step|interaction style|scope boundary|granularity|default can be inferred|in numeric order|^\+\s*$|^\+steps/"
done
```

Expected: each block shows only lines that are clearly part of the Item 2/3/4 text additions (Interaction Style prose, Scope Boundary prose, granularity-choice prose) or step-file index/framing scaffolding — no unexplained content rewrites of moved instructional text.

- [ ] **Step 2: Verify design-brainstorm and plan against base SHA**

```bash
git diff <BASE_SHA> -- plugins/spec-driven-development/skills/design-brainstorm/SKILL.md plugins/spec-driven-development/skills/plan/SKILL.md
```

Expected: diffs show only pure insertions (the Interaction Style section, the fourth override in design-brainstorm; OVERRIDE 7 in plan) — no deletions of existing content, no reordering of unrelated sections.

- [ ] **Step 3: Confirm out-of-scope skills are untouched**

```bash
git diff <BASE_SHA> --stat -- plugins/spec-driven-development/skills/design-adversarial/ plugins/spec-driven-development/skills/design-review/ plugins/spec-driven-development/skills/adversarial/ plugins/spec-driven-development/skills/implement/ plugins/spec-driven-development/skills/verify/ plugins/spec-driven-development/skills/finalize/
```

Expected: empty output (no changes).

- [ ] **Step 4: Final commit (if any cleanup needed)**

If Steps 1-3 reveal no unexpected drift, no further commit is needed — all changes are already committed per-task. If any unexpected drift is found, fix it now and commit:

```bash
git add -A
git commit -m "docs: fix structural drift found in final verification pass"
```

(Skip this step entirely if no drift was found.)

---

## Verification Summary

End-to-end manual verification (no automated test suite exists for skill content, per the design's Risks section):

1. `bash verify-discover-split.sh`, `bash verify-ideate-split.sh`, `bash verify-prd-split.sh` all print `PASS`.
2. Task 2's live dry-run of `discover` completes all 5 step files, exercises the mid-flow interruption/resume path, and produces a valid `docs/<throwaway-slug>-INTENT.md` (then reverted).
3. Task 7's diff-against-base-SHA passes show no unintended content drift in any of the 5 modified/created skill trees.
4. `git diff <BASE_SHA> --stat -- plugins/spec-driven-development/skills/{design-adversarial,design-review,adversarial,implement,verify,finalize}/` is empty.
</content>
