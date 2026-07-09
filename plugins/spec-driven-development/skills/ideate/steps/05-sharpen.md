# Step 05 — Phase 3: Sharpen

**Reads:** Confirmed direction from `04-converge.md`.

**Does:**

After the user confirms a direction, write `docs/<idea-slug>-IDEATE.md`:

```markdown
# Ideate: <Idea Name>
Date: <YYYY-MM-DD>

## Problem Statement
<"How Might We" framing — one sentence>

## Recommended Direction
<The chosen direction and why — 2–3 paragraphs max>

## Key Assumptions to Validate
- [ ] <Assumption — how to test it>
- [ ] <Assumption — how to test it>

## MVP Scope
<Minimum version that tests the core assumption. What's in, what's out.>

## Not Doing (and Why)
- <Thing> — <reason>
- <Thing> — <reason>

## Open Questions
- <Question that needs answering before building>
```

Tell the user: *"IDEATE.md written to `docs/<idea-slug>-IDEATE.md`. Please review it and let me know if you have any changes or if you approve."*

If the user provides feedback, update the file and ask again. When they explicitly approve, proceed.

**Stop condition:** User explicitly approves the IDEATE.md content.

**Hands off:** Approved `docs/<idea-slug>-IDEATE.md` to `06-commit-and-handoff.md`.
