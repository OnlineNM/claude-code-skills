# Step 03 — Draft the Issue Breakdown

**Reads:** Approved `docs/<idea-slug>-PRD.md` from `02-write-prd.md`.

**Does:**

Break the PRD into vertical slices (tracer bullets). Each slice cuts through ALL integration layers end-to-end.

**Before drafting the breakdown**, present exactly these three options and wait for the user's choice — sized for **issue/slice count**, not implementation tasks (task-level granularity belongs to `/sdd:plan`):
- **1. Fewer, larger slices** — fewer handoffs, larger PRs
- **2. Balanced** (default) — one slice per end-to-end user-visible behavior
- **3. More, smaller slices** — maximum AFK-friendly granularity, more sequencing overhead

Then present the proposed breakdown to the user as a numbered list showing: title, type (AFK/HITL), blocked by. Ask:
- Are the dependency relationships correct?
- Should any slices be merged or split, given the chosen granularity?

Iterate until the user approves.

**Slice rules:**
- Each slice delivers a narrow but complete path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- AFK = implementable by an agent without human interaction
- HITL = requires a human decision or design review
- Prefer many thin slices over few thick ones (within the chosen granularity option)

**Stop condition:** User approves the breakdown (granularity option + dependency graph).

**Hands off:** Approved issue list to `04-write-issues.md`.

## Dialog Log

Append an entry to `docs/<idea-slug>-DIALOG.md` recording the granularity options presented and the user's choice, plus a closing entry for the approved breakdown (including any merge/split iterations).
