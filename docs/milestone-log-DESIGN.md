# Spec: Issue Implementation Log
_Locked via brainstorming — by Claude + user_

## Goal
Give `sdd:plan` visibility into what was actually built in the immediately
preceding issue of the same PRD, so planning issue N doesn't rely solely on
the PRD text plus manual code reading. Inspired
by the bm-skills milestone-log pattern, adapted to this repo's flat
`docs/<slug>-ISSUE-N.md` / `PLAN-N.md` file convention (see
`docs/milestone-log-INTENT.md`).

## Approach

**Artifact:** `docs/<slug>-ISSUE-N-LOG.md`, one per issue, flat in `docs/`
(same convention as `ISSUE-N.md` / `PLAN-N.md`).

**Filename parsing:** reuse the same slug/issue-number extraction `sdd:plan`
already does for `docs/<slug>-ISSUE-N.md` → `docs/<slug>-PLAN-N.md` (rightmost
`-ISSUE-<N>.md` suffix). The log for that issue is
`docs/<slug>-ISSUE-N-LOG.md`; the predecessor log `sdd:plan` looks for is the
same slug with `N-1`.

**Format:**
```markdown
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
<first line: one of "Not yet verified" | "Verified" | "Verified after fixes"
| "Discrepancies remain". Followed by optional bullets giving detail — e.g.
what was confirmed, what was fixed, or (required when the status is
"Discrepancies remain") at least one bullet naming the discrepancy and the
affected file/behavior. When status is "Verified after fixes," the bullets
must describe the fixes clearly enough that `What was built` (left untouched
by sdd:verify) is not misleading on its own. Set by sdd:verify; see
lifecycle below.>
```

**Writer / lifecycle:**
1. `sdd:implement`, Step 6 (new, after existing Step 5 "Implementation
   complete" confirmation): write `docs/<slug>-ISSUE-N-LOG.md` with the
   `What's new` and `What was built` sections filled in, describing the
   actual final code/worktree state — not the plan's intended work — in
   case implementation diverged from the plan. `Verification`
   section starts as "Not yet verified." If `sdd:implement` is rerun for the
   same issue, it regenerates the whole file (overwrite, not merge) and
   resets `Verification` to "Not yet verified."
2. `sdd:verify` (existing skill, run after implement): after checking plan
   compliance, it replaces only the `## Verification` section's content
   (leaving `What's new` / `What was built` untouched) with the status line
   and detail bullets described above. If the log file doesn't exist when
   `sdd:verify` runs, it doesn't create one, but notes in its own output that
   the expected log was missing (log creation stays `sdd:implement`'s job).

**Discovery (in `sdd:plan`):**
- Always-on, no new flag. When `sdd:plan` is invoked on `docs/<slug>-ISSUE-N.md`:
  - If `N > 1` and `docs/<slug>-ISSUE-(N-1)-LOG.md` exists: read only that one
    file (not a glob of all prior issues) and use it as **supplemental**
    context alongside the PRD — it never overrides the current issue's spec,
    the PRD, or what the actual code shows. If the log's content contradicts
    the codebase, `sdd:plan` follows the codebase and adds a short "Prior log
    discrepancy" note in the generated plan describing what differed.
  - If the predecessor log's `Verification` still reads "Not yet verified,"
    `sdd:plan` treats its claims as lower-confidence and says so in the
    generated plan.
  - If it doesn't exist (prior issue not yet implemented or not yet logged):
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
- **Concision over exhaustiveness.** A soft ~100-line target keeps the
  always-on N-1 read cheap; this is guidance for the writing agent, not a
  hard limit.

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
  Verify during implementation that `sdd:plan`'s current extraction already
  uses the rightmost `-ISSUE-<N>.md` suffix; if not, fix it consistently for
  both the existing issue→plan path and the new issue→log path.
- `plugins/spec-driven-development/skills/verify/SKILL.md` — add a final
  step that replaces only the `## Verification` section's content in the
  issue's log file (no-op with a note if the log file is missing).
