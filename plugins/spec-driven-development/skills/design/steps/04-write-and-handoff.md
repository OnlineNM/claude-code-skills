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

`docs/<idea-slug>-SESSION.md` exists only to survive a context compaction mid-session — once DESIGN.md is written and about to be committed, its job is done. Delete it rather than committing it, so it never pollutes git history as a scratch file:

```bash
rm -f docs/<idea-slug>-SESSION.md
git add docs/<idea-slug>-DESIGN.md
git commit -m "docs: <idea-slug> intent confirmed"
```

### Handoff

Say: *"Intent confirmed and saved to `docs/<idea-slug>-DESIGN.md`. Run `/sdd:ideate docs/<idea-slug>-DESIGN.md` to explore solutions, or `/sdd:spec docs/<idea-slug>-DESIGN.md` to go straight to spec."*

**Stop condition:** DESIGN.md written and committed.

**Hands off:** Terminal step — control returns to the user.
