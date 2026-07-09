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

## Output and Context Rules

This skill orchestrates git operations and other skills — the risk here is echoing raw command output or another skill's full output instead of a short conclusion. Apply these rules throughout:

- Never paste raw `git status --short` (or any git command) output into the conversation. Summarize it in one line (e.g., "3 fișiere modificate, niciun fișier nou" or "niciun fișier modificat — sar la Step 3").
- After `commit-message` completes, report only the commit message subject line and the fact that it succeeded — do not reproduce the full diff or the full body of the commit message unless the user asks.
- When invoking `finishing-a-development-branch`, relay only the decision points and final outcome to the user (options presented, choice made, result) — do not reproduce that skill's internal logs, git command output, or intermediate reasoning in the conversation.
- Keep the Step 3 test-rerun question to the two lines already specified — do not expand it with justification or history unless the user asks why.
- If any step's underlying command fails or produces an error, report the one-line cause, not the full stack trace or raw error dump — offer to show more only if the user asks.
- Default to the shortest accurate status update between steps (e.g., "Commit creat." / "Testele au fost deja verificate — sar peste re-rulare.").

## Process

### Step 1 — Check for pending changes

```bash
git status --short
```

If there are **no staged or unstaged changes** and no untracked files relevant to the work, skip to Step 3.

If there are pending changes, proceed to Step 2. Do not print the raw command output — summarize per the Output and Context Rules above.

### Step 2 — Commit all changes

Invoke the `commit-message` skill to stage and commit everything:

> Using `commit-message` to stage and commit all pending changes.

The `commit-message` skill will:
- Stage all modified and new files
- Generate a descriptive commit message
- Create the commit

Wait for the commit to complete before proceeding. Report only the commit subject line back to the user.

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

Follow that skill's instructions exactly from this point forward, but relay only decision points and outcomes to the user, per the Output and Context Rules above.
