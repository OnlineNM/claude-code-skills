# Step 01 — Slug and Branch

**Reads:** Optional `docs/<slug>-DESIGN.md` path passed as invocation argument.

**Does:**

#### ⛔ CHECKPOINT 1 — Slug confirmation (MANDATORY, do not skip)

If a DESIGN.md path was passed as argument, derive the slug from the filename (e.g. `docs/auth-forms-DESIGN.md` → `auth-forms`). Propose it and wait for explicit confirmation.

If no argument was passed, ask the user to describe what they want to explore, then derive the slug from their description. Propose it and wait for confirmation.

#### ⛔ CHECKPOINT 2 — Session file (MANDATORY, do not skip)

Immediately after the slug is confirmed, create or resume `docs/<idea-slug>-SESSION.md`:

```markdown
# Ideate: <Idea Name>
Started: <YYYY-MM-DD>

## Summary
<one-paragraph description of what's being ideated>

## Decisions Reached
<!-- updated after each phase completes -->

## Open Questions
<!-- updated as new questions surface -->
```

**Checkpoint invariant:** If the session file already exists, read it and resume — skip decisions already settled (e.g. a phase already confirmed).

#### Branch detection

Check whether `feature/<idea-slug>` already exists:
- If yes: announce *"Branch `feature/<idea-slug>` detected — reusing it."* Switch to it.
- If no: run **CHECKPOINT 3** — present exactly these three options and ask the user to choose one:
  - **1. main** — work directly on the current branch
  - **2. branch** — create and switch to `feature/<idea-slug>`
  - **3. worktree** — create a git worktree at `../<idea-slug>` on branch `feature/<idea-slug>` (isolated workspace)

  After the user picks, invoke `superpowers:using-git-worktrees` if option 3 was chosen.

**Stop condition:** Slug confirmed, session file ready, branch resolved.

**Hands off:** Confirmed `<idea-slug>` and workspace state to `02-read-upstream.md`.
