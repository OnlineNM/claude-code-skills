---
name: finish
description: Finishes a development branch by committing all pending changes and then guiding the merge/PR flow. Use when the user says "finish", "done with implementation", "merge this", "sdd:finish", or wants to wrap up and integrate their work into main/master.
---

# SDD Finish — Commit and Complete Development Branch

Commits all pending changes on the current branch (or worktree), then hands off to `superpowers:finishing-a-development-branch` for merge/PR options.

## Process

### Step 1 — Check for pending changes

```bash
git status --short
```

If there are **no staged or unstaged changes** and no untracked files relevant to the work, skip to Step 3.

If there are pending changes, proceed to Step 2.

### Step 2 — Commit all changes

Invoke the `commit-message` skill to stage and commit everything:

> Using `commit-message` to stage and commit all pending changes.

The `commit-message` skill will:
- Stage all modified and new files
- Generate a descriptive commit message
- Create the commit

Wait for the commit to complete before proceeding.

### Step 3 — Finish the branch

Invoke `superpowers:finishing-a-development-branch` to handle the remainder:

> Using `superpowers:finishing-a-development-branch` to complete the branch.

This skill will:
1. Verify tests pass
2. Detect environment (normal repo vs worktree)
3. Present options: merge locally, create PR, keep as-is, or discard
4. Execute the chosen option and clean up if applicable

Follow that skill's instructions exactly from this point forward.
