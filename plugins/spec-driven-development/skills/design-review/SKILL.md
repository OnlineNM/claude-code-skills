---
name: design-review
description: Adversarial Codex review of an existing spec — Act 2 only. Codex reads the spec in a read-only sandbox, returns VERDICT: APPROVED or VERDICT: REVISE with concrete findings, and Claude iterates until convergence or MAX_ROUNDS cap. Use when user says "review my spec", "codex review spec", or already has a spec document and wants a cross-model stress-test before moving to implementation planning. For the full brainstorming + review flow use spec-me-codex instead.
---

# Spec-Me-Review — Adversarial Spec Review

Codex review only (Act 2). Use when you already have a spec and want a cross-model stress-test before implementation planning.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **high thinking effort** (`ultrathink`) for all reasoning in this skill.

## Language

Conduct all dialogue with the user — status updates, the resolution message, the "ready to move on" question — exclusively in Romanian, regardless of the language the spec was written in.

All deliverables this skill writes or edits (`docs/<idea-slug>-DESIGN.md`, `docs/<idea-slug>-DESIGN-REVIEW-LOG.md`) must always be written in English, independent of the Romanian dialogue above. The Codex review exchange also stays in English (Codex prompts and its verdicts are appended to the log as-is).

## Dialog Log

Maintain `docs/<idea-slug>-DIALOG.md` — a verbatim, human-readable record of the resolution message, the user's approval or final changes, and any deadlock tie-breaking decision. This is an explicit exception to the English-deliverables rule above: it exists to document the actual Romanian dialogue, so its content stays in Romanian, matching what was really said. Create it in Step 1 if it doesn't already exist (resume/append if it does). Use this format:

```markdown
# Dialog: <feature>
Început: <YYYY-MM-DD>

## <Subiect — ex. "Rezoluție", "Rezolvare impas">

**Întrebare:** <întrebarea/mesajul prezentat>
**Răspuns:** <răspunsul utilizatorului>

**Decizie:** <ce s-a stabilit, dacă e cazul>

---
```

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
| `VERDICT_FILE` | `/tmp/codex-verdict-<idea-slug>.txt` | Temp file for Codex output (unique per slug to avoid collisions) |

## Process

Resolve `SPEC_FILE` from args, or locate `*-DESIGN.md` in `docs/`. Derive `<idea-slug>` from the filename (e.g. `docs/user-auth-flow-DESIGN.md` → `user-auth-flow`). Set `VERDICT_FILE` to `/tmp/codex-verdict-<idea-slug>.txt`. Branch/worktree setup was handled by the preceding `/sdd:design-brainstorm` call — do not repeat it.

### Step 1 — Initialize and review

Initialize `LOG_FILE`:
```
# Spec Review Log: <feature>
spec-me-review started. MAX_ROUNDS=<n>. Reviewing: <SPEC_FILE>.
```

Create `docs/<idea-slug>-DIALOG.md` if it doesn't already exist (see "Dialog Log" section above for format); if it exists, resume appending to it.

### Review prompt strategy

Spec content is passed **inline** in the prompt — do NOT ask Codex to read from the filesystem (bwrap sandbox blocks it even without explicit sandbox flags). Claude reads `$SPEC_FILE` and embeds it directly.

### Round 1 — fresh session (capture thread_id)
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

### Rounds 2..MAX — resume same session
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

### Each round
1. Append Codex output to log:
   ```bash
   echo "## Round <n> — Codex" >> "$LOG_FILE"
   cat "$VERDICT_FILE" >> "$LOG_FILE"
   ```
2. Check last line of `$VERDICT_FILE` for verdict:
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
- **APPROVED:** Tell the user the spec path and round count. Ask: *"Spec survived N rounds of Codex. Please review `SPEC_FILE` and let me know if you approve or have any final changes."* Append this question and the user's answer to `docs/<idea-slug>-DIALOG.md`.

  On user approval, propose a git commit — list the files to be staged and ask for confirmation:
  - `$SPEC_FILE`
  - `$LOG_FILE`
  - `docs/<idea-slug>-DIALOG.md` (if it exists)

  On confirmation, commit with message `docs: <idea-slug> spec approved after Codex review`. Do NOT push. Do NOT invoke `writing-plans` automatically.

- **MAX_ROUNDS deadlock:** List each unresolved point + Claude's counter-position. Hand to user to break the tie. Append each unresolved point and the user's tie-breaking decision to `docs/<idea-slug>-DIALOG.md`. After the user resolves, follow the same approval → commit flow as above.

## Examples

**Typical REVISE → APPROVED flow (2 rounds):**

Round 1 — Codex returns:
```
1. Auth section doesn't specify token expiry — fix: add "tokens expire after 24h, refreshable once".
2. No rollback strategy for the migration step — fix: add "migration is reversible via down script".
VERDICT: REVISE
```

Claude revises `SPEC_FILE`, adding both fixes. Appended to log:
```
### Claude's response
Added token expiry (24h + refresh). Added rollback note to migration section. Rejected nothing.
```

Round 2 — Codex returns:
```
Both prior findings addressed. Spec is coherent and implementable.
VERDICT: APPROVED
```

Claude tells the user: *"Spec survived 2 rounds of Codex. Please review `SPEC_FILE` and let me know if you approve."*

## Hard Rules
- Pass spec content **inline** every round — do NOT use `-s read-only` or `-c sandbox_mode="read-only"`, and do NOT ask Codex to read from the filesystem path (bwrap blocks filesystem reads, Codex will fail silently and hallucinate).
- Loop ALWAYS terminates at `MAX_ROUNDS`.
- Claude is final arbiter on every REVISE — don't cave to everything, don't ignore it.
- Do NOT write code. Do NOT invoke `writing-plans` automatically.
- Do NOT commit to git automatically — only commit when the user **explicitly approves**.
