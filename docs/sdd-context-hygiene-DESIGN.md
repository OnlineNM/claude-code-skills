# Intent: SDD Context Hygiene
Confirmed: 2026-07-18

## Outcome
Apply the Finding 1-6 fixes from docs/sdd-context-hygiene-NOTES.md to the `plan`, `implement`, `verify`, `revise`, and `finalize` SKILL.md files of the `spec-driven-development` plugin.

## User
Users of the `sdd:*` skills, on real projects (e.g. `nats-msgs`).

## Why Now
Findings were confirmed against real session transcripts, not just theory — the goal is to fix them before the next real `sdd:plan`/`implement`/`verify` run hits the same failures again.

## Success Criteria
All 6 fixes applied exactly as described in NOTES.md, verified by re-reading the resulting SKILL.md text; no automated tests exist for these skills.

## Constraints
No code changes, no changes to `superpowers:*` skills — only the 5 SKILL.md files under `plugins/spec-driven-development/skills/`.

## Out of Scope
Finding 0 (confirmed not a defect, informational only).
