---
name: design-codex
description: Two-act spec hardening. ACT 1 (you ↔ Claude) — collaborative brainstorming produces an approved spec (2-3 approaches, visual companion, one question at a time). ACT 2 (Claude ↔ Codex) — OpenAI Codex adversarially reviews the spec in a read-only sandbox until APPROVED or MAX_ROUNDS cap. Use when user says "spec me codex", "spec and stress-test", or is defining a high-stakes feature (auth, schema, payments, concurrency) and wants collaborative exploration AND a cross-model sanity check before implementation planning.
---

# Spec-Me-Codex — Collaborative Spec + Adversarial Review

Two acts, two jobs:
- **Act 1** fixes the #1 failure mode: speccing the wrong thing.
- **Act 2** fixes the #2 failure mode: a spec that sounds right but breaks.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **high thinking effort** (`ultrathink`) for all reasoning in this skill.

## Language

Ask all questions in the same language the project/feature description was written in (Romanian or English). Every question and proposed approach must match that language. Internal reasoning, plan artifacts, and `SPEC.md` may stay in English regardless.

## Persistence

Maintain a session file at `docs/<idea-slug>-SESSION.md` to survive context compaction during long sessions.

**At the start:** check if the file exists. If yes, read it and resume — don't revisit already-settled decisions. If no, create it:
```markdown
# Spec: <Idea Name>
Started: <YYYY-MM-DD>

## Summary
<one-paragraph description of what's being specced>

## Decisions Reached
<!-- updated at each brainstorming checkpoint -->

## Open Questions
<!-- updated as new questions surface -->
```

**During the session:** update `Decisions Reached` and `Open Questions` after each major brainstorming checkpoint (approach chosen, design section approved, etc.).

**When Act 1 concludes:** append `## Final Spec Path: docs/<idea-slug>-DESIGN.md` to the session file.

## Before Starting

Tell the user: *"Please run `/clear` first to start with a clean context, then re-invoke this skill."*
If the user has already cleared, proceed.

---

## ACT 1 — SPEC (you ↔ Claude)

### Step 1 — Enter plan-mode
Call `EnterPlanMode` immediately.

### Step 2 — Identify idea-slug and branch strategy

1. From the user's description, derive `<idea-slug>`: kebab-case, 2-4 words (e.g. `user-auth-flow`). Propose it and confirm with the user.
2. Ask the user where work should be committed:
   - **main** — commit directly to the current branch
   - **branch** — create and switch to `feature/<idea-slug>`
   - **worktree** — create a git worktree at `../<idea-slug>` on branch `feature/<idea-slug>` using `superpowers:using-git-worktrees`
3. Set up the chosen environment before proceeding.

### Step 3 — Run brainstorming
Invoke `superpowers:brainstorming` with **two overrides**: do NOT invoke `writing-plans` at the end. And do NOT display the spec content in the console or commit automatically — see Step 3.

### Step 3 — Write SPEC.md
After the brainstorming is complete, write a structured summary directly to `docs/<idea-slug>-SPEC.md` without displaying its full content in the console:

```markdown
# Spec: <feature>
_Locked via brainstorming — by Claude + <user>_

## Goal
<one paragraph reflecting what brainstorming settled>

## Approach
<the chosen approach and key design decisions>

## Key decisions & tradeoffs
<contestable choices — give Codex something to bite>

## Risks / open questions
<anything still genuinely open>

## Out of scope
<explicit bounds established during brainstorming>
```

Initialize `docs/<idea-slug>-SPEC-REVIEW-LOG.md`:
```
# Spec Review Log: <feature>
Act 1 (brainstorming) complete — spec locked with user. MAX_ROUNDS=<n>.
```

After writing both files:
1. Tell the user: *"Spec written to `docs/<idea-slug>-SPEC.md`. Please review it and let me know if you have any changes or if you approve."*
2. If the user provides feedback, update `docs/<idea-slug>-SPEC.md` accordingly and ask again.
3. Only commit to git when the user **explicitly approves** (e.g. "looks good", "approve", "done", "ok"). Do NOT commit automatically.
4. After the commit (or user approval without changes), proceed to Act 2.

---

## ACT 2 — REVIEW (Claude ↔ Codex)

### Prerequisites
- `codex --version` ≥ 0.130
- Codex authenticated (`codex login`; ChatGPT account is fine)
- Do NOT pin `-m` — ChatGPT-account auth rejects `gpt-5.x-codex` variants

### Tunables (read from args, else default)
| Var | Default | Meaning |
|-----|---------|---------|
| `MAX_ROUNDS` | `5` | Hard cap on review rounds |
| `SPEC_FILE` | `docs/<idea-slug>-SPEC.md` | The spec Act 1 produced |
| `LOG_FILE` | `docs/<idea-slug>-SPEC-REVIEW-LOG.md` | Append-only argument transcript |

### Review prompt (sent each round)
> You are an adversarial reviewer for a feature spec. Be skeptical and specific — your job is to find what breaks, not to be agreeable. Read the spec at `SPEC.md` and any repo files you need (you are read-only). Identify concrete flaws: missing requirements, ambiguous behavior, security implications, wrong assumptions, scope creep risks, simpler alternatives. For each flaw, give a one-line fix. Do NOT modify any files. End your reply with EXACTLY one line: `VERDICT: APPROVED` if the spec is sound enough to proceed to implementation planning, or `VERDICT: REVISE` if it still has material problems.

### Round 1 — fresh session (capture thread_id)
```bash
codex exec -s read-only --json -o /tmp/codex-verdict.txt "$(cat REVIEW_PROMPT)" \
  2>/dev/null | grep '"type":"thread.started"'
```
Parse `thread_id` from `{"type":"thread.started","thread_id":"..."}`. Critique is in `/tmp/codex-verdict.txt`.

### Rounds 2..MAX — resume same session
```bash
codex exec resume "$THREAD_ID" -c sandbox_mode="read-only" --json \
  -o /tmp/codex-verdict.txt \
  "I revised the spec. Re-review SPEC.md — check whether your prior findings are addressed and flag anything new. End with VERDICT: APPROVED or VERDICT: REVISE." \
  2>/dev/null >/dev/null
```

### Each round
1. Read `/tmp/codex-verdict.txt`; append to `LOG_FILE`: `## Round <n> — Codex` + full critique.
2. Check last line for verdict:
   - `VERDICT: APPROVED` → Resolution.
   - `VERDICT: REVISE` → Claude decides what's worth acting on (Claude is final arbiter). Revise `SPEC_FILE`. Append `### Claude's response` to `LOG_FILE`: what changed, what was rejected, why. Increment round.
3. If round > `MAX_ROUNDS` → Resolution (deadlock).

### Resolution
- **APPROVED:** Present final `SPEC_FILE`, 3-bullet summary of what the two acts improved, round count. Ask: *"Spec grilled + survived N rounds of Codex. Ready to move to implementation planning?"* Do NOT invoke `writing-plans` automatically — wait for the user.
- **MAX_ROUNDS deadlock:** List each unresolved point + Claude's counter-position. Hand to user to break the tie.

---

## Hard Rules
- Act 1 always precedes Act 2 — no SPEC.md until brainstorming has actually resolved with the user.
- Codex is read-only EVERY round — `-s read-only` first call, `-c sandbox_mode="read-only"` on every resume.
- Loop ALWAYS terminates at `MAX_ROUNDS`.
- Claude is final arbiter on every REVISE — don't cave to everything, don't ignore it.
- Do NOT write code during either act.
- Do NOT invoke `writing-plans` automatically — that's the user's decision after sign-off.
