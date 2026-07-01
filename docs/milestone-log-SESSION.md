# Spec: Issue Implementation Log
Started: 2026-07-01

## Summary
Add an "issue implementation log" mechanism to the sdd plugin, inspired by
bm-skills' milestone-log pattern: after `sdd:implement` finishes an issue,
write a log capturing what was built; `sdd:plan` (and possibly
`sdd:implement`) for later issues in the same PRD reads the immediately
preceding issue's log for context, instead of relying only on the PRD.

## Decisions Reached
- Slug: `milestone-log`
- Input source: `docs/milestone-log-INTENT.md`
- Branch strategy: `branch` — `feature/milestone-log`
- Log artifact: `docs/<slug>-ISSUE-N-LOG.md`, flat, same convention as
  `ISSUE-N.md` / `PLAN-N.md`
- Writer: `sdd:implement` writes it (new Step 6, after existing Step 5);
  `sdd:verify` updates its `Verification` section afterward
- Discovery in `sdd:plan`: always-on, reads only `ISSUE-(N-1)-LOG.md` (not a
  glob of all prior logs), no-op if missing
- Sections: `## What's new in the app`, `## What was built`, `## Verification`
- No changes to `sdd:prd` (no new folder structure, no new flags)

## Open Questions
- None outstanding — resolved during Act 1 brainstorming.

## Final Spec Path: docs/milestone-log-DESIGN.md
