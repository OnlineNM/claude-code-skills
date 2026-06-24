# Spec: SDD Plugin Enhancements
Date: 2026-06-24

## Objective

Improve the `plugins/spec-driven-development` plugin with patterns identified through analysis of the `addyosmani/agent-skills` repository. The changes make the pipeline more robust at requirement extraction, assumption surfacing, and implementation quality gates. All changes are additive — no skill is rewritten from scratch.

## Scope

**Modified skills:** `design`, `design-codex`, `plan`, `implement`, `verify`
**New skills:** `discover`, `ideate`
**Infrastructure:** `.claude-plugin/plugin.json`

## Principles

- All changes are additive — no skill rewrites
- No external references to `agent-skills` — all logic is self-contained
- `design-codex` receives the same modifications as `design` (items 1, 2, INTENT/IDEATE detection)

---

## Part 1 — Modifications to Existing Skills

### 1. Assumptions Block (`design`, `design-codex`)

**Where:** Step 4, before brainstorming starts — immediately after session file is created.

**What:** Surface all implicit assumptions before asking the first question. Format:

```
ASSUMPTIONS I'M MAKING:
1. [assumption about stack / tech]
2. [assumption about audience]
3. [assumption about constraints or scope]
→ Correct me now or I'll proceed with these.
```

Brainstorming only continues after the user explicitly confirms or corrects the assumptions.

---

### 2. Success Criteria Reframing (`design`, `design-codex`)

**Where:** Step 4 brainstorming override — when the user describes a vague objective during brainstorming.

**What:** Translate vague requirements into concrete, measurable success criteria before writing the spec:

```
REQUIREMENT: "Make it faster"

REFRAMED SUCCESS CRITERIA:
- [specific measurable condition, e.g. "LCP < 2.5s on 4G"]
- [specific measurable condition]
→ Are these the right targets?
```

This is a brainstorming sub-step, not a separate checkpoint. It runs whenever an objective cannot be directly verified.

---

### 3. Spec as Living Document (`implement`, `verify`)

**In `implement` — new sub-step after Step 3 (implementation subagent completes):**

Claude reads `docs/<slug>-DESIGN.md` and the current `git diff`. For each divergence from the spec (architectural decision changed, scope adjusted, data model differs), Claude proposes a concrete edit to DESIGN.md. The user approves or rejects each change before Step 4 (testing subagent) begins.

**In `verify` — new Hard Rule:**

> After a REVISE verdict, check whether DESIGN.md needs updating to reflect decisions made during implementation before re-running verify.

---

### 4. Definition of Done (`verify`)

**Where:** New Step 4, inserted after Codex review (current Step 3) and before consolidation (current Step 4, renumbered to Step 5).

**What:** Inline DoD checklist applied to the working tree — no external reference:

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

The final verdict in Step 5 (consolidated report) incorporates DoD status alongside plan compliance and Codex findings.

---

### 5. Framework Doc Verification (`implement` subagent prompt)

**Where:** Step 2 — the prompt sent to the implementation subagent.

**What:** One line added to the subagent instructions:

> "For framework-specific patterns (React hooks, routing, auth, database ORM, etc.), verify against official documentation before implementing."

---

### 6. Common Rationalizations (`design`, `plan`)

**Where:** New section added at the end of each skill, immediately before Hard Rules.

**`design` rationalizations:**

| Rationalization | Reality |
|---|---|
| "This is simple, I don't need a spec" | Simple tasks don't need long specs, but they still need acceptance criteria. A two-line spec is fine. |
| "I'll write the spec after I code it" | That's documentation, not specification. The spec's value is forcing clarity before code. |
| "Requirements will change anyway" | That's why the spec is a living document. An outdated spec is still better than no spec. |
| "The user knows what they want" | Even clear requests have implicit assumptions. The spec surfaces those assumptions. |

**`plan` rationalizations:**

| Rationalization | Reality |
|---|---|
| "I'll figure it out as I go" | That's how you get a tangled mess and rework. 10 minutes of planning saves hours. |
| "The tasks are obvious, no need to write them" | Writing tasks surfaces hidden dependencies and forgotten edge cases. |
| "Planning is overhead" | Planning is the task. Implementation without a plan is just typing. |
| "I can hold it all in my head" | Context windows are finite. Written plans survive session boundaries and compaction. |

---

## Part 2 — New Skills

### 7. `sdd:discover`

**Purpose:** Extract confirmed user intent before design. Answers "what do you actually want?" — not how to build it, but whether you know what you're building.

**When to use:** Ask is underspecified ("build me X" without "for whom" or "why now"), user hasn't articulated success criteria, or there's temptation to fill in unspoken assumptions.

**Process:**

1. Git check + EnterPlanMode
2. **CHECKPOINT 1** — slug approval (identical to `design`)
3. **CHECKPOINT 2** — session file: create `docs/<slug>-SESSION.md` or resume if exists
4. **CHECKPOINT 3** — branch strategy (identical to `design`)
5. **Interview loop:**
   - First message: `HYPOTHESIS: <one sentence> / CONFIDENCE: ~X% — missing: <what>`
   - Each question: `Q: <one focused question> / GUESS: <hypothesis with reasoning>`
   - One question per message — no batching
   - Stop condition: "Can I predict the user's reaction to the next three questions I would ask?"
6. **Restat confirmat** — present structured and wait for explicit "yes":
   ```
   Outcome:      <one line>
   User:         <one line>
   Why now:      <one line>
   Success:      <one line>
   Constraint:   <one line>
   Out of scope: <one line>
   ```
   "Whatever you think" and "sounds good" are NOT a yes — re-ask with two concrete options.
7. Write `docs/<slug>-INTENT.md` with the confirmed restat structure
8. Commit: `docs: <slug> intent confirmed`
9. Handoff: *"Run `/sdd:ideate docs/<slug>-INTENT.md` or `/sdd:design docs/<slug>-INTENT.md`"*

**Output:** `docs/<slug>-INTENT.md`

**Hard Rules:**
- Do NOT write INTENT.md before explicit "yes"
- Do NOT ask more than one question per message
- Do NOT write code or invoke other skills

---

### 8. `sdd:ideate`

**Purpose:** Divergent/convergent exploration of the solution space. Answers "how might this look?" — narrows direction before design, but does not write a spec.

**Input:** Optional — `docs/<slug>-IDEATE.md` path passed as argument.

**Branch detection:** CHECKPOINT 1 (slug confirmation) and CHECKPOINT 2 (session file) always run. If the input is an INTENT.md path, the slug is derived from the filename — CHECKPOINT 1 becomes a confirmation of the derived slug, identical to how `plan` handles it. CHECKPOINT 3 (branch strategy) is skipped if `feature/<slug>` already exists; announce: *"Branch `feature/<slug>` detected — reusing it."* If no branch exists, run CHECKPOINT 3 in full.

**Process:**

0. Git check + EnterPlanMode

**Phase 1 — Divergent (Understand & Expand):**
- If INTENT.md exists, read it and confirm: *"Found `docs/<slug>-INTENT.md` — starting from it."*
- Reframe as "How Might We" statement
- 3-5 sharpening questions, one at a time
- Generate 5-8 variations using lenses: inversion, constraint removal, audience shift, simplification, 10x version, expert lens
- Push back on weak ideas with specificity — not a yes-machine

**Phase 2 — Convergent (Evaluate & Converge):**
- Cluster into 2-3 meaningfully distinct directions
- Stress-test each against: user value (painkiller vs vitamin), feasibility (hardest part), differentiation (why switch)
- Surface hidden assumptions explicitly for each direction:
  - What we're betting is true (unvalidated)
  - What could kill this idea
  - What we're choosing to ignore (and why that's acceptable for now)

**Phase 3 — Sharpen:**
- Write `docs/<slug>-IDEATE.md`:

```markdown
# Problem Statement
[One-sentence "How Might We" framing]

# Recommended Direction
[Chosen direction and why — 2-3 paragraphs max]

# Key Assumptions to Validate
- [ ] [Assumption — how to test it]

# MVP Scope
[Minimum version that tests the core assumption. What's in, what's out.]

# Not Doing (and Why)
- [Thing] — [reason]

# Open Questions
- [Question that needs answering before building]
```

- Commit: `docs: <slug> ideation complete`
- Handoff: *"Run `/sdd:design docs/<slug>-IDEATE.md`"*

**Output:** `docs/<slug>-IDEATE.md`

**Hard Rules:**
- Do NOT skip Phase 1 and 2 and jump to Phase 3 output
- Do NOT validate weak ideas without pushing back
- Do NOT write code or invoke other skills

---

## Part 3 — Integration

### `design` and `design-codex` — upstream document detection

At Step 4, before launching brainstorming, check `docs/` for upstream artifacts from this slug:

1. Look for `docs/<slug>-IDEATE.md` first (higher priority — already has direction)
2. Fall back to `docs/<slug>-INTENT.md` if no IDEATE exists

If found, announce explicitly:
> *"Found `docs/<slug>-IDEATE.md` — using it as the starting point for brainstorming."*

Brainstorming starts with content from these files instead of the raw user description. If neither exists, behavior is identical to current.

---

### `plugin.json` — new skill entries

Add two entries to the skills list in `.claude-plugin/plugin.json`:

```json
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
```

---

## Pipeline Overview

```
sdd:discover  →  docs/<slug>-INTENT.md
     ↓ (optional)
sdd:ideate    →  docs/<slug>-IDEATE.md     ← reads INTENT.md if available
     ↓ (optional)
sdd:design    →  docs/<slug>-DESIGN.md     ← reads INTENT/IDEATE if available
     ↓
sdd:design-review
     ↓
sdd:prd       →  docs/<slug>-PRD.md + ISSUE-N.md
     ↓
sdd:plan      →  docs/<slug>-PLAN.md
     ↓
sdd:implement →  working code              ← spec divergence check → DESIGN.md update
     ↓
sdd:verify    →  plan compliance + Codex + DoD
     ↓
sdd:finalize
```

Each step is optional as an entry point — the pipeline can be entered at any level.

## Success Criteria

- [ ] All 6 existing skill modifications are additive — no content removed from current skill files
- [ ] `sdd:discover` produces INTENT.md and can be run standalone or as a pre-step to `design`
- [ ] `sdd:ideate` reads INTENT.md if available and produces IDEATE.md
- [ ] `sdd:design` detects and uses INTENT/IDEATE documents when present
- [ ] `plugin.json` registers both new skills correctly
- [ ] The full pipeline (discover → ideate → design → prd → plan → implement → verify → finalize) works end-to-end
