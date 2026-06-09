---
name: prd
description: Transforms a DESIGN.md spec into a PRD document and one markdown file per issue — all saved locally, no GitHub required. The user must pass the DESIGN.md path explicitly. Use when user says "prd-me", "create prd from spec", or wants to convert a spec file into a PRD and issues without pushing to GitHub.
---

# PRD-Me — Spec to PRD + Issues

Reads a DESIGN.md file and produces a structured PRD and one markdown file per issue.

## Invocation

The user must pass the DESIGN.md file path explicitly:

> `/prd-me docs/<idea-slug>-DESIGN.md`

If no path is provided, stop and ask: *"Please specify the DESIGN.md file path, e.g. `docs/auth-forms-DESIGN.md`."*

## Process

### Step 1 — Read the spec

Read the file at the provided path. Extract `<idea-slug>` from the filename:
- `docs/auth-forms-DESIGN.md` → `auth-slug` = `auth-forms`
- `docs/youtube-funnel-DESIGN.md` → `idea-slug` = `youtube-funnel`

If the file does not exist, stop and tell the user.

### Step 2 — Explore the codebase

Explore the repo to understand current state. Use the project's domain glossary vocabulary throughout. Respect any ADRs in the area being touched.

### Step 3 — Identify seams

Sketch out the testing seams for this feature. Prefer existing seams over new ones. Use the highest seam possible.

Check with the user that these seams match their expectations before proceeding.

### Step 4 — Write the PRD

Save to `docs/<idea-slug>-PRD.md`:

```markdown
# <Feature Name> — PRD

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

1. As a <actor>, I want <feature>, so that <benefit>

## Implementation Decisions

- Modules that will be built/modified
- Interface changes
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include file paths or code snippets unless a prototype snippet encodes a decision
more precisely than prose (state machine, schema, type shape) — inline it and note it came
from a prototype.

## Testing Decisions

- What makes a good test for this feature
- Which modules will be tested
- Prior art for the tests in the codebase

## Out of Scope

Explicit list of what this PRD does not cover.

## Further Notes

Any additional context.
```

### Step 5 — Draft the issues

Break the PRD into vertical slices (tracer bullets). Each slice cuts through ALL integration layers end-to-end.

Present the proposed breakdown to the user as a numbered list showing: title, type (AFK/HITL), blocked by. Ask:
- Does the granularity feel right?
- Are the dependency relationships correct?
- Should any slices be merged or split?

Iterate until the user approves.

**Slice rules:**
- Each slice delivers a narrow but complete path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- AFK = implementable by an agent without human interaction
- HITL = requires a human decision or design review
- Prefer many thin slices over few thick ones

### Step 6 — Write one file per issue

Write issues in dependency order (blockers first). For each approved issue, save to `docs/<idea-slug>-ISSUE-N.md`:

```markdown
# <Feature Name> — Issue N: <Title>

**Type:** AFK / HITL
**Blocked by:** None / `<idea-slug>-ISSUE-N.md`

## What to build

Concise description of this vertical slice — end-to-end behavior, not layer-by-layer.
Avoid file paths or code snippets unless a prototype snippet encodes a decision more
precisely than prose — inline it and note it came from a prototype.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
```

### Step 7 — Confirm

Tell the user:
> *"PRD saved to `docs/<idea-slug>-PRD.md`. N issues saved to `docs/<idea-slug>-ISSUE-1.md` … `docs/<idea-slug>-ISSUE-N.md`. To implement, pass each issue file to `/writing-plans`."*

## Output

- `docs/<idea-slug>-PRD.md` — structured PRD
- `docs/<idea-slug>-ISSUE-1.md` … `docs/<idea-slug>-ISSUE-N.md` — one file per vertical slice

## Hard Rules

- Do NOT proceed without reading the DESIGN.md file first.
- Do NOT push anything to GitHub.
- Do NOT write code.
- Do NOT invoke `writing-plans` or any implementation skill.
