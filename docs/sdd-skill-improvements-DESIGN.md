# Spec: SDD Skill Improvements
_Locked via brainstorming — by Claude + user. Revised after Codex round 1._

## Goal

Improve the local `spec-driven-development` plugin by borrowing four patterns
observed in `buildermethods/bm-skills`'s `bm-prd-creator`: modular step-files,
a "propose a default, then confirm" interaction style, explicit plan/issue
granularity choices, and a strict "what vs how" boundary in PRD output. Scope
is process/content changes only — no new output formats, no change to
`design-adversarial`/`design-review`/`adversarial`, and no change to
`superpowers:brainstorming` or `superpowers:writing-plans` themselves (only to
how the local skills invoke them, via their existing override mechanism).

## Approach

**Branch:** `feature/sdd-skill-improvements` (created). Before any skill file
edit, implementers must confirm `git branch --show-current` reports
`feature/sdd-skill-improvements` and `git status` is clean of unrelated changes.

**Interaction primitive.** None of the current skills use a tool named
`AskUserQuestion`. The existing pattern is: state options in chat text, wait
for explicit user reply (see `discover`'s Q/GUESS format, `plan`'s "present
exactly these three options" checkpoints). All "propose default" and
"granularity choice" additions below use this same chat-based pattern — no new
tool dependency.

**Item 1 — Modularize `prd`, `discover`, `ideate`.**

Step-mapping table (every current step → new file), grounded in the actual
current content of each skill:

*`discover` (162 lines) →*
| Current step | New location |
|---|---|
| Step 1 (git check) + Step 2 (plan-mode) | `steps/00-setup.md` |
| Step 3 (Checkpoints 1-3: slug, session file, branch) | `steps/01-slug-and-branch.md` |
| Step 4 (interview loop) | `steps/02-interview.md` |
| Step 5 (confirmed restat) | `steps/03-confirm.md` |
| Step 6 (write INTENT.md) + Step 7 (commit) + Step 8 (handoff) | `steps/04-write-and-handoff.md` |

*`ideate` (163 lines) →*
| Current step | New location |
|---|---|
| Step 0 (git check + plan-mode) | `steps/00-setup.md` |
| Step 1 (Checkpoints 1-2 + branch detection) | `steps/01-slug-and-branch.md` |
| Step 2 (read upstream INTENT.md) | `steps/02-read-upstream.md` |
| Step 3 (Phase 1 — Diverge) | `steps/03-diverge.md` |
| Step 4 (Phase 2 — Converge) | `steps/04-converge.md` |
| Step 5 (Phase 3 — Sharpen, write IDEATE.md) | `steps/05-sharpen.md` |
| Step 6 (commit) + Step 7 (handoff) | `steps/06-commit-and-handoff.md` |

*`prd` (148 lines) →*
| Current step | New location |
|---|---|
| Step 1 (read DESIGN.md) + Step 2 (explore codebase) | `steps/00-read-and-explore.md` |
| Step 3 (identify seams) | `steps/01-seams.md` |
| Step 4 (write PRD.md) | `steps/02-write-prd.md` |
| Step 5 (draft issues) | `steps/03-issue-breakdown.md` |
| Step 6 (write issue files + commit) | `steps/04-write-issues.md` |
| Step 7 (confirm) | `steps/05-handoff.md` |

Each thin `SKILL.md` keeps: frontmatter, overview, Model & Thinking, Language
(where applicable), Before Starting, Output, Hard Rules — and replaces the
`## Process` body with a `## Process` section stating explicitly. Any Hard
Rule or cross-reference that names an old step number (e.g. "Do NOT proceed
past Step 5") must be rewritten to name the corresponding new step-file
instead, preserving the behavioral rule while updating the reference:

> Read and follow each file in `steps/` **in numeric order**. Each step file
> is mandatory context, not optional background — do not skip a step file or
> rely on the index summary alone.

Each step file is self-contained and must include, where applicable:
- **Reads:** what prior step output / session file state it depends on
- **Does:** the actual instructions (unchanged from the current monolithic
  content — this is a structural move, not a rewrite)
- **Checkpoint invariants:** for files containing a `⛔ CHECKPOINT`, the exact
  resume behavior if `docs/<slug>-SESSION.md` already has this decision
  recorded (skip re-asking, per existing "if the file already exists, read it
  and resume" rule)
- **Stop condition / approval gate:** what must be true before moving to the
  next step file
- **Hands off:** what the next step file consumes

**Verification that this is structurally faithful (not an unintended
rewrite):** before the first split, record the current `HEAD` SHA (the base
commit). After each split, diff the resulting step files' instructional
content against the corresponding lines of the pre-split monolithic SKILL.md
at that recorded base SHA. The only permitted differences are: the new
Reads/Hands-off framing sentences, plus the specific behavioral edits called
out in Items 2-4 (Interaction Style, granularity choice, scope boundary) —
any other content delta is an unintended drift and must be reverted.

**Item 2 — "Propose a default, then confirm."**

Add an `## Interaction Style` section to `discover` (`steps/02-interview.md`),
`ideate` (`steps/04-converge.md`), and `design-brainstorm` (new section in its
existing monolithic SKILL.md — not modularized):

```markdown
## Interaction Style

Where a reasonable default can be inferred from context already gathered,
propose it and ask for confirmation or correction, instead of asking an open
question. State the default plainly, e.g.: "Default: <X>. Confirm or tell me
what to change." Reserve fully open questions for inputs with no inferable
default (e.g. the raw idea description, the problem statement, or the first
question of an interview before any context exists). This does not relax any
existing explicit-confirmation requirement: a default still requires a clear
yes or an explicit alternative choice from the user — passive agreement
("sounds good", "whatever you think") is still rejected per `discover`'s
existing restat rule, and the same standard applies wherever this style is
used.
```

Scoping to avoid conflicting with existing one-question-at-a-time rules:
- `discover`'s interview loop (Step 4 / `02-interview.md`) keeps "one question
  per message" as a hard rule. The default-proposal style applies to the
  `GUESS:` line already present in the format — make explicit that `GUESS:`
  should commit to a specific default the user can simply confirm, not a
  vague restatement.
- `ideate`'s Phase 2 / Converge (`04-converge.md`) already asks the user to
  pick among 2-3 presented directions — this item formalizes that each
  direction is presented as "Direction A (default: best fit per stress-test)"
  rather than three unranked options.
- `design-brainstorm` delegates its approach-proposal step to
  `superpowers:brainstorming` via an invocation override (see `design-review`
  /`design-adversarial` for the existing override pattern). The current
  `design-brainstorm` invocation already carries three overrides (terminal
  state, success criteria, spec writing) — add another, unnumbered as
  "third" but appended to that existing list:
  > **OVERRIDE — default selection:** When presenting 2-3 approaches, mark
  > one as "(Recommended)" with a one-line reason, consistent with this
  > project's `AskUserQuestion`-style default-first convention.
  This does not modify `superpowers:brainstorming` itself — only how
  `design-brainstorm` invokes it, matching the existing override mechanism.

**Item 3 — Explicit granularity choice in `plan` and `prd`'s issue breakdown.**

`plan/SKILL.md` Step 4 already invokes `superpowers:writing-plans` with 6
named overrides. Add:

> **OVERRIDE 7 — granularity:** Before writing-plans drafts steps, present
> exactly these three options in chat and wait for the user's choice:
> - **1. Fewer, larger steps** — faster execution, less intermediate
>   validation
> - **2. Balanced** (default — recommend this unless the input suggests
>   otherwise) — one step per logical unit of work
> - **3. More, smaller steps** — maximum checkpoints, more context-switch
>   overhead
>
> Include the user's choice **verbatim** in the override text handed to
> `superpowers:writing-plans` (e.g. "OVERRIDE 7 — granularity: the user chose
> 'Balanced — one step per logical unit of work'; size all plan steps
> accordingly"), since writing-plans is an invoked skill, not a typed API —
> the constraint only takes effect if it is literally present in the prompt.

Wording must differ by input type per Codex finding #7: when the input is
`ISSUE-N.md` (already a single vertical slice from `prd`), the three options
size **implementation tasks within that slice**, not features — replace
"steps" wording with "implementation tasks" in the ISSUE-N.md case to avoid
re-litigating PRD-level decomposition.

`prd`'s `steps/03-issue-breakdown.md` (from Item 1) replaces the current
after-the-fact "Does the granularity feel right?" question with the same
upfront 3-option pattern, sized for **issue/slice count** (not implementation
tasks — that distinction belongs to `plan`):
- **1. Fewer, larger slices** — fewer handoffs, larger PRs
- **2. Balanced** (default) — one slice per end-to-end user-visible behavior
- **3. More, smaller slices** — maximum AFK-friendly granularity, more
  sequencing overhead

**Item 4 — "What vs how" boundary in `prd`.**

In `steps/02-write-prd.md` (from Item 1), add — bounded per Codex findings
#9, #10, #11:

```markdown
## Scope Boundary: What, Not How

Applies to `docs/<slug>-PRD.md` only — NOT to `docs/<slug>-ISSUE-N.md` files,
which may continue to inline a prototype snippet per the existing rule
("unless a prototype snippet encodes a decision more precisely than prose").

In the Problem Statement, Solution, and User Stories sections: no code
snippets, no method/function names, no file paths, no internal module names.
User-facing or third-party platform/integration names ARE allowed where the
user genuinely interacts with them (e.g. "sign in with Google", "export to
Notion") — the boundary is *implementation technology* (how it's built), not
*product surface* (what the user sees and touches).

Example — disallowed: "calls `validateSession()` in `auth/middleware.ts`
using JWT." Example — allowed: "the user stays signed in across page
reloads."

The Implementation Decisions section may name modules, schemas, and API
contracts per the existing template, but only for contracts that are
externally relevant (e.g. a public API shape another team integrates with) —
not internal file/module references. Before writing the PRD, scan the draft
against this rule and strip violations.
```

## Key decisions & tradeoffs

- **Modularization scope limited to 3 skills** (`prd`, `discover`, `ideate`) —
  not applied to `design-brainstorm`, `design-adversarial`, `design-review`,
  `plan`, `implement`, `verify`, `finalize`. Per Codex finding #15, implement
  one skill first (`discover`, smallest scope of the three) and validate
  end-to-end before splitting `ideate` and `prd`, rather than splitting all
  three simultaneously. The pre-split monolithic content stays in git history
  at the recorded base SHA (see Item 1's verification note) as the rollback
  path — no separate backup file.
- **No new output formats** — explicitly rejected HTML/PDF PRD output.
- **Granularity choice is upfront, not retroactive**, with distinct wording
  for slice-count (`prd`) vs. task-count (`plan`) per Codex finding #7 — these
  are different decisions at different points in the pipeline and must not
  share a single ambiguous "granularity" prompt.
- **No new tool dependency** — "propose default, then confirm" and
  "granularity choice" both use the existing chat-based option-presentation
  pattern already used throughout these skills (no `AskUserQuestion` tool
  exists in this codebase's skill vocabulary).
- **`design-brainstorm`/`plan` changes go through existing override
  mechanisms** (the override pattern already used to invoke
  `superpowers:brainstorming` and `superpowers:writing-plans`) rather than
  modifying those upstream skills directly — keeps this change local to the
  `spec-driven-development` plugin.
- **"What vs how" applies to PRD.md only, not ISSUE-N.md or DESIGN.md** —
  ISSUE-N.md already has a narrower, deliberate exception for prototype
  snippets; DESIGN.md's "Key decisions & tradeoffs" section legitimately
  references technical approach. PRD is the boundary case where leaking
  implementation detail is the actual problem being fixed.

## Risks / open questions

- Splitting `discover`/`ideate`/`prd` into step-files changes invocation flow
  from "read one file" to "read N files in order." Mitigated by: explicit
  "read in numeric order, each is mandatory" instruction in each trimmed
  SKILL.md, and per-file Reads/Hands-off framing for resumability after
  context compaction (Codex finding #4).
  - Residual risk: an agent could still read only the index and skip step
    files if it misjudges them as optional. Accepted risk for v1 — revisit if
    the `discover` pilot (see staged rollout below) shows this happening.
- No automated test suite exists for skill content — verification is manual
  dry-run with a trivial throwaway feature description plus a structural diff
  against pre-split content (per Item 1's verification note), not unit tests.
- **Staged rollout**: implement and validate `discover` first; only proceed
  to `ideate` and `prd` after a dry-run of `discover` on a trivial throwaway
  feature description exercises every step file end-to-end — setup, slug +
  branch checkpoints, the full interview loop, restat confirmation, write +
  commit, and handoff — including one deliberate mid-flow interruption to
  confirm session-file resume works, AND the user explicitly approves moving
  on to `ideate`/`prd`. Both conditions (full exercise + explicit user
  approval) must hold; neither alone is sufficient.

## Out of scope

- HTML/PDF PRD output.
- Modularizing `design-brainstorm`, `design-adversarial`, `design-review`,
  `plan`, `implement`, `verify`, `finalize`.
- Any change to the Codex adversarial review mechanics in
  `design-adversarial` / `design-review` / `adversarial`.
- Any modification to `superpowers:brainstorming` or `superpowers:writing-plans`
  themselves — only to the override blocks `design-brainstorm` and `plan` pass
  into them.
- Any code/implementation changes — this spec covers SKILL.md/step-file
  content only.
- Introducing `AskUserQuestion` or any new tool dependency.
