---
name: design-review
description: Adversarial Codex review of an existing spec — Act 2 only. Codex reads the spec in a read-only sandbox, returns VERDICT: APPROVED or VERDICT: REVISE with concrete findings, and Claude iterates until convergence or MAX_ROUNDS cap. Use when user says "review my spec", "codex review spec", or already has a spec document and wants a cross-model stress-test before moving to implementation planning. For the full brainstorming + review flow use spec-me-codex instead.
---

# Spec-Me-Review — Adversarial Spec Review

Codex review only (Act 2). Use when you already have a spec and want a cross-model stress-test before implementation planning.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **high thinking effort** (`ultrathink`) for all reasoning in this skill.

Pass the spec file path as an argument (ex: `docs/<idea-slug>-DESIGN.md`), or place `<idea-slug>-DESIGN.md` în directorul `docs/`.

## Prerequisites
- `codex --version` ≥ 0.130
- Codex authenticated (`codex login`; ChatGPT account is fine)
- Do NOT pin `-m` — ChatGPT-account auth rejects `gpt-5.x-codex` variants

## Tunables (read from args, else default)
| Var | Default | Meaning |
|-----|---------|---------|
| `MAX_ROUNDS` | `5` | Hard cap on review rounds |
| `SPEC_FILE` | `docs/<idea-slug>-DESIGN.md` | Path to the spec to review |
| `LOG_FILE` | `docs/<idea-slug>-DESIGN-REVIEW-LOG.md` | Append-only argument transcript |

## Process

Resolve `SPEC_FILE` from args, or locate `*-DESIGN.md` in `docs/`. Derive `<idea-slug>` from the filename (e.g. `docs/user-auth-flow-DESIGN.md` → `user-auth-flow`). Branch/worktree setup was handled by the preceding `/sdd:design` call — do not repeat it.

### Step 1 — Initialize and review

Initialize `LOG_FILE`:
```
# Spec Review Log: <feature>
spec-me-review started. MAX_ROUNDS=<n>. Reviewing: <SPEC_FILE>.
```

### Review prompt
> You are an adversarial reviewer for a feature spec. Be skeptical and specific — your job is to find what breaks, not to be agreeable. Read the spec at `<SPEC_FILE>` and any repo files you need (you are read-only). Identify concrete flaws: missing requirements, ambiguous behavior, security implications, wrong assumptions, scope creep risks, simpler alternatives. For each flaw, give a one-line fix. Do NOT modify any files. End your reply with EXACTLY one line: `VERDICT: APPROVED` if the spec is sound enough to proceed to implementation planning, or `VERDICT: REVISE` if it still has material problems.

### Round 1 — fresh session (capture thread_id)
```bash
codex exec --json -o /tmp/codex-verdict.txt "$(cat REVIEW_PROMPT)" \
  2>/dev/null | grep '"type":"thread.started"'
```
Parse `thread_id` from `{"type":"thread.started","thread_id":"..."}`. Critique is in `/tmp/codex-verdict.txt`.

### Rounds 2..MAX — resume same session
```bash
codex exec resume "$THREAD_ID" --json \
  -o /tmp/codex-verdict.txt \
  "I revised the spec. Re-review <SPEC_FILE> — check whether your prior findings are addressed and flag anything new. End with VERDICT: APPROVED or VERDICT: REVISE." \
  2>/dev/null >/dev/null
```

### Each round
1. Append Codex output to log:
```bash
echo "## Round <n> — Codex" >> "$LOG_FILE"
cat /tmp/codex-verdict.txt >> "$LOG_FILE"
```
2. Check last line of `/tmp/codex-verdict.txt` for verdict:
   - `VERDICT: APPROVED` → Resolution.
   - `VERDICT: REVISE` → Claude decides what's worth acting on (Claude is final arbiter). Revise `SPEC_FILE` (file edit only — no git commit). Then append Claude's response to log:
```bash
echo "### Claude's response" >> "$LOG_FILE"
echo "<what changed, what was rejected, why>" >> "$LOG_FILE"
```
   Increment round.
3. If round > `MAX_ROUNDS` → Resolution (deadlock).

**No git commits during the review loop** — only the final spec (after user approval) is committed.

### Resolution
- **APPROVED:** Tell the user the spec path and round count. Ask: *"Spec survived N rounds of Codex. Please review `SPEC_FILE` and let me know if you approve or have any final changes."* Wait for explicit user approval before committing. Do NOT invoke `writing-plans` automatically.
- **MAX_ROUNDS deadlock:** List each unresolved point + Claude's counter-position. Hand to user to break the tie. Wait for explicit user approval before committing.

## Hard Rules
- Codex runs without sandbox flags — `-s read-only` / `-c sandbox_mode="read-only"` block filesystem reads via bwrap and must NOT be used.
- Loop ALWAYS terminates at `MAX_ROUNDS`.
- Claude is final arbiter on every REVISE — don't cave to everything, don't ignore it.
- Do NOT write code. Do NOT invoke `writing-plans` automatically.
- Do NOT commit to git automatically — only commit when the user **explicitly approves**.
