# Intent: Issue/Milestone Implementation Log for sdd plugin

## Context

Inspired by `bm-skills` (https://github.com/buildermethods/bm-skills), where a large PRD is split into milestones. When planning/implementing each milestone, the agent:
1. Reads the full PRD for context.
2. Reads previous milestones' logs (`milestones/<n>-*/milestone-log.md`) to know what has already been built.
3. Plans and implements ONLY the current milestone's scope.
4. Verifies the work against the "Done when" criteria in the PRD.
5. At the end, writes a `milestone-log.md` with:
   - `## What's new in the app` — a short, non-technical bullet list focused on user-facing capabilities.
   - Technical implementation details (files created, models added, routes added, etc.) — intended for the agent that will plan the next milestone.

## Problem in the current sdd flow

Our flow (`sdd:prd` → `sdd:plan` → `sdd:implement`) splits a PRD into individual issues, each planned and implemented separately (possibly across different sessions/`/clear`s). Currently, `sdd:plan` for issue N has no structured visibility into what was already built in issues 1..N-1 — it relies only on the PRD plus, at best, manual code reading.

## What we want to explore

Whether and how to add a similar "implementation log" mechanism per issue, which would be:
- Written automatically at the end of `sdd:implement` for the current issue.
- Read automatically by `sdd:plan` (and possibly `sdd:implement`) when planning/implementing a later issue from the same PRD.

## Open questions for brainstorming

- Where are the logs stored? (e.g. `docs/<slug>-issues/<n>-*/issue-log.md`, or next to the existing `ISSUE-N.md`)
- Exact log format (sections, what "What was built" contains)
- How does `sdd:plan` discover previous logs (folder glob, explicit list in the PRD?)
- What happens if issues are not implemented strictly in order
- Whether this mechanism should be opt-in or default for any PRD with multiple issues
- Impact on existing skills: `sdd:plan`, `sdd:implement`, possibly `sdd:prd` (folder structure)

## Goal

The outcome of this exploration should be a decision: whether or not to implement this mechanism, and if so, a spec (`DESIGN.md`) describing the log format and the changes needed in `sdd:plan`/`sdd:implement`.
