# Plan: Issue Implementation Log (milestone-log)

**For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task. Each task must follow superpowers:test-driven-development.

## Context

`sdd:plan` currently plans issue N using only the PRD text plus manual code reading — it has no visibility into what actually happened when issue N-1 was implemented. This can cause plans to miss decisions or divergences from the prior issue. `docs/milestone-log-DESIGN.md` (approved, brainstormed + Codex-reviewed) specifies a lightweight per-issue log file, written by `sdd:implement`, updated by `sdd:verify`, and read by `sdd:plan` for the immediate predecessor issue only. This plan translates that locked spec into edits across three skill files — no open design decisions remain.

These are markdown skill-instruction files, not application code with an automated test suite. "Tests" here means: manually re-read each edited SKILL.md for internal consistency, and dry-run the described logic against concrete example filenames to confirm the steps produce the right file paths and content.

## Files to modify

- `plugins/spec-driven-development/skills/implement/SKILL.md`
- `plugins/spec-driven-development/skills/verify/SKILL.md`
- `plugins/spec-driven-development/skills/plan/SKILL.md`

## Task 1 — `sdd:implement`: write the log after tests pass

File: `plugins/spec-driven-development/skills/implement/SKILL.md`

Insert a new **Step 6** immediately after the existing Step 5 ("Confirm", lines 106–110), before `## Hard Rules`:

```markdown
### Step 6 — Write issue log

Only if the plan file is `docs/<idea-slug>-PLAN-N.md` (an issue-derived plan, not a plain `docs/<idea-slug>-PLAN.md`):

Write `docs/<idea-slug>-ISSUE-N-LOG.md` (overwrite if it already exists — regenerate the whole file, do not merge with a prior version):

​```markdown
# Issue N Log: <issue title>

## What's new in the app
<bulleted, non-technical, user-facing capabilities added — scannable by a
non-technical reviewer. If this issue has no user-facing change (infra,
tests, refactor), write "No user-facing change.">

## What was built
<files created/modified, models/schema changes, routes/endpoints added,
public contracts, migrations, and any other decision a future issue may
depend on. Keep concise — target well under ~100 lines unless the issue
genuinely requires more detail.>

## Verification
Not yet verified
​```

Base `<issue title>` and the content on the actual final code/worktree state produced by Steps 2–4 — not the plan's intended work — in case implementation diverged from the plan (this is what Step 3's divergence check already surfaces).
```

If the plan is a plain `docs/<idea-slug>-PLAN.md` (DESIGN- or PRD-derived, no issue number), skip Step 6 entirely — no log file is written.

`## Hard Rules` needs no new rule — existing "Do NOT run inline" rules don't apply here since this is a direct file write, not a subagent dispatch. Leave Hard Rules as-is.

**Verification for this task:** Re-read the edited file. Confirm Step 1's existing slug/plan-number extraction (`docs/auth-forms-PLAN-1.md` → slug=`auth-forms`, plan=`1`) supplies exactly what Step 6 needs to build the path `docs/auth-forms-ISSUE-1-LOG.md`. Dry-run: for input `docs/auth-forms-PLAN-2.md`, Step 6 should describe writing `docs/auth-forms-ISSUE-2-LOG.md`.

## Task 2 — `sdd:verify`: update only the Verification section

File: `plugins/spec-driven-development/skills/verify/SKILL.md`

Insert a new **Step 6** between the existing Step 5 ("Consolidate and report", ends line 98) and the existing Step 6 ("Offer merge and cleanup", line 100 — renumber that one to Step 7):

```markdown
### Step 6 — Update issue log

Only if the plan file is `docs/<idea-slug>-PLAN-N.md` (an issue-derived plan):

1. Check whether `docs/<idea-slug>-ISSUE-N-LOG.md` exists.
2. If it does not exist, do not create one — just note in the Step 5 report that the expected log was missing (log creation is `sdd:implement`'s job, not this skill's).
3. If it exists, replace only the `## Verification` section's content (leave `## What's new in the app` and `## What was built` untouched). The first line must be exactly one of:
   - `Not yet verified` — should not normally be written here; this step always sets one of the other three.
   - `Verified` — plan compliance confirmed, no technical defects, all DoD items checked (verdict was PASS with nothing to note).
   - `Verified after fixes` — verdict reached PASS but only after issues found during this review were fixed; add bullets describing the fixes clearly enough that "What was built" (left untouched) isn't misleading on its own.
   - `Discrepancies remain` — verdict is REVISE; add at least one bullet naming the discrepancy and the affected file/behavior.
4. Optional bullets after the status line may summarize what was confirmed, what was fixed, or the discrepancies found in Steps 2–4.
```

This step runs regardless of PASS/REVISE verdict (the status line itself encodes the verdict), so it happens before the existing PASS-only "Offer merge and cleanup" step, which becomes Step 7.

**Verification for this task:** Re-read the edited file, confirm Step numbering is consistent (Step 6 new, Step 7 = old Step 6), and confirm every existing reference elsewhere in the file to "Step 6" (if any) was updated. Dry-run: a REVISE verdict on `docs/auth-forms-PLAN-2.md` should describe writing status `Discrepancies remain` with at least one bullet into `docs/auth-forms-ISSUE-2-LOG.md`, and should NOT trigger Step 7 (merge offer).

## Task 3 — `sdd:plan`: read the predecessor log

File: `plugins/spec-driven-development/skills/plan/SKILL.md`

First, confirm current Step 1 extraction (lines 31–38) already uses the rightmost `-ISSUE-<N>.md` suffix consistently with the `-PLAN-N.md` output naming — it does (shown by the existing example `docs/auth-forms-ISSUE-1.md → ... output = docs/auth-forms-PLAN-1.md`). No fix needed there.

Insert a new subsection at the end of **Step 1** (after line 38, before `### Step 2`):

```markdown
#### Predecessor log check (ISSUE inputs only)

If the input type is ISSUE and `N > 1`:
1. Check whether `docs/<idea-slug>-ISSUE-(N-1)-LOG.md` exists.
2. If it does not exist (issue 1, or the prior issue not yet implemented/logged), no-op — current behavior unchanged.
3. If it exists, read only that one file (not a glob of all prior issues) and hold it as **supplemental** context for Step 4 — it never overrides the current issue's spec, the PRD, or what the actual code shows.
   - If the log's `## Verification` reads "Not yet verified," treat its claims as lower-confidence and say so in the generated plan.
   - If the log's content contradicts the codebase, follow the codebase and add a short "Prior log discrepancy" note in the generated plan describing what differed.
```

No change needed to Step 2 (branch setup), Step 3 (enter plan-mode), Step 5 (commit), or Step 6 (confirm stop). Step 4 (writing-plans invocation) should be told to fold in this predecessor-log context when present — add one clause to OVERRIDE 1:

> **OVERRIDE 1 — input:** The feature description comes from the file read in Step 1, not from conversation context. If a predecessor log was found per the Predecessor log check above, include it as supplemental context (with any lower-confidence or discrepancy notes) alongside the primary input.

**Verification for this task:** Re-read the edited file. Dry-run: invoking on `docs/auth-forms-ISSUE-2.md` should check for `docs/auth-forms-ISSUE-1-LOG.md`; invoking on `docs/auth-forms-ISSUE-1.md` should skip the check (N=1); invoking on a DESIGN.md or PRD.md input should never trigger this subsection at all (it's ISSUE-only, matching Step 2's existing "PRD and ISSUE inputs only" pattern but narrower — issue-only).

## Out of scope (per DESIGN)

- No changes to `sdd:prd` folder structure or file naming.
- No new flags/options in any skill's frontmatter or invocation syntax.
- No cross-issue log aggregation.

## Verification (end-to-end)

1. Re-read all three edited SKILL.md files fully for internal consistency (step numbering, cross-references, terminology matching "idea-slug", "PLAN-N", "ISSUE-N").
2. Dry-run the full lifecycle on paper with a hypothetical 2-issue PRD (`docs/demo-ISSUE-1.md`, `docs/demo-ISSUE-2.md`):
   - `sdd:implement docs/demo-PLAN-1.md` → should describe writing `docs/demo-ISSUE-1-LOG.md` with Verification: "Not yet verified".
   - `sdd:verify docs/demo-PLAN-1.md` → should describe updating only `## Verification` in that log to "Verified" (or "Discrepancies remain" etc.), leaving other sections untouched.
   - `sdd:plan docs/demo-ISSUE-2.md` → should describe reading `docs/demo-ISSUE-1-LOG.md` as supplemental context.
3. Confirm no lifecycle step is described as running for a plain (non-issue) `docs/<slug>-PLAN.md`.
