# Step 04 — Write Issue Files

**Reads:** Approved issue list from `03-issue-breakdown.md`.

**Does:**

Write issues in dependency order (blockers first). For each approved issue, write directly to `docs/<idea-slug>-ISSUE-N.md` without displaying its full content in the console. After all files are written, tell the user: *"N issue files written to `docs/<idea-slug>-ISSUE-1.md` … `docs/<idea-slug>-ISSUE-N.md`. Please review them and let me know if you have any changes or if you approve."* If the user provides feedback, update the relevant files and ask again. Only commit all docs (PRD + issues) to git when the user **explicitly approves** (e.g. "looks good", "approve", "done", "ok"). Do NOT commit automatically.

Issue structure:

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

**Stop condition:** User explicitly approves all issue files; PRD + issues committed.

**Hands off:** Committed PRD and issue files to `05-handoff.md`.
