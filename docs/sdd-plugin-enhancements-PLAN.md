# SDD Plugin Enhancements Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task. Each task must follow superpowers:test-driven-development.

**Goal:** Add 2 new skills (`discover`, `ideate`) and 6 additive modifications to existing SDD plugin skills to improve requirement extraction, assumption surfacing, and implementation quality gates.

**Architecture:** All changes are additive edits to existing SKILL.md files plus creation of two new skill directories. No skill is rewritten from scratch. Modifications follow the pipeline order: discover → ideate → design → plan → implement → verify.

**Tech Stack:** Markdown (SKILL.md files), JSON (plugin.json). No runtime dependencies — skill files are read and interpreted by Claude Code.

## Global Constraints

- All changes are **additive** — do NOT remove any existing content from skill files
- Do NOT reference `agent-skills` or any external repository in skill content
- `design-codex` receives identical modifications to `design` (items 1, 2, INTENT/IDEATE detection)
- Base directory for all relative paths below: `plugins/spec-driven-development/` inside the repo root `/Users/lairimia/VSCode/claude-code-skills/`
- Run all commands from `/Users/lairimia/VSCode/claude-code-skills/`

---

### Task 1: Step 4 Enhancements to `design/SKILL.md` — IDEATE/INTENT Detection + Assumptions Block + Success Criteria Override

**Files:**
- Modify: `plugins/spec-driven-development/skills/design/SKILL.md`

**What changes:** In Step 4, replace the opening line
```
### Step 4 — Run brainstorming
Invoke `superpowers:brainstorming` and follow it exactly, with **two overrides**:
```
with an expanded version that (a) detects upstream IDEATE/INTENT artifacts, (b) requires the assumptions block before invoking brainstorming, and (c) adds a third override for success criteria reframing.

The existing two overrides and the trailing "Follow every other brainstorming step as written" line remain unchanged.

- [ ] **Step 1: Verify the target string is present (pre-condition check)**

```bash
grep -n "Run brainstorming" plugins/spec-driven-development/skills/design/SKILL.md
```
Expected: one hit, at the line starting `### Step 4 — Run brainstorming`

- [ ] **Step 2: Verify the new content does NOT yet exist**

```bash
grep -c "IDEATE.md" plugins/spec-driven-development/skills/design/SKILL.md
```
Expected: `0`

- [ ] **Step 3: Apply the edit**

Using Edit tool, replace in `plugins/spec-driven-development/skills/design/SKILL.md`:

Old string (exact):
```
### Step 4 — Run brainstorming
Invoke `superpowers:brainstorming` and follow it exactly, with **two overrides**:
```

New string:
```
### Step 4 — Run brainstorming

**Before brainstorming**, check `docs/` for upstream artifacts from this slug:
1. If `docs/<slug>-IDEATE.md` exists: announce *"Found `docs/<slug>-IDEATE.md` — using it as the starting point for brainstorming."* Start brainstorming from its content instead of the raw user description.
2. Else if `docs/<slug>-INTENT.md` exists: announce *"Found `docs/<slug>-INTENT.md` — using it as the starting point for brainstorming."* Start brainstorming from its content instead of the raw user description.
3. If neither exists: start brainstorming from the user's raw description (current behavior).

**Before invoking brainstorming**, surface all implicit assumptions the user has not stated:

```
ASSUMPTIONS I'M MAKING:
1. [assumption about stack / tech]
2. [assumption about audience]
3. [assumption about constraints or scope]
→ Correct me now or I'll proceed with these.
```

Do not begin brainstorming until the user explicitly confirms or corrects the list.

Invoke `superpowers:brainstorming` and follow it exactly, with **three overrides**:
```

- [ ] **Step 4: Add third override (success criteria reframing) after the existing two overrides**

The existing overrides end with:
```
> **OVERRIDE — spec writing:** When the spec is ready to be written:
```

Add the following BEFORE that override line (after OVERRIDE — terminal state):

Old string:
```
> **OVERRIDE — spec writing:** When the spec is ready to be written:
```

New string:
```
> **OVERRIDE — success criteria:** Whenever the user describes a vague objective (e.g. "make it faster", "improve UX"), reframe it as concrete, measurable success criteria before writing a spec section:
>
> ```
> REQUIREMENT: "Make it faster"
>
> REFRAMED SUCCESS CRITERIA:
> - [specific measurable condition, e.g. "LCP < 2.5s on 4G"]
> - [specific measurable condition]
> → Are these the right targets?
> ```
>
> Do not write a spec section for an objective that cannot be directly verified.

> **OVERRIDE — spec writing:** When the spec is ready to be written:
```

- [ ] **Step 5: Verify the new content exists**

```bash
grep -c "IDEATE.md" plugins/spec-driven-development/skills/design/SKILL.md
grep -c "ASSUMPTIONS I'M MAKING" plugins/spec-driven-development/skills/design/SKILL.md
grep -c "REFRAMED SUCCESS CRITERIA" plugins/spec-driven-development/skills/design/SKILL.md
```
Expected: `1` for each

- [ ] **Step 6: Commit**

```bash
git add plugins/spec-driven-development/skills/design/SKILL.md
git commit -m "feat(sdd): add IDEATE/INTENT detection, assumptions block, success criteria reframing to design"
```

---

### Task 2: Same Step 4 Enhancements to `design-codex/SKILL.md`

**Files:**
- Modify: `plugins/spec-driven-development/skills/design-codex/SKILL.md`

**What changes:** Identical to Task 1, but targeting `design-codex/SKILL.md`. The Step 4 line in this file reads slightly differently so the old/new strings differ.

- [ ] **Step 1: Verify pre-condition**

```bash
grep -c "IDEATE.md" plugins/spec-driven-development/skills/design-codex/SKILL.md
```
Expected: `0`

- [ ] **Step 2: Apply upstream detection + assumptions block**

Using Edit tool, replace in `plugins/spec-driven-development/skills/design-codex/SKILL.md`:

Old string (exact):
```
### Step 4 — Run brainstorming
Invoke `superpowers:brainstorming` with **two overrides**: do NOT invoke `writing-plans` at the end. And do NOT display the spec content in the console or commit automatically — see Step 5.
```

New string:
```
### Step 4 — Run brainstorming

**Before brainstorming**, check `docs/` for upstream artifacts from this slug:
1. If `docs/<slug>-IDEATE.md` exists: announce *"Found `docs/<slug>-IDEATE.md` — using it as the starting point for brainstorming."* Start brainstorming from its content instead of the raw user description.
2. Else if `docs/<slug>-INTENT.md` exists: announce *"Found `docs/<slug>-INTENT.md` — using it as the starting point for brainstorming."* Start brainstorming from its content instead of the raw user description.
3. If neither exists: start brainstorming from the user's raw description (current behavior).

**Before invoking brainstorming**, surface all implicit assumptions the user has not stated:

```
ASSUMPTIONS I'M MAKING:
1. [assumption about stack / tech]
2. [assumption about audience]
3. [assumption about constraints or scope]
→ Correct me now or I'll proceed with these.
```

Do not begin brainstorming until the user explicitly confirms or corrects the list.

**Success criteria override:** Whenever the user describes a vague objective (e.g. "make it faster", "improve UX"), reframe it as concrete, measurable success criteria before writing a spec section:

```
REQUIREMENT: "Make it faster"

REFRAMED SUCCESS CRITERIA:
- [specific measurable condition, e.g. "LCP < 2.5s on 4G"]
- [specific measurable condition]
→ Are these the right targets?
```

Do not write a spec section for an objective that cannot be directly verified.

Invoke `superpowers:brainstorming` with **two overrides**: do NOT invoke `writing-plans` at the end. And do NOT display the spec content in the console or commit automatically — see Step 5.
```

- [ ] **Step 3: Verify**

```bash
grep -c "IDEATE.md" plugins/spec-driven-development/skills/design-codex/SKILL.md
grep -c "ASSUMPTIONS I'M MAKING" plugins/spec-driven-development/skills/design-codex/SKILL.md
grep -c "REFRAMED SUCCESS CRITERIA" plugins/spec-driven-development/skills/design-codex/SKILL.md
```
Expected: `1` for each

- [ ] **Step 4: Commit**

```bash
git add plugins/spec-driven-development/skills/design-codex/SKILL.md
git commit -m "feat(sdd): add IDEATE/INTENT detection, assumptions block, success criteria reframing to design-codex"
```

---

### Task 3: Add Common Rationalizations to `design/SKILL.md` and `plan/SKILL.md`

**Files:**
- Modify: `plugins/spec-driven-development/skills/design/SKILL.md`
- Modify: `plugins/spec-driven-development/skills/plan/SKILL.md`

**What changes:** A new `## Common Rationalizations` section is inserted immediately before `## Hard Rules` in each file. Different rationalization tables per file.

- [ ] **Step 1: Verify pre-condition**

```bash
grep -c "Common Rationalizations" plugins/spec-driven-development/skills/design/SKILL.md
grep -c "Common Rationalizations" plugins/spec-driven-development/skills/plan/SKILL.md
```
Expected: `0` for both

- [ ] **Step 2: Add rationalizations to `design/SKILL.md`**

Using Edit tool, replace in `plugins/spec-driven-development/skills/design/SKILL.md`:

Old string (exact):
```
## Hard Rules

- Do NOT invoke `writing-plans`, `executing-plans`, or any implementation skill.
- Do NOT write any code.
- Do NOT suggest next steps beyond pointing to `writing-plans` as the user's choice.
```

New string:
```
## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "This is simple, I don't need a spec" | Simple tasks don't need long specs, but they still need acceptance criteria. A two-line spec is fine. |
| "I'll write the spec after I code it" | That's documentation, not specification. The spec's value is forcing clarity before code. |
| "Requirements will change anyway" | That's why the spec is a living document. An outdated spec is still better than no spec. |
| "The user knows what they want" | Even clear requests have implicit assumptions. The spec surfaces those assumptions. |

## Hard Rules

- Do NOT invoke `writing-plans`, `executing-plans`, or any implementation skill.
- Do NOT write any code.
- Do NOT suggest next steps beyond pointing to `writing-plans` as the user's choice.
```

- [ ] **Step 3: Add rationalizations to `plan/SKILL.md`**

First, verify the Hard Rules section exists:
```bash
grep -n "## Hard Rules" plugins/spec-driven-development/skills/plan/SKILL.md
```
Expected: one hit

Using Edit tool, replace in `plugins/spec-driven-development/skills/plan/SKILL.md`:

Old string (exact):
```
## Hard Rules

- Do NOT invoke `executing-plans` or any implementation skill.
- Do NOT write code.
- Do NOT start executing — that is the user's decision in a new session.
- Always read the input file before invoking writing-plans.
- Always run Step 2 (branch setup) for PRD and ISSUE inputs — do NOT skip it even if you think the branch already exists.
- Always commit after user approves — do NOT skip Step 5. Do NOT push.
```

New string:
```
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
```

- [ ] **Step 4: Verify**

```bash
grep -c "Common Rationalizations" plugins/spec-driven-development/skills/design/SKILL.md
grep -c "Common Rationalizations" plugins/spec-driven-development/skills/plan/SKILL.md
```
Expected: `1` for both

- [ ] **Step 5: Commit**

```bash
git add plugins/spec-driven-development/skills/design/SKILL.md \
        plugins/spec-driven-development/skills/plan/SKILL.md
git commit -m "feat(sdd): add common rationalizations section to design and plan skills"
```

---

### Task 4: Enhance `implement/SKILL.md` — Framework Doc Line + Spec Divergence Step

**Files:**
- Modify: `plugins/spec-driven-development/skills/implement/SKILL.md`

**What changes:**
1. Add one instruction line to the implementation subagent prompt in Step 2 (after "Do NOT modify tests to make them pass — fix the implementation instead.")
2. Insert a new **Step 3 — Spec divergence check** between the current Step 2 and Step 3
3. Renumber old Step 3 → Step 4, old Step 4 → Step 5

- [ ] **Step 1: Verify pre-conditions**

```bash
grep -c "verify against official documentation" plugins/spec-driven-development/skills/implement/SKILL.md
grep -c "Spec divergence check" plugins/spec-driven-development/skills/implement/SKILL.md
```
Expected: `0` for both

- [ ] **Step 2: Add framework doc verification line to subagent prompt**

Using Edit tool, replace in `plugins/spec-driven-development/skills/implement/SKILL.md`:

Old string (exact):
```
- Do NOT modify tests to make them pass — fix the implementation instead.
- After all tasks are complete, run the full test suite and confirm all tests pass.
```

New string:
```
- Do NOT modify tests to make them pass — fix the implementation instead.
- For framework-specific patterns (React hooks, routing, auth, database ORM, etc.), verify against official documentation before implementing.
- After all tasks are complete, run the full test suite and confirm all tests pass.
```

- [ ] **Step 3: Insert new Step 3 (spec divergence check) and rename old Step 3 → Step 4**

Using Edit tool, replace in `plugins/spec-driven-development/skills/implement/SKILL.md`:

Old string (exact):
```
### Step 3 — Dispatch testing subagent

After the implementation subagent completes, dispatch a **separate** testing subagent — never run tests inline. A separate subagent ensures the test run happens with a clean context, independent of implementation decisions.
```

New string:
```
### Step 3 — Spec divergence check

After the implementation subagent completes, read `docs/<idea-slug>-DESIGN.md` and run `git diff` to compare the current working tree against the spec.

For each divergence (architectural decision changed, scope adjusted, data model differs from what the spec describes), propose a concrete edit to `docs/<idea-slug>-DESIGN.md`. Present each proposed edit to the user individually and wait for approval or rejection before continuing.

Only after the user has reviewed all proposed spec edits (or confirmed there are none), proceed to the testing subagent.

### Step 4 — Dispatch testing subagent

After the implementation subagent completes, dispatch a **separate** testing subagent — never run tests inline. A separate subagent ensures the test run happens with a clean context, independent of implementation decisions.
```

- [ ] **Step 4: Rename old Step 4 → Step 5**

Using Edit tool, replace in `plugins/spec-driven-development/skills/implement/SKILL.md`:

Old string (exact):
```
### Step 4 — Confirm

When the testing subagent reports all tests pass, say:
```

New string:
```
### Step 5 — Confirm

When the testing subagent reports all tests pass, say:
```

- [ ] **Step 5: Verify**

```bash
grep -c "verify against official documentation" plugins/spec-driven-development/skills/implement/SKILL.md
grep -c "Spec divergence check" plugins/spec-driven-development/skills/implement/SKILL.md
grep -n "### Step" plugins/spec-driven-development/skills/implement/SKILL.md
```
Expected: `1`, `1`, and steps 1–5 listed in order

- [ ] **Step 6: Commit**

```bash
git add plugins/spec-driven-development/skills/implement/SKILL.md
git commit -m "feat(sdd): add framework doc verification and spec divergence check to implement"
```

---

### Task 5: Enhance `verify/SKILL.md` — Definition of Done + Spec Living Doc Hard Rule

**Files:**
- Modify: `plugins/spec-driven-development/skills/verify/SKILL.md`

**What changes:**
1. Insert new **Step 4 — Definition of Done** after current Step 3 (Codex review)
2. Rename old Step 4 → Step 5, old Step 5 → Step 6
3. Update the consolidated report template in (new) Step 5 to include DoD status
4. Add new Hard Rule for spec living document

- [ ] **Step 1: Verify pre-conditions**

```bash
grep -c "Definition of Done" plugins/spec-driven-development/skills/verify/SKILL.md
grep -c "DESIGN.md needs updating" plugins/spec-driven-development/skills/verify/SKILL.md
```
Expected: `0` for both

- [ ] **Step 2: Insert new Step 4 (DoD) and rename old Step 4 → Step 5**

Using Edit tool, replace in `plugins/spec-driven-development/skills/verify/SKILL.md`:

Old string (exact):
````
### Step 4 — Consolidate and report

Present a single consolidated summary:

```
## Review: <idea-slug>-PLAN[-N]

### Plan compliance (Claude)
<issues from Step 2, or "No issues found">

### Technical defects (Codex)
<issues from Step 3, or "No issues found">

### Verdict
PASS — implementation matches the plan and no technical defects found.
  or
REVISE — list of items to fix before the implementation can be considered complete.
```
````

New string:
````
### Step 4 — Definition of Done

Before consolidating results, apply this checklist to the working tree. Each unchecked item is a blocking defect — add it to the REVISE list.

**Correctness**
- [ ] Behavior verified at runtime, not just compiled or typechecked
- [ ] New behavior is covered by tests that fail without the change
- [ ] Existing tests still pass — no regressions

**Quality**
- [ ] No dead code, debug output, or commented-out blocks
- [ ] Changes are scoped to the task — no unrelated code touched
- [ ] Linting and formatting pass

**Integration**
- [ ] Change works with the rest of the system, not just in isolation
- [ ] Backward compatibility considered for any public interface change

**Ship-readiness**
- [ ] Security implications reviewed for any untrusted input or auth handling
- [ ] Rollback path exists for anything risky

### Step 5 — Consolidate and report

Present a single consolidated summary:

```
## Review: <idea-slug>-PLAN[-N]

### Plan compliance (Claude)
<issues from Step 2, or "No issues found">

### Technical defects (Codex)
<issues from Step 3, or "No issues found">

### Definition of Done
<checklist status — list any unchecked items, or "All items checked">

### Verdict
PASS — implementation matches the plan, no technical defects, and all DoD items are checked.
  or
REVISE — list of items to fix before the implementation can be considered complete.
```
````

- [ ] **Step 3: Rename old Step 5 → Step 6**

Using Edit tool, replace in `plugins/spec-driven-development/skills/verify/SKILL.md`:

Old string (exact):
```
### Step 5 — Offer merge and cleanup (PASS only)

Only when the verdict is PASS, ask the user:
```

New string:
```
### Step 6 — Offer merge and cleanup (PASS only)

Only when the verdict is PASS, ask the user:
```

- [ ] **Step 4: Add Hard Rule for spec living document**

Using Edit tool, replace in `plugins/spec-driven-development/skills/verify/SKILL.md`:

Old string (exact):
```
## Hard Rules

- Do NOT fix any issues found during review.
- Do NOT invoke `executing-plans` or any implementation skill.
- Always read the plan file before running any review.
- `/codex:review` is standard review — do NOT use `/codex:adversarial-review` (design decisions are already settled at this stage).
```

New string:
```
## Hard Rules

- Do NOT fix any issues found during review.
- Do NOT invoke `executing-plans` or any implementation skill.
- Always read the plan file before running any review.
- `/codex:review` is standard review — do NOT use `/codex:adversarial-review` (design decisions are already settled at this stage).
- After a REVISE verdict, check whether `docs/<idea-slug>-DESIGN.md` needs updating to reflect decisions made during implementation before re-running verify.
```

- [ ] **Step 5: Verify**

```bash
grep -c "Definition of Done" plugins/spec-driven-development/skills/verify/SKILL.md
grep -c "DESIGN.md needs updating" plugins/spec-driven-development/skills/verify/SKILL.md
grep -n "### Step" plugins/spec-driven-development/skills/verify/SKILL.md
```
Expected: `1`, `1`, and steps 1–6 listed in order

- [ ] **Step 6: Commit**

```bash
git add plugins/spec-driven-development/skills/verify/SKILL.md
git commit -m "feat(sdd): add Definition of Done checklist and spec living-doc hard rule to verify"
```

---

### Task 6: Create `sdd:discover` Skill

**Files:**
- Create: `plugins/spec-driven-development/skills/discover/SKILL.md`

**What changes:** New skill file implementing the intent extraction pipeline — git check, plan-mode, slug/session/branch checkpoints, HYPOTHESIS-led interview loop, confirmed restat structure, INTENT.md output, commit, handoff.

- [ ] **Step 1: Verify the directory does not yet exist**

```bash
ls plugins/spec-driven-development/skills/ | grep discover
```
Expected: no output (empty)

- [ ] **Step 2: Create the skill file**

Write `plugins/spec-driven-development/skills/discover/SKILL.md` with this content:

```markdown
---
name: discover
description: Extracts confirmed user intent before design. Use when the ask is underspecified ("build me X" without "for whom" or "why now"), when success criteria are missing, or when there is temptation to fill in unspoken assumptions. Produces docs/<slug>-INTENT.md. Handoff goes to sdd:ideate or sdd:design.
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

~~~markdown
# Discover: <Idea Name>
Started: <YYYY-MM-DD>

## Summary
<one-paragraph description of what's being discovered>

## Decisions Reached
<!-- updated after each confirmed answer -->

## Open Questions
<!-- updated as new questions surface -->
~~~

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
~~~
HYPOTHESIS: <one sentence summary of what you think the user wants>
CONFIDENCE: ~X% — missing: <what is still unclear>
~~~

**Each subsequent question format:**
~~~
Q: <one focused question>
GUESS: <your current hypothesis with brief reasoning>
~~~

**Rules:**
- One question per message — never batch multiple questions
- Each question targets the most important unknown
- Push back on vague answers — offer two concrete options if needed

**Stop condition:** You can confidently predict the user's reaction to the next three questions you would ask. At this point, proceed to Step 5.

### Step 5 — Present confirmed restat

Summarize everything confirmed into this structure and **wait for explicit "yes"** before continuing:

~~~
Outcome:      <one line — what the user wants to achieve>
User:         <one line — who this is for>
Why now:      <one line — why this matters right now>
Success:      <one line — how they'll know it worked>
Constraint:   <one line — the hardest constraint>
Out of scope: <one line — what this explicitly does not include>
~~~

"Whatever you think" and "sounds good" are NOT a yes. If the user gives a vague confirmation, re-ask by presenting two concrete versions of the restat and asking which is right.

### Step 6 — Write INTENT.md

After explicit "yes", write `docs/<idea-slug>-INTENT.md`:

~~~markdown
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
~~~

### Step 7 — Commit

```bash
git add docs/<idea-slug>-INTENT.md docs/<idea-slug>-SESSION.md
git commit -m "docs: <idea-slug> intent confirmed"
```

### Step 8 — Handoff

Say: *"Intent confirmed and saved to `docs/<idea-slug>-INTENT.md`. Run `/sdd:ideate docs/<idea-slug>-INTENT.md` to explore solutions, or `/sdd:design docs/<idea-slug>-INTENT.md` to go straight to spec."*

## Output

- `docs/<idea-slug>-SESSION.md` — persistent session context
- `docs/<idea-slug>-INTENT.md` — confirmed intent structure

## Hard Rules

- Do NOT write `docs/<idea-slug>-INTENT.md` before the user gives an explicit "yes" to the restat.
- Do NOT ask more than one question per message.
- Do NOT write code or invoke other skills.
- Do NOT proceed past Step 5 until the restat has been explicitly confirmed.
```

- [ ] **Step 3: Verify the file was created**

```bash
ls plugins/spec-driven-development/skills/discover/SKILL.md
grep -c "INTENT.md" plugins/spec-driven-development/skills/discover/SKILL.md
grep -c "HYPOTHESIS" plugins/spec-driven-development/skills/discover/SKILL.md
```
Expected: file exists, `1`, `1`

- [ ] **Step 4: Commit**

```bash
git add plugins/spec-driven-development/skills/discover/SKILL.md
git commit -m "feat(sdd): add discover skill for intent extraction"
```

---

### Task 7: Create `sdd:ideate` Skill

**Files:**
- Create: `plugins/spec-driven-development/skills/ideate/SKILL.md`

**What changes:** New skill file implementing divergent/convergent solution exploration — reads INTENT.md if provided, runs 3-phase ideation (Diverge → Converge → Sharpen), produces IDEATE.md with problem statement, recommended direction, assumptions, MVP scope, and open questions.

- [ ] **Step 1: Verify the directory does not yet exist**

```bash
ls plugins/spec-driven-development/skills/ | grep ideate
```
Expected: no output

- [ ] **Step 2: Create the skill file**

Write `plugins/spec-driven-development/skills/ideate/SKILL.md` with this content:

```markdown
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

~~~
/sdd:ideate docs/<slug>-INTENT.md    ← recommended: starts from confirmed intent
/sdd:ideate                           ← no input: derive slug interactively
~~~

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

~~~markdown
# Ideate: <Idea Name>
Started: <YYYY-MM-DD>

## Summary
<one-paragraph description of what's being ideated>

## Decisions Reached
<!-- updated after each phase completes -->

## Open Questions
<!-- updated as new questions surface -->
~~~

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

~~~markdown
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
~~~

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
```

- [ ] **Step 3: Verify the file was created**

```bash
ls plugins/spec-driven-development/skills/ideate/SKILL.md
grep -c "IDEATE.md" plugins/spec-driven-development/skills/ideate/SKILL.md
grep -c "How Might We" plugins/spec-driven-development/skills/ideate/SKILL.md
```
Expected: file exists, `1`, `1`

- [ ] **Step 4: Commit**

```bash
git add plugins/spec-driven-development/skills/ideate/SKILL.md
git commit -m "feat(sdd): add ideate skill for solution space exploration"
```

---

### Task 8: Update `plugin.json` — Register `discover` and `ideate`, Bump Version

**Files:**
- Modify: `plugins/spec-driven-development/.claude-plugin/plugin.json`

**What changes:** Add a `"skills"` array with entries for the two new skills. Bump version from `1.3.2` to `1.4.0` (minor bump — new features added).

- [ ] **Step 1: Verify pre-condition**

```bash
grep -c "discover" plugins/spec-driven-development/.claude-plugin/plugin.json
```
Expected: `0`

- [ ] **Step 2: Apply the edit**

Using Edit tool, replace the entire contents of `plugins/spec-driven-development/.claude-plugin/plugin.json`:

Old string (exact, full file):
```json
{
  "name": "sdd",
  "version": "1.3.2",
  "description": "Skills for spec driver development: design → prd  → plan → implement → verify.",
  "author": {
    "name": "Laurentiu Irimia"
  }
}
```

New string:
```json
{
  "name": "sdd",
  "version": "1.4.0",
  "description": "Skills for spec driven development: discover → ideate → design → prd → plan → implement → verify.",
  "author": {
    "name": "Laurentiu Irimia"
  },
  "skills": [
    {
      "name": "discover",
      "path": "skills/discover/SKILL.md",
      "description": "Extracts confirmed user intent before design. Use when the ask is underspecified, when 'who' or 'why now' is missing, or when there is temptation to fill in unspoken assumptions. Produces docs/<slug>-INTENT.md."
    },
    {
      "name": "ideate",
      "path": "skills/ideate/SKILL.md",
      "description": "Divergent/convergent exploration of solution space before writing a spec. Use when intent is known but direction is unclear. Reads INTENT.md if available. Produces docs/<slug>-IDEATE.md."
    }
  ]
}
```

- [ ] **Step 3: Verify**

```bash
grep -c "discover" plugins/spec-driven-development/.claude-plugin/plugin.json
grep -c "ideate" plugins/spec-driven-development/.claude-plugin/plugin.json
grep -c "1.4.0" plugins/spec-driven-development/.claude-plugin/plugin.json
```
Expected: `1`, `1`, `1`

- [ ] **Step 4: Commit**

```bash
git add plugins/spec-driven-development/.claude-plugin/plugin.json
git commit -m "feat(sdd): register discover and ideate skills in plugin.json, bump to 1.4.0"
```

---

## Verification: End-to-End Checklist

After all tasks complete, run this checklist manually:

```bash
# 1. All modified existing skills gained lines (additive check)
for skill in design design-codex plan implement verify; do
  echo "=== $skill ===" && wc -l plugins/spec-driven-development/skills/$skill/SKILL.md
done

# 2. New skills exist
ls plugins/spec-driven-development/skills/discover/SKILL.md
ls plugins/spec-driven-development/skills/ideate/SKILL.md

# 3. design and design-codex have all three enhancements
grep -l "IDEATE.md" plugins/spec-driven-development/skills/design/SKILL.md plugins/spec-driven-development/skills/design-codex/SKILL.md
grep -l "ASSUMPTIONS I'M MAKING" plugins/spec-driven-development/skills/design/SKILL.md plugins/spec-driven-development/skills/design-codex/SKILL.md
grep -l "REFRAMED SUCCESS CRITERIA" plugins/spec-driven-development/skills/design/SKILL.md plugins/spec-driven-development/skills/design-codex/SKILL.md

# 4. plan has rationalizations
grep -c "Common Rationalizations" plugins/spec-driven-development/skills/plan/SKILL.md

# 5. implement has both new additions
grep -c "verify against official documentation" plugins/spec-driven-development/skills/implement/SKILL.md
grep -c "Spec divergence check" plugins/spec-driven-development/skills/implement/SKILL.md

# 6. verify has DoD and new hard rule
grep -c "Definition of Done" plugins/spec-driven-development/skills/verify/SKILL.md
grep -c "DESIGN.md needs updating" plugins/spec-driven-development/skills/verify/SKILL.md

# 7. plugin.json has both new skills and updated version
grep -c "1.4.0" plugins/spec-driven-development/.claude-plugin/plugin.json
```

All expected values: `1` or "file exists" for each check.
