# Spec: SDD Context Hygiene
_Locked via brainstorming — by Claude + user_

## Goal
Apply the 6 confirmed findings from `docs/sdd-context-hygiene-NOTES.md` to the `plan`,
`implement`, `verify`, `revise`, and `finalize` SKILL.md files of the
`spec-driven-development` plugin. These findings came from cross-checking the skills'
documented behavior against real session transcripts (project `nats-msgs`), not theory —
the goal is to close each defect before the next real `sdd:plan`/`sdd:implement`/`sdd:verify`
run hits the same failure again. This is a text-only documentation change: no code
changes, no changes to `superpowers:*` skills — only the 5 named SKILL.md files.

## Approach
Each finding gets one targeted change, applied to each named occurrence (Findings 2 and
4 each touch two template blocks — Step 2 and Step 4 of `implement/SKILL.md`), anchored
by section heading and surrounding
text (line numbers below are advisory pointers gathered via pre-brainstorming codebase
exploration, not implementation instructions — re-locate by heading/text if the files
have since shifted). The implementation phase (`/sdd:plan` → `/sdd:implement`) must use
the `skill-creator` skill to apply these 6 edits to the SKILL.md files, rather than raw
ad-hoc Edit/Write calls, so the result stays consistent with the plugin's own
skill-authoring conventions. The implementer (`/sdd:plan` → `/sdd:implement`) must read
`skill-creator`'s own SKILL.md at implementation time to identify its exact steps for
editing an existing skill and its validation checklist, and follow those precisely —
this spec intentionally doesn't pre-enumerate `skill-creator`'s internal steps, since
that workflow is owned by `skill-creator` itself and could change independently of this
spec. No unrelated reflow, reformatting, or edits outside the sections named below.

If, during implementation, any of the 5 files no longer matches the structure this spec
assumes (e.g. a heading/step already renumbered or removed), stop and report the
discrepancy to the user rather than guessing a placement.

1. **Finding 1 — missing `/clear` prompt in `finalize`.**
   `finalize/SKILL.md` has no `## Before Starting` section at all. Add one, identical in
   wording to `plan/SKILL.md:30-33` and `verify/SKILL.md:29-31`, with one addition
   covering the internal handoff from Finding 6's `verify` Step 7 (so a same-session
   "Yes" handoff isn't blocked by asking to clear a context `verify` just used):
   > `## Before Starting`
   > Tell the user: *"Please run `/clear` first to start with a clean context, then
   > re-invoke this skill."* If the user has already cleared, proceed. If this skill was
   > invoked directly by `sdd:verify` Step 7 (same-session handoff after a PASS verdict),
   > skip this prompt and proceed directly — the handoff is intentional and doesn't need
   > a fresh context.

2. **Finding 2 — full plan content pasted into subagent dispatch prompts.**
   - `implement/SKILL.md:84` (Step 2 template, placeholder at line 71 inside
     `<plan>...</plan>`): currently "Replace `<PLAN_CONTENT>` with the full content of
     the plan file read in Step 1."
   - `implement/SKILL.md:116` (Step 4 template, placeholder at line 106): currently
     "Replace `<PLAN_CONTENT>` with the full content of the plan file."
   - `revise/SKILL.md:73-76` (Step 2c) has no literal placeholder — it delegates by
     reference to `implement`'s Steps 2/4 pattern, so it inherits the fix automatically
     once those two are changed; no separate edit needed there.

   Fix: in both `implement/SKILL.md` template blocks, replace the `<plan>...</plan>`
   block (containing the `<PLAN_CONTENT>` placeholder) with the literal template block
   `<plan_path><PLAN_PATH></plan_path>` — `<PLAN_PATH>` stays a placeholder token in the
   template text itself, filled in with the plan file's **absolute path** at dispatch
   time, exactly as `<PLAN_CONTENT>` was before. Replace the "Replace `<PLAN_CONTENT>`
   with the full content..." instruction with: "Replace `<PLAN_PATH>` with the absolute
   path of the plan file read in Step 1. Read that file yourself, in your own context,
   before starting work — do not rely on any plan content being pasted into this
   prompt." After making this change, re-read both full dispatch templates end-to-end to
   confirm no remaining line embeds full plan content or instructs pasting it in (a plain
   instruction like "read the plan file" is fine and expected — only literal content
   embedding is the problem).

3. **Finding 3 — granularity checkpoint fires on every `plan` run.**
   `plan/SKILL.md:88-99`, heading `#### Granularity choice (before invoking
   writing-plans)` (line 90) inside `### Step 4`, is a plain subheading with no
   `⛔ CHECKPOINT ... MANDATORY` marker (unlike Checkpoint 1 at line 71 and Checkpoint 2
   at line 75). It currently presents three options (Fewer/larger, Balanced [default],
   More/smaller) every time.

   Fix: rewrite so the skill auto-selects "Balanced" and proceeds silently (no need to
   announce the choice to the user — it was already the documented default), and only
   surfaces the three-option question when the input ISSUE-N.md content clearly signals,
   in qualitative terms (no numeric thresholds), unusually large/complex or unusually
   trivial scope. Give 2-3 concrete example signals directly in the skill text so the
   trigger isn't left purely to interpretation, e.g.: scope spans multiple independent
   subsystems or user-facing flows; the description itself calls out unusual risk,
   migration, or rollback complexity; or the change is a single-line/trivial fix with no
   meaningful design decisions. Matches the judgment-based style of the plugin's other
   checkpoints — examples guide judgment, they don't replace it with a threshold.

4. **Finding 4 — recurring "File has not been read yet" failures in `subagent-driven-development` dispatch.**
   `implement/SKILL.md`'s Step 2 dispatch template (lines 75-78: "Use the
   `superpowers:subagent-driven-development` skill...", "Each task must follow
   `superpowers:test-driven-development`.", "Do NOT skip any step.") and its Step 4
   dispatch template both lack an explicit read-before-write rule. Because
   `subagent-driven-development` spawns a fresh, isolated subagent per task, a later task
   modifying a file an earlier task created trips the Edit/Write read-before-write guard —
   observed in transcript `9e2d66c8`, with a risky raw-shell-command workaround.

   Fix: add the following bullet, verbatim, to **both** the Step 2 and Step 4 dispatch
   prompt templates in `implement/SKILL.md` (Step 2: inserted after line 77, before the
   "Do NOT modify tests" line; Step 4: inserted at the equivalent position in its
   template):
   > "Before every use of the `Edit` tool on an existing file — even one you believe a
   > prior task already created — use the `Read` tool on it first, in this subagent's
   > own context; using `Write` to create a genuinely new file needs no prior Read. If
   > `Edit` or `Write` fails, `Read` the file (or confirm it doesn't exist) and retry the
   > same tool — never fall back to a raw shell command (e.g. `sed`, `cat >`) to force
   > the change through."

5. **Finding 5 — `verify` Step 3 always fails to invoke Codex review.**
   `verify/SKILL.md:65-67`, `### Step 3 — Technical review (Codex)`, currently reads:
   "Run `/codex:review --wait` to get an independent technical check from Codex on the
   same working tree." `codex:review` is a slash **command** (frontmatter
   `disable-model-invocation: true`), never callable via the `Skill` tool by the model —
   this step always errors as written.

   Fix: replace the instruction with a direct, non-interactive Bash invocation of the
   `codex` binary, run through the Bash tool (with a bounded timeout, e.g. the Bash
   tool's `timeout` parameter set to a few minutes) rather than the `Skill` tool:
   `codex review --uncommitted "Review the uncommitted changes in this working tree for
   correctness, adherence to the plan, and code quality. Report concrete issues found."`
   (300 second timeout)
   Add: if the `codex` binary is unavailable, the command exits non-zero (auth failure,
   etc.), or it hits the timeout, report that the Codex review could not run and let the
   user decide whether to proceed to Step 4 without it or stop and fix Codex access first
   — do not silently skip the step or block indefinitely. Any findings Codex does return
   are advisory input into `verify`'s overall PASS/FAIL determination alongside its other
   checks — they don't auto-fail the run on their own, but the model weighs them the same
   way it weighs findings from `verify`'s other steps when producing the final verdict.

6. **Finding 6 — ambiguous merge/cleanup wording in `verify` Step 7 (cosmetic).**
   `verify/SKILL.md:130-136`, `### Step 7 — Offer merge and cleanup (PASS only)`, asks:
   "The implementation is validated. Would you like to merge and clean up?" — reading as
   if `verify` performs the merge itself, though the "Yes" branch already hands off to
   `sdd:finalize`. No functional defect (confirmed against 2 real PASS transcripts).

   Fix: reword the question text only, to name `sdd:finalize` explicitly: "The
   implementation is validated. Would you like `sdd:finalize` to merge and clean up?"
   The Yes/No branch behavior itself is unchanged — Yes still invokes `sdd:finalize`, No
   still stops here — this edit touches only the question's wording, not the sub-options
   or control flow beneath it.

## Key decisions & tradeoffs
- **Path-passing over content-pasting (Finding 2):** trades a small risk (subagent must
  successfully Read the path) for a much larger context-pollution and staleness fix
  (parent thread's payload no longer scales with plan size, and can't hand the subagent a
  stale/paraphrased copy post-compaction).
- **Qualitative trigger for Finding 3, not numeric heuristics:** consistent with how the
  rest of the SDD plugin's checkpoints already work (judgment-based, not threshold-based);
  avoids a brittle rule that under- or over-fires on edge cases.
- **Finding 4 rule duplicated in both Step 2 and Step 4 templates**, rather than stated
  once and inherited by reference, so each dispatch prompt is self-contained and the rule
  survives even if one template is read/edited in isolation later.
- **Fixed `--uncommitted` flag for Finding 5**, not a dynamically chosen flag: `verify`
  always runs post-implementation, pre-commit, so the working tree is reliably
  uncommitted at this point — no need for conditional logic.
- **skill-creator mandated for implementation**, not raw edits: keeps the 5 SKILL.md
  files consistent with the plugin's own authoring/validation conventions rather than
  ad-hoc text surgery. Tradeoff: heavier than a plain Edit for what are individually
  small text changes — accepted because it also runs skill-creator's structural
  validation (frontmatter, heading hierarchy, step consistency) across all 6 edits,
  catching accidental structural breakage a raw Edit wouldn't.
- **Absolute path for Finding 2**, not relative: subagents in
  `subagent-driven-development` may not share the parent's assumed cwd, so a relative
  path is a latent failure; an absolute path removes that ambiguity entirely. Tradeoff:
  this puts local filesystem path strings into subagent prompts and session transcripts
  — accepted as a minor, low-sensitivity cost for local dev workflows, in exchange for
  correctness.
- **Same-session `/clear` exception for Finding 1's `finalize` handoff**: accepted
  tradeoff — this preserves the existing convenience of `verify` Step 7's automatic
  "Yes" handoff, at the cost of `finalize` sometimes running inside a larger
  verification-context session rather than a freshly cleared one. `finalize`'s own steps
  (git status, delegate to `commit-message`, ask about re-running tests) have no
  dependency on conversation history, so this cost is judged acceptable.

## Risks / open questions
None outstanding — all decisions were confirmed with the user during brainstorming
(idea slug, branch strategy, all 5 implicit assumptions, Finding 3/4/5 wording choices,
and the skill-creator requirement placement).

## Out of scope
- Finding 0 (initial hypothesis about repeated context growth from reading all
  ISSUE/PLAN/LOG files) — confirmed via transcript review to be expected behavior, not a
  defect. No action taken.
- Any code changes.
- Any changes to `superpowers:*` skills themselves (only how the 5 `sdd:*` skills invoke
  or dispatch them).
- Automated tests — none exist for these skills.

## Verification
For each of the 6 findings, after implementation:
1. Confirm the specific text change described above is present at the right location
   (by heading/section, not just line number).
2. Re-read the entire modified section (not just the new lines) end-to-end to confirm it
   still reads coherently — no duplicated instructions, no leftover reference to removed
   placeholders (e.g. no stray `<PLAN_CONTENT>` or `<plan>` tag left behind after Finding
   2's edit), no contradiction with adjacent steps.
3. Confirm no edits were made outside the 6 named sections — no incidental reflow or
   reformatting elsewhere in any of the 5 files.
4. For Finding 2 specifically: grep both `implement/SKILL.md` dispatch templates to
   confirm no remaining prompt text embeds full plan content. Also check
   `revise/SKILL.md` Step 2c — it should still only reference `implement`'s Steps 2/4
   pattern by name (no literal plan content of its own), which is the existing,
   unmodified behavior this spec doesn't change.
