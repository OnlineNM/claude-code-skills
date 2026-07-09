# Step 06 — Commit and Handoff

**Reads:** Approved `docs/<idea-slug>-IDEATE.md` from `05-sharpen.md`.

**Does:**

`docs/<idea-slug>-SESSION.md` exists only to survive a context compaction mid-session — once IDEATE.md is written and about to be committed, its job is done. Delete it rather than committing it, so it never pollutes git history as a scratch file:

```bash
rm -f docs/<idea-slug>-SESSION.md
git add docs/<idea-slug>-IDEATE.md
git commit -m "docs: <idea-slug> ideation complete"
```

Say: *"Ideation complete. Run `/sdd:spec docs/<idea-slug>-IDEATE.md` to begin the spec."*

**Stop condition:** Committed.

**Hands off:** Terminal step — control returns to the user.
