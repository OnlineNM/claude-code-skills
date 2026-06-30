# Step 04 — Write INTENT.md, Commit, Handoff

**Reads:** Confirmed restat from `03-confirm.md`.

**Does:**

### Write INTENT.md

After explicit "yes", write `docs/<idea-slug>-INTENT.md`:

```markdown
# Intent: <Idea Name>
Confirmed: <YYYY-MM-DD>

## Outcome
<one line>

## User
<one line>

## Why Now
<one line>

## Success Criteria
<one line>

## Constraints
<one line>

## Out of Scope
<one line>
```

### Commit

```bash
git add docs/<idea-slug>-INTENT.md docs/<idea-slug>-SESSION.md
git commit -m "docs: <idea-slug> intent confirmed"
```

### Handoff

Say: *"Intent confirmed and saved to `docs/<idea-slug>-INTENT.md`. Run `/sdd:ideate docs/<idea-slug>-INTENT.md` to explore solutions, or `/sdd:design-brainstorm docs/<idea-slug>-INTENT.md` to go straight to spec."*

**Stop condition:** INTENT.md written and committed.

**Hands off:** Terminal step — control returns to the user.
