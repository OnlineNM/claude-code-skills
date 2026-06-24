# Spec: SDD Plugin Enhancements
Started: 2026-06-24

## Summary
Improvements to the `plugins/spec-driven-development` plugin inspired by analysis of the `agent-skills` repository (addyosmani/agent-skills). The changes touch existing skills (`design`, `plan`, `implement`, `verify`) and add two new skills (`sdd:discover` and `sdd:ideate`), with the goal of making the pipeline more robust at requirement extraction, assumption surfacing, and implementation quality gates.

## Decisions Reached

- All 8 improvements in one spec, single implementation cycle (Approach A)
- `discover` and `ideate` are optional pre-steps — pipeline can be entered at any level
- `discover` produces `docs/<slug>-INTENT.md` (explicit artifact, committed to git)
- `ideate` produces `docs/<slug>-IDEATE.md` (explicit artifact, committed to git)
- `discover` → `ideate` → `design` are sequentially optional (B)
- `design` auto-detects INTENT/IDEATE by slug and announces what it found (C)
- "Spec as living document": separate sub-step in `implement` — Claude reads DESIGN.md + diff after implementation subagent, proposes updates (C)
- `design-codex` receives same changes as `design` (items 1, 2, upstream detection)
- `ideate` CHECKPOINT 1+2 always run; CHECKPOINT 3 skipped if branch already exists
- `ideate` includes EnterPlanMode as step 0

## Open Questions
<!-- none remaining -->
