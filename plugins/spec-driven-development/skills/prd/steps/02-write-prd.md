# Step 02 — Write the PRD

**Reads:** Confirmed seams from `01-seams.md`.

**Does:**

Write directly to `docs/<idea-slug>-PRD.md` without displaying its full content in the console. Just confirm the path. Then tell the user: *"PRD written to `docs/<idea-slug>-PRD.md`. Please review it and let me know if you have any changes before we move on to the issues breakdown."* If the user provides feedback, update the file and ask again. Proceed to `03-issue-breakdown.md` only after the user approves the PRD.

The PRD structure to use:

```markdown
# <Feature Name> — PRD

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

1. As a <actor>, I want <feature>, so that <benefit>

## Implementation Decisions

- Interface changes
- Architectural decisions
- Schema changes
- API contracts (only where externally relevant — see Scope Boundary below)
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

## Scope Boundary: What, Not How

Applies to `docs/<slug>-PRD.md` only — NOT to `docs/<slug>-ISSUE-N.md` files, which may continue to inline a prototype snippet per the existing rule ("unless a prototype snippet encodes a decision more precisely than prose").

In the Problem Statement, Solution, and User Stories sections: no code snippets, no method/function names, no file paths, no internal module names. User-facing or third-party platform/integration names ARE allowed where the user genuinely interacts with them (e.g. "sign in with Google", "export to Notion") — the boundary is *implementation technology* (how it's built), not *product surface* (what the user sees and touches).

Example — disallowed: "calls `validateSession()` in `auth/middleware.ts` using JWT." Example — allowed: "the user stays signed in across page reloads."

The Implementation Decisions section may name modules, schemas, and API contracts per the existing template, but only for contracts that are externally relevant (e.g. a public API shape another team integrates with) — not internal file/module references. The Testing Decisions section ("Which modules will be tested") is NOT subject to this boundary — naming internal modules there is fine, since it describes test scope rather than product-facing solution content. Before writing the PRD, scan the Implementation Decisions section against this rule and strip violations.

**Stop condition:** User explicitly approves the PRD content (after the Scope Boundary scan).

**Hands off:** Approved `docs/<idea-slug>-PRD.md` to `03-issue-breakdown.md`.

## Dialog Log

Append an entry to `docs/<idea-slug>-DIALOG.md` for each feedback round on the PRD draft, and a closing entry recording the user's final approval.
