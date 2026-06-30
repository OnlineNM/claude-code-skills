# Step 00 — Setup

**Reads:** Nothing — this is the first step.

**Does:**

### Git dirty-state check

Run `git status`. If there are any uncommitted, unstaged, or untracked files, tell the user to commit or stash changes before proceeding. Do NOT continue.

### Enter plan-mode

Call `EnterPlanMode` immediately. All work happens in plan-mode.

**Stop condition:** `git status` is clean AND plan-mode is active.

**Hands off:** Clean working tree, plan-mode active, control to `01-slug-and-branch.md`.
