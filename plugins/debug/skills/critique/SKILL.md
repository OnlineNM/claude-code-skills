---
name: critique
description: >
  Runs an adversarial review of a completed task that produced a single output file.
  Use this immediately after finishing a task — generating a README, writing a config,
  producing a spec, drafting a script — when you want a skeptical second pass before
  shipping. Codex acts as a hostile reviewer looking for spec mismatches, wrong
  assumptions, and gaps, not a friendly summarizer. Trigger on: "adversarial review",
  "have codex review this", "what did we miss", "second opinion", "codex check this".
  If the task produced a single file and the user wants critical validation, always
  offer or invoke this skill proactively.
---

# Adversarial Review

Sends the original task requirement and a single output file to Codex CLI for adversarial review. Codex is instructed to be skeptical — its job is to find what breaks, not to be agreeable.

## Scope

This skill applies only to tasks whose outcome is **a single file** (README, config, script, spec, schema, etc.). For multi-file changes use a different review approach.

## Steps

### 1. Extract context from conversation

From the current conversation, identify:
- **Original requirement** — the user's initial request or spec that drove the task
- **Output file path** — the absolute path of the file produced

If the conversation contains multiple candidate requirements or files, pick the most recent and most specific ones.

### 2. Confirm with the user before sending

Present what you've extracted:

> I'll send the following to Codex for adversarial review:
> - **Requirement:** `<one-line summary of the requirement>`
> - **File:** `<absolute path>`
>
> Confirm, or let me know what to adjust.

Wait for confirmation. Do not proceed without it.

### 3. Spawn Codex review via `codex:codex-rescue` subagent

Spawn an Agent with `subagent_type: codex:codex-rescue` and pass this as the task prompt (fill in the bracketed parts):

```
You are an adversarial reviewer for a completed task. Be skeptical and specific — your job is to find what breaks, what's missing, and what doesn't match the spec. Do not be agreeable. Do not summarize what's correct.

## Original requirement

[paste the full original requirement here]

## File to review

@[absolute path to the output file]

## Review instructions

- Check every claim or design decision in the file against the requirement. Flag anything wrong, missing, or ambiguous.
- Surface unstated assumptions that could mislead an implementer.
- Identify anything that would need to change before this is production-ready.
- Be concrete: quote the specific line or section when raising an issue.
- Only report problems and gaps — do not list things that are correct.
- End with a verdict: PASS (minor issues only), NEEDS WORK (significant gaps), or REJECT (fundamental mismatches with the requirement).
```

This is a read-only review — do not pass `--write` and do not ask Codex to modify files.

### 4. Structure and present findings

Once Codex responds, present the findings in this format:

**Verdict:** `PASS / NEEDS WORK / REJECT`

**Issues found:**
- List each issue Codex raised, grouped by severity if multiple exist
- Quote the relevant section of the file for each issue
- Add a one-line note on the impact if it's not self-evident

**Summary:** One or two sentences on the overall quality relative to the requirement.

If Codex found nothing to raise (rare), say so explicitly and note the verdict.
