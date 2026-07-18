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
Each finding gets one targeted text edit at a precisely located line range (confirmed via
codebase exploration prior to brainstorming). The implementation phase (`/sdd:plan` →
`/sdd:implement`) must use the `skill-creator` skill to apply these 6 edits to the
SKILL.md files, rather than raw ad-hoc Edit/Write calls — this keeps the edits consistent
with the plugin's existing skill-authoring conventions and format.

1. **Finding 1 — missing `/clear` prompt in `finalize`.**
   `finalize/SKILL.md` has no `## Before Starting` section at all. Add one, identical in
   wording to `plan/SKILL.md:30-33` and `verify/SKILL.md:29-31`:
   > `## Before Starting`
   > Tell the user: *"Please run `/clear` first to start with a clean context, then
   > re-invoke this skill."* If the user has already cleared, proceed.

2. **Finding 2 — full plan content pasted into subagent dispatch prompts.**
   - `implement/SKILL.md:84` (Step 2 template, placeholder at line 71 inside
     `<plan>...</plan>`): currently "Replace `<PLAN_CONTENT>` with the full content of
     the plan file read in Step 1."
   - `implement/SKILL.md:116` (Step 4 template, placeholder at line 106): currently
     "Replace `<PLAN_CONTENT>` with the full content of the plan file."
   - `revise/SKILL.md:73-76` (Step 2c) has no literal placeholder — it delegates by
     reference to `implement`'s Steps 2/4 pattern, so it inherits the fix automatically
     once those two are changed; no separate edit needed there.

   Fix: in both `implement/SKILL.md` template blocks, replace the `<PLAN_CONTENT>`
   placeholder and its "replace with full content" instruction with the plan file's
   **path**, plus an explicit instruction telling the subagent to read that file itself
   at the start of its own context (e.g. "Read the plan file at `<PLAN_PATH>` before
   starting.").

3. **Finding 3 — granularity checkpoint fires on every `plan` run.**
   `plan/SKILL.md:88-99`, heading `#### Granularity choice (before invoking
   writing-plans)` (line 90) inside `### Step 4`, is a plain subheading with no
   `⛔ CHECKPOINT ... MANDATORY` marker (unlike Checkpoint 1 at line 71 and Checkpoint 2
   at line 75). It currently presents three options (Fewer/larger, Balanced [default],
   More/smaller) every time.

   Fix: rewrite so the skill auto-selects "Balanced" without asking, and only surfaces
   the three-option question when the input ISSUE-N.md content clearly signals, in
   qualitative terms (no numeric thresholds), unusually large/complex or unusually
   trivial scope — matching the judgment-based style of the plugin's other checkpoints.

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
   > "Before every Write or Edit on a file — even one you believe a prior task already
   > created — Read it first in this subagent's own context. Never fall back to a raw
   > shell command to bypass an Edit/Write failure; Read the file and retry the tool
   > instead."

5. **Finding 5 — `verify` Step 3 always fails to invoke Codex review.**
   `verify/SKILL.md:65-67`, `### Step 3 — Technical review (Codex)`, currently reads:
   "Run `/codex:review --wait` to get an independent technical check from Codex on the
   same working tree." `codex:review` is a slash **command** (frontmatter
   `disable-model-invocation: true`), never callable via the `Skill` tool by the model —
   this step always errors as written.

   Fix: replace the instruction with a direct Bash invocation of the `codex` binary:
   `codex review --uncommitted "..."`, run through the Bash tool rather than the `Skill`
   tool.

6. **Finding 6 — ambiguous merge/cleanup wording in `verify` Step 7 (cosmetic).**
   `verify/SKILL.md:130-136`, `### Step 7 — Offer merge and cleanup (PASS only)`, asks:
   "The implementation is validated. Would you like to merge and clean up?" — reading as
   if `verify` performs the merge itself, though the "Yes" branch already hands off to
   `sdd:finalize`. No functional defect (confirmed against 2 real PASS transcripts).

   Fix: reword the question to name `sdd:finalize` explicitly: "The implementation is
   validated. Would you like `sdd:finalize` to merge and clean up?"

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
  ad-hoc text surgery.

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
- Automated tests — none exist for these skills; verification is by re-reading the
  resulting SKILL.md text against this spec.
