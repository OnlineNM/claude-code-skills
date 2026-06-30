# Spec: SDD Skill Improvements
Started: 2026-06-30

## Summary
Borrow 4 patterns observed in buildermethods/bm-skills (bm-prd-creator) and apply them
to the local spec-driven-development plugin: (1) modularize large monolithic SKILL.md
files into step-files, (2) adopt a "propose defaults, then confirm" interaction pattern,
(3) add explicit milestone/plan granularity options with trade-offs, (4) enforce a strict
"what vs how" boundary in the PRD skill (no code/libraries/method names).

## Decisions Reached
- Slug confirmed: sdd-skill-improvements

## Open Questions
- Branch strategy (main / branch / worktree) — pending Checkpoint 3
- Exact skills in scope for #1 modularization (prd, discover, ideate — confirm all three?)
- Whether #4 (what-vs-how boundary) also applies to design-brainstorm's DESIGN.md, or PRD only
