# SDD Context Hygiene Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task. Each task must follow superpowers:test-driven-development.

**Goal:** Apply the 6 confirmed findings from `docs/sdd-context-hygiene-NOTES.md` / `docs/sdd-context-hygiene-SPEC.md` to `plan`, `implement`, `verify`, `revise`, and `finalize` SKILL.md files of the `spec-driven-development` plugin (source at `plugins/spec-driven-development/skills/<name>/SKILL.md`), closing 6 real defects observed in transcript review.

**Architecture:** Text-only documentation edits, no code. Each task edits one or two SKILL.md files at a named heading, guided by `skill-creator`'s general skill-authoring conventions (see Global Constraints). Verification is grep-based text-presence/absence plus manual coherence re-read — no automated test suite exists for these skills.

**Tech Stack:** Markdown SKILL.md files, git, grep, skill-creator.

## Global Constraints

- Scope: ONLY these 5 files may be touched: `plugins/spec-driven-development/skills/finalize/SKILL.md`, `plugins/spec-driven-development/skills/implement/SKILL.md`, `plugins/spec-driven-development/skills/plan/SKILL.md`, `plugins/spec-driven-development/skills/verify/SKILL.md`, `plugins/spec-driven-development/skills/revise/SKILL.md` (revise needs no edit — see Task 7). No `superpowers:*` skill files. No code files.
- No edits outside the 6 named sections in any file — no incidental reflow, reformatting, or whitespace changes elsewhere.
- **skill-creator usage (required by spec, resolved here from reading `skill-creator`'s actual SKILL.md so the implementer doesn't have to guess):** skill-creator has no separate formal "edit an existing installed skill" checklist for a Claude Code / git-tracked-repo context — its only "updating an existing skill" note (preserve name/directory, copy to a writable location if the installed path is read-only) lives under its Claude.ai- and Cowork-specific sections and does not apply here, because these SKILL.md files are ordinary writable files in this git working tree, not an installed read-only skill package. The applicable, real checklist to follow for every edit in this plan is skill-creator's general **Skill Writing Guide**: keep YAML frontmatter (`name`, `description`) untouched and valid, keep each SKILL.md under ~500 lines (all 5 files are far under this already), write instructions in imperative form matching the surrounding style, uphold the **Principle of Lack of Surprise** (edits must not change what the skill claims to do beyond what the spec authorizes), and prefer explaining the *why* over bare MUSTs where the existing file already does so. Apply this checklist mentally before and after every Edit call in this plan; it does not require running skill-creator's eval/test-case machinery (that machinery is for creating/scoring new skills from scratch or optimizing trigger descriptions — not applicable to 6 targeted text fixes).
- If any of the 5 files no longer matches the structure this plan assumes (a heading/step already renumbered, removed, or reworded since this plan was written), STOP and report the discrepancy — do not guess a placement. (Structure was confirmed current as of writing this plan by reading all 5 files in full.)
- Out of scope (do not touch): Finding 0 (already resolved, no action), any code changes, any `superpowers:*` skill changes, automated tests (none exist for these skills), the `Hard Rules` line in `verify/SKILL.md` referencing `/codex:review` vs `/codex:adversarial-review` (Finding 5 only changes Step 3's body, not this unrelated Hard Rules bullet).

---

### Task 1: Finding 1 — add `## Before Starting` to `finalize/SKILL.md`

**Files:**
- Modify: `plugins/spec-driven-development/skills/finalize/SKILL.md`

**Interfaces:** None (standalone doc section insert).

- [ ] **Step 1: Verify the section is currently absent (test-before-fix)**

```bash
grep -n "## Before Starting" plugins/spec-driven-development/skills/finalize/SKILL.md
```

Expected: no output (section does not exist yet). If it already exists, STOP and report the discrepancy per Global Constraints.

- [ ] **Step 2: Insert the new section**

In `plugins/spec-driven-development/skills/finalize/SKILL.md`, the file currently reads (lines 14-20):

```markdown
## Language

Conduct all dialogue with the user — questions, status updates, presented options — exclusively in Romanian, regardless of the language used elsewhere in the session.

All deliverables this skill produces or drives (commit messages, merge/PR content) must always be written in English, independent of the Romanian dialogue above.

## Output and Context Rules
```

Using the `Edit` tool, replace that exact block with:

```markdown
## Language

Conduct all dialogue with the user — questions, status updates, presented options — exclusively in Romanian, regardless of the language used elsewhere in the session.

All deliverables this skill produces or drives (commit messages, merge/PR content) must always be written in English, independent of the Romanian dialogue above.

## Before Starting

Tell the user: *"Please run `/clear` first to start with a clean context, then re-invoke this skill."* If the user has already cleared, proceed. If this skill was invoked directly by `sdd:verify` Step 7 (same-session handoff after a PASS verdict), skip this prompt and proceed directly — the handoff is intentional and doesn't need a fresh context.

## Output and Context Rules
```

- [ ] **Step 3: Verify the section is now present (test-after-fix)**

```bash
grep -n "## Before Starting" plugins/spec-driven-development/skills/finalize/SKILL.md
grep -n "sdd:verify\` Step 7" plugins/spec-driven-development/skills/finalize/SKILL.md
```

Expected: both greps return one matching line each.

- [ ] **Step 4: Re-read the edited region end-to-end**

Read `plugins/spec-driven-development/skills/finalize/SKILL.md` lines 1-35 and confirm: heading hierarchy is intact (`##` level, consistent with siblings), no duplicated "Before Starting" section, no leftover artifact from the edit, the section reads coherently between `## Language` and `## Output and Context Rules`.

- [ ] **Step 5: Commit**

```bash
git add plugins/spec-driven-development/skills/finalize/SKILL.md
git commit -m "docs(sdd): add Before Starting section to finalize skill (Finding 1)"
```

---

### Task 2: Finding 2 — path-passing instead of content-pasting in `implement/SKILL.md`

**Files:**
- Modify: `plugins/spec-driven-development/skills/implement/SKILL.md`

**Interfaces:**
- Produces: the template placeholder token is renamed from `<PLAN_CONTENT>` to `<PLAN_PATH>` across both Step 2 and Step 4 dispatch templates — Task 4 (Finding 4) edits the same two templates and must use the post-Task-2 file state (i.e. apply Task 2 before Task 4 if working sequentially — this plan already orders them that way).

- [ ] **Step 1: Verify current placeholder occurrences (test-before-fix)**

```bash
grep -n "PLAN_CONTENT" plugins/spec-driven-development/skills/implement/SKILL.md
```

Expected: 4 matches — two `<PLAN_CONTENT>` inside the two `<plan>...</plan>` blocks (Step 2 and Step 4 templates), and two "Replace `<PLAN_CONTENT>` with..." instruction lines.

- [ ] **Step 2: Fix the Step 2 dispatch template**

The file currently reads (the Step 2 template block plus its instruction line):

```markdown
```
You are implementing a TDD plan. Read this plan carefully and execute it step by step.

<plan>
<PLAN_CONTENT>
</plan>

Instructions:
- Use the `superpowers:subagent-driven-development` skill to implement this plan task-by-task.
- Each task must follow `superpowers:test-driven-development`.
- Do NOT skip any step.
- Do NOT modify tests to make them pass — fix the implementation instead.
- For framework-specific patterns (React hooks, routing, auth, database ORM, etc.), verify against official documentation before implementing.
- After all tasks are complete, run the full test suite and confirm all tests pass.
- Report back concisely: task count completed/total, overall test pass/fail counts, and any issues encountered in 1-2 lines each. Do not paste full test output or file contents in your report.
```

Replace `<PLAN_CONTENT>` with the full content of the plan file read in Step 1.
```

Using the `Edit` tool, replace the `<plan>...</plan>` block and the instruction line below the template with:

```markdown
```
You are implementing a TDD plan. Read this plan carefully and execute it step by step.

<plan_path>
<PLAN_PATH>
</plan_path>

Instructions:
- Use the `superpowers:subagent-driven-development` skill to implement this plan task-by-task.
- Each task must follow `superpowers:test-driven-development`.
- Do NOT skip any step.
- Do NOT modify tests to make them pass — fix the implementation instead.
- For framework-specific patterns (React hooks, routing, auth, database ORM, etc.), verify against official documentation before implementing.
- After all tasks are complete, run the full test suite and confirm all tests pass.
- Report back concisely: task count completed/total, overall test pass/fail counts, and any issues encountered in 1-2 lines each. Do not paste full test output or file contents in your report.
```

Replace `<PLAN_PATH>` with the absolute path of the plan file read in Step 1. Read that file yourself, in your own context, before starting work — do not rely on any plan content being pasted into this prompt.
```

(Leave the `Instructions:` bullet list untouched here — Task 4 will insert one more bullet into it.)

- [ ] **Step 3: Fix the Step 4 dispatch template**

The file currently reads (the Step 4 template block plus its instruction line):

```markdown
```
You are verifying an implementation against a TDD plan. Do NOT modify any code.

<plan>
<PLAN_CONTENT>
</plan>

Instructions:
- Read the test commands and verification steps defined in the plan above.
- Run every test and verification command.
- Report concisely: pass/fail counts, an overall PASS / FAIL verdict, and for each failing test only its name plus a 1-3 line error excerpt (not the full stack trace or raw command output).
- Do NOT fix anything — only report what you find.
```

Replace `<PLAN_CONTENT>` with the full content of the plan file.
```

Using the `Edit` tool, replace the `<plan>...</plan>` block and the instruction line below the template with:

```markdown
```
You are verifying an implementation against a TDD plan. Do NOT modify any code.

<plan_path>
<PLAN_PATH>
</plan_path>

Instructions:
- Read the test commands and verification steps defined in the plan above.
- Run every test and verification command.
- Report concisely: pass/fail counts, an overall PASS / FAIL verdict, and for each failing test only its name plus a 1-3 line error excerpt (not the full stack trace or raw command output).
- Do NOT fix anything — only report what you find.
```

Replace `<PLAN_PATH>` with the absolute path of the plan file read in Step 1. Read that file yourself, in your own context, before starting work — do not rely on any plan content being pasted into this prompt.
```

- [ ] **Step 4: Verify no `<PLAN_CONTENT>` or bare `<plan>` tag remains, and `<PLAN_PATH>` is present exactly twice (test-after-fix)**

```bash
grep -n "PLAN_CONTENT" plugins/spec-driven-development/skills/implement/SKILL.md
grep -n "<plan>" plugins/spec-driven-development/skills/implement/SKILL.md
grep -c "PLAN_PATH" plugins/spec-driven-development/skills/implement/SKILL.md
```

Expected: first two greps return no output; third returns `4` (two `<plan_path>`/`</plan_path>` wrapper occurrences per template × 2 templates, plus the two `<PLAN_PATH>` placeholder tokens themselves — confirm the actual count against what Step 2/3 above produced; the key pass criterion is zero `PLAN_CONTENT` matches and zero bare `<plan>` matches).

- [ ] **Step 5: Re-read both full dispatch templates end-to-end**

Read `plugins/spec-driven-development/skills/implement/SKILL.md` in full and confirm no remaining line embeds full plan content or instructs pasting it in (a plain instruction like "read the plan file" is fine and expected — only literal content embedding is the problem). Confirm both templates are internally consistent (same placeholder style, no leftover reference to the old pattern).

- [ ] **Step 6: Commit**

```bash
git add plugins/spec-driven-development/skills/implement/SKILL.md
git commit -m "docs(sdd): pass plan by path instead of pasted content in implement dispatch templates (Finding 2)"
```

---

### Task 3: Finding 3 — granularity checkpoint no longer fires on every `plan` run

**Files:**
- Modify: `plugins/spec-driven-development/skills/plan/SKILL.md`

**Interfaces:** None (standalone doc section rewrite).

- [ ] **Step 1: Verify current unconditional 3-option prompt (test-before-fix)**

```bash
grep -n "Present exactly these three options in chat and wait for the user's choice" plugins/spec-driven-development/skills/plan/SKILL.md
```

Expected: one match, inside `#### Granularity choice (before invoking writing-plans)`.

- [ ] **Step 2: Rewrite the granularity section**

The file currently reads (lines 90-99):

```markdown
#### Granularity choice (before invoking writing-plans)

Present exactly these three options in chat and wait for the user's choice:
- **1. Fewer, larger steps** — faster execution, less intermediate validation
- **2. Balanced** (default — recommend this unless the input suggests otherwise) — one step per logical unit of work
- **3. More, smaller steps** — maximum checkpoints, more context-switch overhead

Wording must differ by input type: when the input is `ISSUE-N.md` (already a single vertical slice from `prd`), the three options size **implementation tasks within that slice**, not features — replace "steps" wording with "implementation tasks" in the ISSUE-N.md case to avoid re-litigating PRD-level decomposition.

Hold the user's literal choice (e.g. `"Balanced — one step per logical unit of work"`) — it is interpolated into OVERRIDE 7 below when invoking `writing-plans`.
```

Using the `Edit` tool, replace that block with:

```markdown
#### Granularity choice (before invoking writing-plans)

Default to **"Balanced — one step per logical unit of work"** and proceed silently — do not ask the user, since Balanced is already the documented default and re-asking on every run adds friction without adding signal in the common case.

Only surface the three-option question when the input content clearly signals, in qualitative terms (no numeric thresholds), unusually large/complex or unusually trivial scope. Example signals:
- The scope spans multiple independent subsystems or user-facing flows.
- The description itself calls out unusual risk, migration, or rollback complexity.
- The change is a single-line/trivial fix with no meaningful design decisions.

These examples guide judgment — they don't replace it with a threshold. When one of these (or a comparable) signal is present, present exactly these three options in chat and wait for the user's choice:
- **1. Fewer, larger steps** — faster execution, less intermediate validation
- **2. Balanced** (default — recommend this unless the input suggests otherwise) — one step per logical unit of work
- **3. More, smaller steps** — maximum checkpoints, more context-switch overhead

Wording must differ by input type: when the input is `ISSUE-N.md` (already a single vertical slice from `prd`), the three options size **implementation tasks within that slice**, not features — replace "steps" wording with "implementation tasks" in the ISSUE-N.md case to avoid re-litigating PRD-level decomposition.

Hold the resulting choice — whether auto-selected Balanced or the user's literal answer to the three-option question (e.g. `"Balanced — one step per logical unit of work"`) — it is interpolated into OVERRIDE 7 below when invoking `writing-plans`.
```

- [ ] **Step 3: Verify the auto-select default and conditional trigger are present (test-after-fix)**

```bash
grep -n "Default to \*\*\"Balanced" plugins/spec-driven-development/skills/plan/SKILL.md
grep -n "Only surface the three-option question" plugins/spec-driven-development/skills/plan/SKILL.md
grep -c "Fewer, larger steps" plugins/spec-driven-development/skills/plan/SKILL.md
```

Expected: first two greps return one match each; third returns `1` (the three-option list still exists exactly once, now gated).

- [ ] **Step 4: Re-read the edited region end-to-end**

Read `plugins/spec-driven-development/skills/plan/SKILL.md` around `### Step 4` (roughly lines 84-125) and confirm: the OVERRIDE 7 text below (referencing the "user already chose a granularity above this invocation") still reads coherently with an auto-selected choice (not just a user-typed one) — no contradiction between "the user already chose" phrasing and the new auto-select path. If it reads awkwardly, adjust OVERRIDE 7's lead-in wording minimally (e.g. "a granularity was determined above this invocation") without changing its substantive instruction to interpolate the choice verbatim.

- [ ] **Step 5: Commit**

```bash
git add plugins/spec-driven-development/skills/plan/SKILL.md
git commit -m "docs(sdd): auto-select Balanced granularity by default, ask only on unusual scope (Finding 3)"
```

---

### Task 4: Finding 4 — read-before-write rule in `implement/SKILL.md` dispatch templates

**Files:**
- Modify: `plugins/spec-driven-development/skills/implement/SKILL.md`

**Interfaces:**
- Consumes: the `<plan_path>`-based templates produced by Task 2 — this task edits the same two template blocks and must run after Task 2.

- [ ] **Step 1: Verify the rule is currently absent (test-before-fix)**

```bash
grep -n "read-before-write\|Before every use of the \`Edit\` tool" plugins/spec-driven-development/skills/implement/SKILL.md
```

Expected: no output.

- [ ] **Step 2: Insert the bullet into the Step 2 template**

After Task 2, the Step 2 template's instruction list reads:

```markdown
Instructions:
- Use the `superpowers:subagent-driven-development` skill to implement this plan task-by-task.
- Each task must follow `superpowers:test-driven-development`.
- Do NOT skip any step.
- Do NOT modify tests to make them pass — fix the implementation instead.
```

Using the `Edit` tool, insert the new bullet between "Do NOT skip any step." and "Do NOT modify tests...":

```markdown
Instructions:
- Use the `superpowers:subagent-driven-development` skill to implement this plan task-by-task.
- Each task must follow `superpowers:test-driven-development`.
- Do NOT skip any step.
- Before every use of the `Edit` tool on an existing file — even one you believe a prior task already created — use the `Read` tool on it first, in this subagent's own context; using `Write` to create a genuinely new file needs no prior Read. If `Edit` or `Write` fails, `Read` the file (or confirm it doesn't exist) and retry the same tool — never fall back to a raw shell command (e.g. `sed`, `cat >`) to force the change through.
- Do NOT modify tests to make them pass — fix the implementation instead.
```

- [ ] **Step 3: Insert the bullet into the Step 4 template**

After Task 2, the Step 4 template's instruction list reads:

```markdown
Instructions:
- Read the test commands and verification steps defined in the plan above.
- Run every test and verification command.
- Report concisely: pass/fail counts, an overall PASS / FAIL verdict, and for each failing test only its name plus a 1-3 line error excerpt (not the full stack trace or raw command output).
- Do NOT fix anything — only report what you find.
```

Using the `Edit` tool, insert the new bullet (identical wording, verbatim per spec) between the "Report concisely..." bullet and "Do NOT fix anything...":

```markdown
Instructions:
- Read the test commands and verification steps defined in the plan above.
- Run every test and verification command.
- Report concisely: pass/fail counts, an overall PASS / FAIL verdict, and for each failing test only its name plus a 1-3 line error excerpt (not the full stack trace or raw command output).
- Before every use of the `Edit` tool on an existing file — even one you believe a prior task already created — use the `Read` tool on it first, in this subagent's own context; using `Write` to create a genuinely new file needs no prior Read. If `Edit` or `Write` fails, `Read` the file (or confirm it doesn't exist) and retry the same tool — never fall back to a raw shell command (e.g. `sed`, `cat >`) to force the change through.
- Do NOT fix anything — only report what you find.
```

- [ ] **Step 4: Verify the bullet appears exactly twice, once per template (test-after-fix)**

```bash
grep -c "never fall back to a raw shell command" plugins/spec-driven-development/skills/implement/SKILL.md
```

Expected: `2`.

- [ ] **Step 5: Re-read both templates end-to-end**

Read `plugins/spec-driven-development/skills/implement/SKILL.md` in full and confirm: the new bullet reads coherently in both positions (grammatically fits the surrounding bullet list), no duplicate insertion within a single template, bullet ordering elsewhere in each template is otherwise unchanged.

- [ ] **Step 6: Commit**

```bash
git add plugins/spec-driven-development/skills/implement/SKILL.md
git commit -m "docs(sdd): add read-before-write rule to implement dispatch templates (Finding 4)"
```

---

### Task 5: Finding 5 — fix broken Codex invocation in `verify/SKILL.md` Step 3

**Files:**
- Modify: `plugins/spec-driven-development/skills/verify/SKILL.md`

**Interfaces:** None (standalone doc section rewrite). Does not touch the unrelated `Hard Rules` bullet mentioning `/codex:review` vs `/codex:adversarial-review` — out of scope per Global Constraints.

- [ ] **Step 1: Verify the current broken instruction (test-before-fix)**

```bash
grep -n "Run \`/codex:review --wait\`" plugins/spec-driven-development/skills/verify/SKILL.md
```

Expected: one match, inside `### Step 3 — Technical review (Codex)`.

- [ ] **Step 2: Rewrite Step 3**

The file currently reads (lines 65-69):

```markdown
### Step 3 — Technical review (Codex)

Run `/codex:review --wait` to get an independent technical check from Codex on the same working tree.

This pass catches defects that Claude may have missed — it has no plan context and reviews purely for technical correctness. When relaying its findings in Step 5, summarize each as a 1-2 line issue statement — do not paste Codex's raw output or full diff commentary into the chat.
```

Using the `Edit` tool, replace that block with:

```markdown
### Step 3 — Technical review (Codex)

`codex:review` is a slash command with `disable-model-invocation: true` and cannot be invoked via the `Skill` tool — instead, run the `codex` binary directly through the Bash tool, non-interactively, with a bounded timeout:

```bash
codex review --uncommitted "Review the uncommitted changes in this working tree for correctness, adherence to the plan, and code quality. Report concrete issues found."
```

Use the Bash tool's `timeout` parameter set to 300000 (300 seconds / 5 minutes).

If the `codex` binary is unavailable, the command exits non-zero (auth failure, etc.), or it hits the timeout, report that the Codex review could not run and let the user decide whether to proceed to Step 4 without it or stop and fix Codex access first — do not silently skip this step or block indefinitely.

This pass catches defects that Claude may have missed — it has no plan context and reviews purely for technical correctness. Any findings Codex does return are advisory input into Step 5's overall PASS/FAIL determination alongside `verify`'s other checks — they don't auto-fail the run on their own, but weigh them the same way findings from `verify`'s other steps are weighed when producing the final verdict. When relaying its findings in Step 5, summarize each as a 1-2 line issue statement — do not paste Codex's raw output or full diff commentary into the chat.
```

- [ ] **Step 3: Verify the fix is present (test-after-fix)**

```bash
grep -n "codex review --uncommitted" plugins/spec-driven-development/skills/verify/SKILL.md
grep -n "Run \`/codex:review --wait\`" plugins/spec-driven-development/skills/verify/SKILL.md
```

Expected: first grep returns one match; second grep returns no output (old broken instruction is gone).

- [ ] **Step 4: Re-read the edited region end-to-end**

Read `plugins/spec-driven-development/skills/verify/SKILL.md` around `### Step 3` and confirm it reads coherently with `### Step 2` above and `### Step 4` below, and does not contradict the unrelated `Hard Rules` bullet about `/codex:review` vs `/codex:adversarial-review` (that bullet still refers to Codex review generically as "standard review" — confirm this still makes sense given Step 3 no longer uses the slash-command form; if genuinely contradictory, note it for the user rather than editing Hard Rules, since Hard Rules edits are out of scope for this plan).

- [ ] **Step 5: Commit**

```bash
git add plugins/spec-driven-development/skills/verify/SKILL.md
git commit -m "docs(sdd): fix verify Step 3 to invoke codex via Bash instead of an unusable slash command (Finding 5)"
```

---

### Task 6: Finding 6 — reword `verify/SKILL.md` Step 7 question

**Files:**
- Modify: `plugins/spec-driven-development/skills/verify/SKILL.md`

**Interfaces:** None (cosmetic wording-only change; Yes/No branch behavior unchanged).

- [ ] **Step 1: Verify current wording (test-before-fix)**

```bash
grep -n "Would you like to merge and clean up?" plugins/spec-driven-development/skills/verify/SKILL.md
```

Expected: one match, inside `### Step 7 — Offer merge and cleanup (PASS only)`.

- [ ] **Step 2: Reword the question line only**

The file currently reads (lines 130-138, after Task 5's edit this section is unchanged since Task 5 only touched Step 3):

```markdown
### Step 7 — Offer merge and cleanup (PASS only)

Only when the verdict is PASS, ask the user:

> *"The implementation is validated. Would you like to merge and clean up?"*
> - **Yes** — invoke `sdd:finalize` to commit any pending changes and handle merge into main and branch/worktree cleanup.
> - **No** — stop here. Leave the branch/worktree as-is.

Do NOT proceed with merge or cleanup without explicit user confirmation.
```

Using the `Edit` tool, replace only the quoted question line:

```markdown
### Step 7 — Offer merge and cleanup (PASS only)

Only when the verdict is PASS, ask the user:

> *"The implementation is validated. Would you like `sdd:finalize` to merge and clean up?"*
> - **Yes** — invoke `sdd:finalize` to commit any pending changes and handle merge into main and branch/worktree cleanup.
> - **No** — stop here. Leave the branch/worktree as-is.

Do NOT proceed with merge or cleanup without explicit user confirmation.
```

- [ ] **Step 3: Verify the new wording is present and the old wording is gone (test-after-fix)**

```bash
grep -n "Would you like \`sdd:finalize\` to merge and clean up?" plugins/spec-driven-development/skills/verify/SKILL.md
grep -n "Would you like to merge and clean up?" plugins/spec-driven-development/skills/verify/SKILL.md
```

Expected: first grep returns one match; second grep returns no output.

- [ ] **Step 4: Re-read the edited region end-to-end**

Read `plugins/spec-driven-development/skills/verify/SKILL.md` around `### Step 7` and confirm the Yes/No sub-options and control flow beneath are byte-identical to before — only the quoted question text changed.

- [ ] **Step 5: Commit**

```bash
git add plugins/spec-driven-development/skills/verify/SKILL.md
git commit -m "docs(sdd): name sdd:finalize explicitly in verify Step 7 question wording (Finding 6)"
```

---

### Task 7: Final cross-file verification (spec's Verification section, checks 3-4) and `revise/SKILL.md` no-op confirmation

**Files:**
- Read only: all 5 files under `plugins/spec-driven-development/skills/{finalize,implement,plan,verify,revise}/SKILL.md`

**Interfaces:** None (verification-only task, no file modifications expected).

- [ ] **Step 1: Confirm no edits leaked outside the 6 named sections**

```bash
git diff --stat plugins/spec-driven-development/skills/finalize/SKILL.md plugins/spec-driven-development/skills/implement/SKILL.md plugins/spec-driven-development/skills/plan/SKILL.md plugins/spec-driven-development/skills/verify/SKILL.md
```

(Run against the commit before Task 1 if diffing across all commits, e.g. `git diff --stat <pre-task-1-sha>..HEAD -- plugins/spec-driven-development/skills/`.) Expected: only the 4 files above show changes (not `revise/SKILL.md`), and each diff's line-change count is consistent with a small, localized edit (roughly single-digit-to-low-double-digit line deltas per file) — a large/unexpected line count signals unintended reflow and should be investigated before proceeding.

- [ ] **Step 2: Confirm `revise/SKILL.md` Step 2c still only references `implement`'s pattern by name**

```bash
grep -n "same pattern as \`sdd:implement\`'s Steps 2/4" plugins/spec-driven-development/skills/revise/SKILL.md
grep -n "PLAN_CONTENT\|PLAN_PATH" plugins/spec-driven-development/skills/revise/SKILL.md
```

Expected: first grep returns one match (Step 2c's existing by-reference line, unchanged); second grep returns no output — `revise/SKILL.md` has no literal plan-content placeholder of its own, confirming it inherits Task 2's and Task 4's fixes automatically without a direct edit, per the spec's stated rationale.

- [ ] **Step 3: Confirm no `<PLAN_CONTENT>` or bare `<plan>` tag remains anywhere in the plugin**

```bash
grep -rn "PLAN_CONTENT" plugins/spec-driven-development/skills/
grep -rn "^<plan>$" plugins/spec-driven-development/skills/
```

Expected: both return no output.

- [ ] **Step 4: Final full re-read of all 4 modified files**

Read each of `plugins/spec-driven-development/skills/finalize/SKILL.md`, `plugins/spec-driven-development/skills/implement/SKILL.md`, `plugins/spec-driven-development/skills/plan/SKILL.md`, and `plugins/spec-driven-development/skills/verify/SKILL.md` in full, end-to-end, and confirm: each reads coherently with no duplicated instructions, no contradictions with adjacent steps, and every one of the 6 findings' fixes is present exactly where the spec describes it (by heading/section, matching the spec's own Verification section checks 1-2).

No commit needed for this task — it is read-only verification confirming Tasks 1-6 are complete and correct.
</content>
