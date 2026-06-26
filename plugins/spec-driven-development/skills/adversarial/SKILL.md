---
name: adversarial
description: Use when the user wants to stress-test an existing spec document before implementation planning. Activate on phrases like "review my spec", "adversarial spec review", "codex review spec", or "cross-model review". Requires a completed spec file (e.g. docs/<idea-slug>-DESIGN.md) as input — do not use for brainstorming or drafting a spec from scratch.
---

> **Portable version of `design-review`.** This skill contains no Claude Code–specific dependencies and can be used with any agent runtime that has access to the Codex CLI. If you are using Claude Code, the `design-review` skill is equivalent and includes Claude Code–specific shortcuts (slash commands, effort level hints). Use this skill when running on Gemini CLI, Copilot CLI, Codex CLI, or any other agent environment.

# Overview

Runs an adversarial, multi-round review of an existing spec document using a secondary reviewer model (Codex). The reviewer returns a structured `VERDICT: APPROVED` or `VERDICT: REVISE` verdict with concrete findings each round. The primary model acts as final arbiter, deciding which findings to act on, revising the spec, and iterating until the reviewer approves or the round cap is reached.

This skill covers Act 2 only — adversarial review. It assumes a spec file already exists and that any branch or worktree setup was handled by a preceding brainstorming step.

## When to use

- The user has a completed spec document and wants an independent, skeptical review before committing to implementation planning.
- The user asks for a "cross-model stress-test" or "adversarial review" of a spec.
- The user wants to validate that a spec has no missing requirements, ambiguous behavior, security implications, or wrong assumptions before handing it off to developers.

## When NOT to use

- No spec document exists yet — use a brainstorming or spec-drafting skill first.
- The user wants to brainstorm or explore a feature idea — this skill does not produce specs, it reviews them.
- The user wants a human-style editorial review of prose or documentation — this skill is scoped to feature spec validation only.

## Instructions

> Before starting, verify the prerequisites listed in **Notes / Tooling**.

**Tunables — read from arguments, else use defaults:**

| Var | Default | Meaning |
|-----|---------|---------|
| `MAX_ROUNDS` | `5` | Hard cap on review rounds |
| `SPEC_FILE` | `docs/<idea-slug>-DESIGN.md` | Path to the spec to review |
| `LOG_FILE` | `docs/<idea-slug>-DESIGN-REVIEW-LOG.md` | Append-only review transcript |
| `VERDICT_FILE` | `/tmp/codex-verdict-<idea-slug>.txt` | Temp file for Codex output (use a unique name per slug to avoid collisions) |

1. Resolve `SPEC_FILE` from args, or locate `*-DESIGN.md` in `docs/`. Derive `<idea-slug>` from the filename (e.g. `docs/user-auth-flow-DESIGN.md` → `user-auth-flow`). Set `VERDICT_FILE` to `/tmp/codex-verdict-<idea-slug>.txt`.

2. Initialize `LOG_FILE` with the header:
   ```
   # Spec Review Log: <feature>
   spec-me-review started. MAX_ROUNDS=<n>. Reviewing: <SPEC_FILE>.
   ```

3. **Round 1 — fresh session.** Pass spec content inline (do NOT ask the reviewer to read from the filesystem — the sandbox blocks it):
   ```bash
   SPEC_CONTENT=$(cat "$SPEC_FILE")
   REVIEW_PROMPT="You are an adversarial reviewer for a feature spec. Be skeptical and specific — your job is to find what breaks, not to be agreeable. Here is the spec to review:

   ---
   ${SPEC_CONTENT}
   ---

   Identify concrete flaws: missing requirements, ambiguous behavior, security implications, wrong assumptions, scope creep risks, simpler alternatives. For each flaw, give a one-line fix. Do NOT modify any files. End your reply with EXACTLY one line: \`VERDICT: APPROVED\` if the spec is sound enough to proceed to implementation planning, or \`VERDICT: REVISE\` if it still has material problems."

   codex exec --json -o "$VERDICT_FILE" "$REVIEW_PROMPT" \
     2>/dev/null | grep '"type":"thread.started"'
   ```
   Parse `thread_id` from `{"type":"thread.started","thread_id":"..."}`. Critique is in `$VERDICT_FILE`.

4. **Rounds 2..MAX — resume same session:**
   ```bash
   SPEC_CONTENT=$(cat "$SPEC_FILE")
   codex exec resume "$THREAD_ID" --json \
     -o "$VERDICT_FILE" \
     "I revised the spec. Here is the updated version:

   ---
   ${SPEC_CONTENT}
   ---

   Re-review — check whether your prior findings are addressed and flag anything new. End with VERDICT: APPROVED or VERDICT: REVISE." \
     2>/dev/null >/dev/null
   ```

5. **After each round:**
   - Append Codex output to the log:
     ```bash
     echo "## Round <n> — Codex" >> "$LOG_FILE"
     cat "$VERDICT_FILE" >> "$LOG_FILE"
     ```
   - Check the last line of `$VERDICT_FILE`:
     - `VERDICT: APPROVED` → proceed to Resolution.
     - `VERDICT: REVISE` → the primary model decides what is worth acting on (primary model is final arbiter). Edit `SPEC_FILE` directly — no git commit. Append the response to the log:
       ```bash
       echo "### Primary model's response" >> "$LOG_FILE"
       echo "<what changed, what was rejected, why>" >> "$LOG_FILE"
       ```
       Increment round counter and repeat from step 4.
   - If round > `MAX_ROUNDS` → proceed to Resolution (deadlock).

6. **Resolution:**
   - **APPROVED:** Tell the user the spec path and round count. Ask: *"Spec survived N rounds of review. Please review `SPEC_FILE` and let me know if you approve or have any final changes."*
   - **MAX_ROUNDS deadlock:** List each unresolved point and the primary model's counter-position. Hand to the user to break the tie. After the user resolves, follow the same approval → commit flow.

7. **On explicit user approval**, propose a git commit — list the files to be staged and ask for confirmation:
   - `$SPEC_FILE`
   - `$LOG_FILE`

   On confirmation, commit with message `docs: <idea-slug> spec approved after Codex review`. Do NOT push. Do NOT proceed to implementation planning automatically.

## Output format

- **During review:** each round outputs the Codex verdict appended to `$LOG_FILE`. No console output of raw Codex text — summarize findings briefly.
- **At resolution:** a short summary stating the verdict, round count, and the paths of `$SPEC_FILE` and `$LOG_FILE`.
- **Commit summary** (on approval):
  ```
  Slug:      <idea-slug>
  Spec file: <SPEC_FILE>
  Log file:  <LOG_FILE>
  Rounds:    <n>
  ```

## Examples

**Typical REVISE → APPROVED flow (2 rounds):**

Round 1 — Codex returns:
```
1. Auth section doesn't specify token expiry — fix: add "tokens expire after 24h, refreshable once".
2. No rollback strategy for the migration step — fix: add "migration is reversible via down script".
VERDICT: REVISE
```

Primary model revises `SPEC_FILE`, adding both fixes. Appended to log:
```
### Primary model's response
Added token expiry (24h + refresh). Added rollback note to migration section. Rejected nothing.
```

Round 2 — Codex returns:
```
Both prior findings addressed. Spec is coherent and implementable.
VERDICT: APPROVED
```

Primary model tells the user: *"Spec survived 2 rounds of review. Please review `docs/user-auth-flow-DESIGN.md` and let me know if you approve."*

## Notes / Tooling

### Prerequisites — verify before starting

- `codex --version` ≥ 0.130 is installed
- Codex is authenticated (`codex login`; ChatGPT account is sufficient)
- Do NOT pin `-m` — ChatGPT-account auth rejects `gpt-5.x-codex` variants

### External dependency — Codex CLI

This skill requires the [OpenAI Codex CLI](https://github.com/openai/codex) (`codex`) ≥ 0.130 to be installed and authenticated. Without it the review loop cannot run.

- Install: follow the Codex CLI setup guide for your platform.
- Authenticate: `codex login` (ChatGPT account is sufficient; do NOT pin a specific model with `-m`).

### If using Claude Code

- The preceding brainstorming step is invoked as `/sdd:design-brainstorm`
- Maximum reasoning effort is specified as `ultrathink`
- Implementation planning skill is invoked as `/sdd:plan` or `writing-plans`

### Hard rules (enforced regardless of runtime)

- Pass spec content **inline** every round — do NOT use `-s read-only` or `-c sandbox_mode="read-only"`.
- The review loop ALWAYS terminates at `MAX_ROUNDS`.
- Do NOT write code.
- Do NOT commit to git automatically — only commit when the user explicitly approves.
