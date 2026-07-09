# Step 01 — Slug and Branch

**Reads:** Nothing new — continues from `00-setup.md`.

**Does:**

#### ⛔ CHECKPOINT 1 — Slug approval (MANDATORY, do not skip)

From the user's description, derive `<idea-slug>` using these rules:
- Lowercase, kebab-case
- Only `a-z`, `0-9`, `-`
- Replace spaces and punctuation with `-`
- Collapse multiple `-` into one
- Trim `-` from start and end
- Maximum 40 characters

Propose the slug and **wait for explicit confirmation before continuing**.

#### ⛔ CHECKPOINT 2 — Session file (MANDATORY, do not skip)

Immediately after the slug is confirmed, create `docs/<idea-slug>-SESSION.md`:

```markdown
# Discover: <Idea Name>
Started: <YYYY-MM-DD>

## Summary
<one-paragraph description of what's being discovered>

## Decisions Reached
<!-- updated after each confirmed answer -->

## Open Questions
<!-- updated as new questions surface -->
```

**Checkpoint invariant:** If `docs/<idea-slug>-SESSION.md` already exists, read it and resume — skip decisions already settled. Do not re-ask Checkpoint 1 or 2 if the session file shows them already resolved.

#### ⛔ CHECKPOINT 3 — Branch strategy (MANDATORY, do not skip)

Present exactly these three options and ask the user to choose one:
- **1. main** — work directly on the current branch
- **2. branch** — create and switch to `feature/<idea-slug>`
- **3. worktree** — create a git worktree at `../<idea-slug>` on branch `feature/<idea-slug>` (isolated workspace)

After the user picks, invoke `superpowers:using-git-worktrees` if option 3 was chosen.

**Stop condition:** Slug confirmed, session file created/resumed, branch strategy chosen and applied.

**Hands off:** Confirmed `<idea-slug>`, an existing or freshly created `docs/<idea-slug>-SESSION.md`, and the chosen workspace (main/branch/worktree) to `02-interview.md`.
