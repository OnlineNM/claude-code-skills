---
name: design-adversarial
description: Two-act spec hardening. ACT 1 (you ↔ Claude) — collaborative brainstorming produces an approved spec (2-3 approaches, visual companion, one question at a time). ACT 2 (Claude ↔ Codex) — OpenAI Codex adversarially reviews the spec (content passed inline — no filesystem sandbox) until APPROVED or MAX_ROUNDS cap. Use when user says "spec me codex", "spec and stress-test", or is defining a high-stakes feature (auth, schema, payments, concurrency) and wants collaborative exploration AND a cross-model sanity check before implementation planning.
---

# Spec-Me-Codex — Collaborative Spec + Adversarial Review

Two acts, two jobs:
- **Act 1** fixes the #1 failure mode: speccing the wrong thing.
- **Act 2** fixes the #2 failure mode: a spec that sounds right but breaks.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **high thinking effort** (`ultrathink`) for all reasoning in this skill.

## Language

Conduct all dialogue with the user — questions, proposed approaches, confirmations, status updates — exclusively in Romanian, regardless of the language the project/feature description was written in.

All deliverables this skill writes (`docs/<idea-slug>-SESSION.md`, `docs/<idea-slug>-DESIGN.md`, `docs/<idea-slug>-DESIGN-REVIEW-LOG.md`) must always be written in English, independent of the Romanian dialogue above. Internal reasoning and the Codex review exchange also stay in English. When a decision reached in Romanian dialogue is captured in a deliverable, translate it into English rather than copying the Romanian wording verbatim.

## Dialog Log

Maintain `docs/<idea-slug>-DIALOG.md` throughout the session — a verbatim, human-readable record of every question asked, the user's answer, the approaches proposed, and the decisions reached (including Act 2's deadlock resolutions, if any). This file is an explicit exception to the English-deliverables rule above: it exists to document the actual Romanian dialogue, so its content stays in Romanian, matching what was really said.

Creation is handled by ⛔ CHECKPOINT 2, alongside `SESSION.md`. Use this format — one heading per topic, one paragraph per question/answer pair:

```markdown
# Dialog: <Idea Name>
Început: <YYYY-MM-DD>

## <Subiect — ex. "Ipoteze", "Abordarea aleasă", "Rezolvare impas Act 2">

**Întrebare:** <întrebarea pusă>
**Răspuns:** <răspunsul utilizatorului>

**Decizie:** <ce s-a stabilit, dacă e cazul>

---
```

Because Step 4 delegates the actual interview to `superpowers:brainstorming`, pass it an additional override (below) instructing it to append to this file as it goes — it cannot know about `DIALOG.md` otherwise.

## Persistence

Maintain `docs/<idea-slug>-SESSION.md` throughout the session. Creation is handled by ⛔ CHECKPOINT 2 — this section describes upkeep only.

**During the session:** update `Decisions Reached` and `Open Questions` after each major brainstorming checkpoint (approach chosen, design section approved, etc.).

**When Act 1 concludes:** append `## Final Spec Path: docs/<idea-slug>-DESIGN.md` to the session file.

## Before Starting

Tell the user: *"Please run `/clear` first to start with a clean context, then re-invoke this skill."*
If the user has already cleared, proceed.

---

## ACT 1 — SPEC (you ↔ Claude)

### Step 1 — Git dirty-state check
Run `git status`. If there are any uncommitted, unstaged, or untracked files, tell the user to commit or stash changes before proceeding. Do NOT continue.

### Step 2 — Enter plan-mode
Call `EnterPlanMode` immediately.

### Step 3 — Identify idea-slug and branch strategy

#### ⛔ CHECKPOINT 1 — Slug approval (MANDATORY, do not skip)

1. From the user's description, derive `<idea-slug>` using these rules:
   - Lowercase, kebab-case
   - Only `a-z`, `0-9`, `-`
   - Replace spaces and punctuation with `-`
   - Collapse multiple `-` into one
   - Trim `-` from start and end
   - Maximum 40 characters

   Propose the slug to the user and **wait for explicit confirmation before continuing**. Do NOT proceed until the user approves or corrects it.

#### ⛔ CHECKPOINT 2 — Session file (MANDATORY, do not skip)

Immediately after the slug is confirmed, create `docs/<idea-slug>-SESSION.md`. Do this **now** — before the branch question, before brainstorming, before anything else. Do not defer or skip this because the session feels "short" or "simple": short sessions still get interrupted by context compaction.

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

If the file already exists, read it and resume — skip decisions already settled.

Also create `docs/<idea-slug>-DIALOG.md` at this point (see "Dialog Log" section above for format). If it already exists, resume appending to it instead of overwriting.

#### ⛔ CHECKPOINT 3 — Branch strategy (MANDATORY, do not skip)

2. Present exactly these three options and ask the user to choose one — do not reduce to two:
   - **1. main** — commit directly to the current branch
   - **2. branch** — create and switch to `feature/<idea-slug>`
   - **3. worktree** — create a git worktree at `../<idea-slug>` on branch `feature/<idea-slug>` (isolated workspace, recommended for longer specs)
   
   After the user picks, invoke `superpowers:using-git-worktrees` if option 3 was chosen.
3. Set up the chosen environment before proceeding.

### Step 4 — Run brainstorming

**Before brainstorming**, check `docs/` for upstream artifacts from this slug:
1. If `docs/<slug>-IDEATE.md` exists: announce *"Found `docs/<slug>-IDEATE.md` — using it as the starting point for brainstorming."* Start brainstorming from its content instead of the raw user description.
2. Else if `docs/<slug>-INTENT.md` exists: announce *"Found `docs/<slug>-INTENT.md` — using it as the starting point for brainstorming."* Start brainstorming from its content instead of the raw user description.
3. If neither exists: start brainstorming from the user's raw description (current behavior).

**Before invoking brainstorming**, surface all implicit assumptions the user has not stated:

```
ASSUMPTIONS I'M MAKING:
1. [assumption about stack / tech]
2. [assumption about audience]
3. [assumption about constraints or scope]
→ Correct me now or I'll proceed with these.
```

Do not begin brainstorming until the user explicitly confirms or corrects the list. Append this exchange (the assumptions list and the user's confirmation/corrections) to `docs/<idea-slug>-DIALOG.md`.

**Success criteria override:** Whenever the user describes a vague objective (e.g. "make it faster", "improve UX"), reframe it as concrete, measurable success criteria before writing a spec section:

```
REQUIREMENT: "Make it faster"

REFRAMED SUCCESS CRITERIA:
- [specific measurable condition, e.g. "LCP < 2.5s on 4G"]
- [specific measurable condition]
→ Are these the right targets?
```

Do not write a spec section for an objective that cannot be directly verified.

Invoke `superpowers:brainstorming` with **three overrides**: do NOT invoke `writing-plans` at the end; do NOT display the spec content in the console or commit automatically — see Step 5; and after each clarifying question is answered, after each approach/direction the user picks, and after each design section is approved, append an entry to `docs/<idea-slug>-DIALOG.md` (format defined above) recording the question/option presented and the user's answer/choice, incrementally as it happens.

### Step 5 — Write DESIGN.md
After the brainstorming is complete, write a structured summary directly to `docs/<idea-slug>-DESIGN.md` without displaying its full content in the console:

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

Initialize `docs/<idea-slug>-DESIGN-REVIEW-LOG.md`:
```
# Spec Review Log: <feature>
Act 1 (brainstorming) complete — spec locked with user. MAX_ROUNDS=<n>.
```

After writing both files:
1. Tell the user: *"Spec written to `docs/<idea-slug>-DESIGN.md`. Please review it and let me know if you have any changes or if you approve."*
2. If the user provides feedback, update `docs/<idea-slug>-DESIGN.md` accordingly and ask again.
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
| `SPEC_FILE` | `docs/<idea-slug>-DESIGN.md` | The spec Act 1 produced |
| `LOG_FILE` | `docs/<idea-slug>-DESIGN-REVIEW-LOG.md` | Append-only argument transcript |

### Review prompt strategy

Spec content is passed **inline** in the prompt — do NOT rely on Codex reading from the filesystem (bwrap sandbox blocks it). Claude reads `$SPEC_FILE` and embeds it directly.

### Round 1 — fresh session (capture thread_id)
```bash
SPEC_CONTENT=$(cat "$SPEC_FILE")
REVIEW_PROMPT="You are an adversarial reviewer for a feature spec. Be skeptical and specific — your job is to find what breaks, not to be agreeable. Here is the spec to review:

---
${SPEC_CONTENT}
---

Identify concrete flaws: missing requirements, ambiguous behavior, security implications, wrong assumptions, scope creep risks, simpler alternatives. For each flaw, give a one-line fix. Do NOT modify any files. End your reply with EXACTLY one line: \`VERDICT: APPROVED\` if the spec is sound enough to proceed to implementation planning, or \`VERDICT: REVISE\` if it still has material problems."

codex exec --json -o /tmp/codex-verdict.txt "$REVIEW_PROMPT" \
  2>/dev/null | grep '"type":"thread.started"'
```
Parse `thread_id` from `{"type":"thread.started","thread_id":"..."}`. Critique is in `/tmp/codex-verdict.txt`.

### Rounds 2..MAX — resume same session
```bash
SPEC_CONTENT=$(cat "$SPEC_FILE")
codex exec resume "$THREAD_ID" --json \
  -o /tmp/codex-verdict.txt \
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
cat /tmp/codex-verdict.txt >> "$LOG_FILE"
```
2. Check last line of `/tmp/codex-verdict.txt` for verdict:
   - `VERDICT: APPROVED` → Resolution.
   - `VERDICT: REVISE` → Claude decides what's worth acting on (Claude is final arbiter). Revise `SPEC_FILE`. Then append Claude's response to log:
```bash
echo "### Claude's response" >> "$LOG_FILE"
echo "<what changed, what was rejected, why>" >> "$LOG_FILE"
```
   Increment round.
3. If round > `MAX_ROUNDS` → Resolution (deadlock).

### Resolution
- **APPROVED:** Output this summary and give a 3-bullet summary of what the two acts improved:
```
Title:     <feature title>
Slug:      <idea-slug>
Mode:      Branch | Worktree | Main
Spec file: docs/<idea-slug>-DESIGN.md
Log file:  docs/<idea-slug>-DESIGN-REVIEW-LOG.md
Rounds:    N
```
  Then propose a git commit — list the files to be staged and ask for confirmation:
  - `docs/<idea-slug>-DESIGN.md`
  - `docs/<idea-slug>-DESIGN-REVIEW-LOG.md`
  - `docs/<idea-slug>-SESSION.md` (if it exists)
  - `docs/<idea-slug>-DIALOG.md` (if it exists)

  On user approval, commit with message `docs: finalize <idea-slug> spec (brainstorming + Codex review)`. Do NOT push.

  Then recommend a next step instead of asking a generic "ready to move on?" — assess whether the finished `docs/<idea-slug>-DESIGN.md` describes one cohesive unit of work or would benefit from being broken into independently shippable slices first:
  - **Recommend `/sdd:plan`** (the common case) when the spec describes a single vertical slice — even a multi-step feature — that one TDD plan can carry end-to-end and ship as one PR.
  - **Recommend `/sdd:prd`** instead when the spec itself describes 2+ independently shippable, user-visible behaviors — distinct user journeys, phases the spec already calls out separately, or subsystems that don't share a single code path. `/sdd:prd` breaks it into vertical-slice issues, each of which then gets its own `/sdd:plan` pass.

  State the recommendation as a default with a one-line reason, and let the user pick the other path if they disagree (per the Language section above, deliver this message in Romanian):

  > *"<brief reason, e.g. 'This spec describes a single flow — one implementation plan can cover it end-to-end.'> I recommend `/sdd:plan` as the next step. Do you want to continue with that, or would you rather go through `/sdd:prd` first to break it into separate issues?"*

  Do NOT invoke either skill automatically — wait for the user's choice. Append the recommendation and the user's choice to `docs/<idea-slug>-DIALOG.md`.
- **MAX_ROUNDS deadlock:** List each unresolved point + Claude's counter-position. Hand to user to break the tie. Append each unresolved point and the user's tie-breaking decision to `docs/<idea-slug>-DIALOG.md`. After the user resolves, propose the same commit as above.

---

## Hard Rules
- Act 1 always precedes Act 2 — no DESIGN.md until brainstorming has actually resolved with the user.
- Pass spec content **inline** every round — do NOT use `-s read-only` or `-c sandbox_mode="read-only"` (bwrap blocks filesystem reads, Codex will fail silently and hallucinate).
- Loop ALWAYS terminates at `MAX_ROUNDS`.
- Claude is final arbiter on every REVISE — don't cave to everything, don't ignore it.
- Do NOT write code during either act.
- Do NOT invoke `writing-plans` automatically — that's the user's decision after sign-off.
