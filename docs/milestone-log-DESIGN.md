# Spec: Issue Implementation Log
_Locked via brainstorming — by Claude + user_

## Goal
Give `sdd:plan` (and `sdd:implement`) visibility into what was actually built
in the immediately preceding issue of the same PRD, so planning/implementing
issue N doesn't rely solely on the PRD text plus manual code reading. Inspired
by the bm-skills milestone-log pattern, adapted to this repo's flat
`docs/<slug>-ISSUE-N.md` / `PLAN-N.md` file convention (see
`docs/milestone-log-INTENT.md`).

## Approach

**Artifact:** `docs/<slug>-ISSUE-N-LOG.md`, one per issue, flat in `docs/`
(same convention as `ISSUE-N.md` / `PLAN-N.md`).

**Format:**
```markdown
# Issue N Log: <issue title>

## What's new in the app
<bulleted, non-technical, user-facing capabilities added — scannable by a
non-technical reviewer>

## What was built
<files created/modified, models/schema changes, routes/endpoints added,
key decisions that affect future issues>

## Verification
<filled/updated by sdd:verify after it confirms plan compliance; empty or
"Not yet verified" if sdd:verify hasn't run>
```

**Writer / lifecycle:**
1. `sdd:implement`, Step 6 (new, after existing Step 5 "Implementation
   complete" confirmation): write `docs/<slug>-ISSUE-N-LOG.md` with the
   `What's new` and `What was built` sections filled in. `Verification`
   section starts as "Not yet verified."
2. `sdd:verify` (existing skill, run after implement): after it confirms plan
   compliance, it updates the `Verification` section of the same log file
   with what it confirmed (or discrepancies found/fixed).

**Discovery (in `sdd:plan`):**
- Always-on, no new flag. When `sdd:plan` is invoked on `docs/<slug>-ISSUE-N.md`:
  - If `N > 1` and `docs/<slug>-ISSUE-(N-1)-LOG.md` exists: read only that one
    file (not a glob of all prior issues) and use it as additional context
    alongside the PRD, to avoid unnecessary context load.
  - If it doesn't exist (issue 1, or prior issue not yet implemented/logged):
    no-op, current behavior unchanged.
- No change to `sdd:prd` — no new folder structure, no new options.

## Key decisions & tradeoffs
- **Only N-1's log, not all prior logs.** Cheaper context; assumes issues are
  implemented in order and that each log captures everything relevant a
  successor needs (transitively) from its own predecessor. Risk: if issue
  N-2 introduced a model that issue N cares about but N-1's log didn't
  mention it, that context is lost. Accepted tradeoff per user's explicit
  choice — favors low context cost over completeness.
- **Sequential-order assumption.** If issues are implemented out of order,
  `sdd:plan` for issue N looks for `ISSUE-(N-1)-LOG.md` specifically — if
  that issue hasn't been implemented yet, it's simply not found and the step
  no-ops. No special handling for out-of-order implementation.
- **Always-on, no opt-in flag.** Simpler; a single-issue PRD (or issue 1)
  degrades to current no-op behavior automatically, so there's no cost to
  making it default.
- **`sdd:verify` updates rather than replaces.** Keeps a single log file per
  issue as the source of truth instead of splitting into log + verify report.

## Risks / open questions
- If `sdd:verify` is skipped entirely for an issue, its log's `Verification`
  section permanently reads "Not yet verified." — acceptable, not blocking.
- Exact wording/subsections under "What was built" (e.g. explicit "Files
  changed" vs "Models" vs "Routes" subheadings) is left to `sdd:implement`'s
  judgment at write time rather than rigidly specified here.

## Out of scope
- No changes to `sdd:prd` (folder structure, file naming for ISSUE-N.md/PRD.md
  stay as-is).
- No new user-facing flags/options in any skill's frontmatter or invocation.
- No cross-PRD log aggregation or dashboard — logs are only consumed one
  file at a time by `sdd:plan` for the immediate next issue.

## Implementation touchpoints
- `plugins/spec-driven-development/skills/implement/SKILL.md` — add Step 6
  (write `ISSUE-N-LOG.md`) after existing Step 5.
- `plugins/spec-driven-development/skills/plan/SKILL.md` — add a check at
  Step 1 (slug/issue-number extraction) for `docs/<slug>-ISSUE-(N-1)-LOG.md`.
- `plugins/spec-driven-development/skills/verify/SKILL.md` — add a final
  step to append/update the `Verification` section of the issue's log file.
