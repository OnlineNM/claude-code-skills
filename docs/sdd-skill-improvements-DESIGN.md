# Spec: SDD Skill Improvements
_Locked via brainstorming — by Claude + user_

## Goal

Improve the local `spec-driven-development` plugin by borrowing four patterns
observed in `buildermethods/bm-skills`'s `bm-prd-creator`: modular step-files,
a "propose defaults, then confirm" interaction style, explicit plan/issue
granularity choices, and a strict "what vs how" boundary in PRD output. Scope
is process/content changes only — no new output formats, no change to the
design-brainstorm/design-adversarial/design-review trio beyond the defaults rule.

## Approach

**Branch:** `feature/sdd-skill-improvements` (created).

**Item 1 — Modularize `prd`, `discover`, `ideate`.**
Split each skill's monolithic SKILL.md (148/162/163 lines) into a thin index
SKILL.md (frontmatter, overview, model/thinking line, numbered step index) plus
`steps/*.md` files, one per phase:
- `prd/steps/`: `intent-confirm.md`, `seam-identification.md`, `write-prd.md`,
  `issue-breakdown.md`, `write-issues.md`, `confirm-commit.md`
- `discover/steps/`: `intake.md`, `interview.md`, `confirm-intent.md`,
  `write-intent.md`
- `ideate/steps/`: `diverge.md`, `converge.md`, `sharpen.md`, `write-ideate.md`

Each step file states what it reads (prior step output / session state), what
it asks or does, and what it hands off next. Pure structural refactor — no
output schema change for `INTENT.md`, `IDEATE.md`, `PRD.md`, or issue files.

**Item 2 — "Propose defaults, then confirm."**
Add an `## Interaction Style` rule to `discover`, `ideate`, `design-brainstorm`
(and into the relevant step files for the modularized skills): propose a
default via `AskUserQuestion` (labeled "(Recommended)") instead of open-ended
questions, reserving free-form chat for genuinely open inputs (raw idea,
problem statement). Applied at: `discover`'s interview step, `ideate`'s
converge step, `design-brainstorm`'s approach-proposal step.

**Item 3 — Explicit granularity choice in `plan` and `prd`'s issue breakdown.**
`plan/SKILL.md` (not modularized — small enough) gains a step before plan
writing: propose 3 granularity options (fewer/larger, balanced [default],
more/smaller) via `AskUserQuestion`, each with an inline risk/control vs.
momentum trade-off, before sizing the resulting PLAN.md steps. `prd`'s
issue-breakdown step file gets the same upfront 3-option choice, replacing the
current after-the-fact "does the granularity feel right?" check.

**Item 4 — "What vs how" boundary in `prd`.**
`prd`'s `write-prd.md` step gets an explicit `## Scope Boundary: What, Not How`
rule: PRD body (Problem Statement, Solution, User Stories) may not contain code
snippets, library/framework names, method/function names, or file paths.
Implementation Decisions section may still name modules/schemas/API contracts
per the existing template, but no code. Applies to PRD output only — DESIGN.md
is unaffected.

## Key decisions & tradeoffs

- **Modularization scope limited to 3 skills** (prd, discover, ideate) — not
  applied to design-brainstorm/design-adversarial/design-review/plan/implement/
  verify/finalize. Those are either already appropriately sized or have
  external-tool integration (Codex) that doesn't fit the step-file pattern
  cleanly. Risk: inconsistent skill structure across the plugin going forward.
- **No new output formats** — explicitly rejected HTML/PDF PRD output (can be
  generated on demand from markdown via existing tools, not worth a skill
  change).
- **Granularity choice is upfront, not retroactive** — bm-skills' milestones.md
  pattern presents 3 named options before generation; the current `plan` and
  `prd` skills ask "does this feel right?" after generating one structure.
  Tradeoff: one extra user roundtrip per invocation, but avoids regenerating a
  plan/issue set from scratch when the user wanted different granularity.
- **"What vs how" applies to PRD only, not DESIGN.md** — DESIGN.md already
  contains "Key decisions & tradeoffs" that legitimately reference technical
  approach; PRD is the user-facing/stakeholder artifact where leaking
  implementation detail is the actual failure mode being fixed.

## Risks / open questions

- Splitting `discover`/`ideate`/`prd` into step-files changes how the skill is
  invoked end-to-end (multi-file reads instead of one). Risk: if step files
  aren't self-contained (each restates what it needs from prior steps), the
  skill could lose coherence across a long session or context compaction.
  Mitigation: each step file explicitly states its inputs/outputs (per Item 1
  approach above).
- No automated tests exist for skill content — verification is manual dry-run
  with a trivial throwaway feature description, not a test suite.

## Out of scope

- HTML/PDF PRD output.
- Modularizing design-brainstorm, design-adversarial, design-review, implement,
  verify, finalize.
- Any change to the Codex adversarial review mechanics in design-adversarial /
  design-review / adversarial.
- Any code/implementation changes — this spec covers SKILL.md/step-file content
  only.
