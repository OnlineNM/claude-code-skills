---
name: finalize
description: Finalizes a development branch by committing all pending changes and then guiding the merge/PR flow. Use when the user says "finalize", "finish", "done with implementation", "merge this", "sdd:finalize", or wants to wrap up and integrate their work into main/master.
---

# SDD Finalize — Commit and Complete Development Branch

Commits all pending changes on the current branch (or worktree), then hands off to `superpowers:finishing-a-development-branch` for merge/PR options.

## Model & Thinking

Use **Claude Haiku** (`claude-haiku`) with **medium thinking effort** for all reasoning in this skill. This skill is orchestration, not judgment — checking git status, delegating to `commit-message`, asking a yes/no question, and handing off to `finishing-a-development-branch` — so it does not need a larger model.

## Language

Conduct all dialogue with the user — questions, status updates, presented options — exclusively in Romanian, regardless of the language used elsewhere in the session.

All deliverables this skill produces or drives (commit messages, merge/PR content) must always be written in English, independent of the Romanian dialogue above.

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

### Step 3 — Ask about re-running tests

Tests were already run during `sdd:implement` and `sdd:verify`. Ask the user:

> *"Should the finishing step re-run the full test suite? It was already run during implement/verify."*
> - **Yes** — re-run tests before presenting merge/PR options.
> - **No** (suggested) — skip re-running tests; treat them as already verified.

### Step 4 — Finish the branch

Invoke `superpowers:finishing-a-development-branch` to handle the remainder:

> Using `superpowers:finishing-a-development-branch` to complete the branch.

If the user answered **No** in Step 3, include this override with the invocation:

> **OVERRIDE:** Tests were already verified during `sdd:implement`/`sdd:verify` in this same session — skip Step 1 (test verification) and proceed directly to Step 2 (Detect Environment).

If the user answered **Yes**, invoke normally with no override — the skill runs its own test verification in Step 1.

This skill will then:
1. Verify tests pass (unless skipped per the override above)
2. Detect environment (normal repo vs worktree)
3. Present options: merge locally, create PR, keep as-is, or discard
4. Execute the chosen option and clean up if applicable

Follow that skill's instructions exactly from this point forward.
