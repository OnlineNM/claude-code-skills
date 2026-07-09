# Step 04 — Write DESIGN.md, Commit, Handoff

**Reads:** Confirmed restat from `03-confirm.md`.

**Does:**

### Write DESIGN.md

After explicit "yes", write `docs/<idea-slug>-DESIGN.md`:

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
git add docs/<idea-slug>-DESIGN.md docs/<idea-slug>-SESSION.md
git commit -m "docs: <idea-slug> intent confirmed"
```

### Handoff

Say: *"Intent confirmed and saved to `docs/<idea-slug>-DESIGN.md`. Run `/sdd:ideate docs/<idea-slug>-DESIGN.md` to explore solutions, or `/sdd:spec docs/<idea-slug>-DESIGN.md` to go straight to spec."*

**Stop condition:** DESIGN.md written and committed.

**Hands off:** Terminal step — control returns to the user.
