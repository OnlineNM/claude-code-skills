---
name: compare
description: Compares an original Claude Code–specific skill with its generic (declaudeified) counterpart and classifies the pair as EQUIVALENT or DIVERGENT. Use when the user has completed the declaudeify → convert workflow and wants to decide whether to keep both versions or consolidate to the generic. Invoke whenever the user asks "is the generic version good enough?", "can I drop the original?", "what did I lose in the conversion?", "compare these two skills", "should I keep both?", "is the declaudeified version equivalent?", or after /skill-check:lint passes on the converted skill. Always invoke after /skill-check:convert.
---

# compare — Semantic Equivalence Analyzer

Your job is to determine whether a generic (declaudeified) skill preserves the full semantic intent of its Claude Code–specific original, or whether meaningful capability was lost in the transformation. You do this through static analysis — reading both files and comparing their content — not by executing either skill.

The goal is a single, actionable verdict: **can the original be safely retired, or do both versions need to be maintained?**

## Reading the input

The user provides two files:

- **original** — the Claude Code–specific skill (before declaudeify)
- **generic** — the portable version (after declaudeify + convert)

These may be provided as:
- **File paths** passed as arguments: `/skill-check:compare path/to/original.md path/to/generic.md`
- **Inline content** pasted directly into the message

If either file is missing or ambiguous, ask: "Please provide paths to both the original and the generic SKILL.md, or paste their contents."

## Analysis process

Read both files in full. Then work through the differences section by section — frontmatter, overview, instructions, output format, and any appendix content. For each difference, classify it as **cosmetic** or **functional** using the criteria below.

### Cosmetic changes

These preserve the full semantic intent of the original instruction. The agent following the generic skill will do the same thing as the agent following the original.

| Pattern | Why cosmetic |
|---|---|
| `.claude/skills/` → `your skills directory` | Same instruction, neutral wording |
| `"in Claude Code"` → `"in your agent environment"` | Same meaning, different product name |
| `"Skills panel"` → `"skills list in your interface"` | Same UI concept, runtime-neutral description |
| `CLAUDE_SKILL_DIR` → `SKILLS_DIR` | Same variable purpose, renamed |
| Tool call moved to Notes AND main step still uses imperative language for the same activity (e.g. `"Use TodoWrite to track"` → `"Track each category"` + TodoWrite in Notes) | The activity is still required; the tool is preserved as a Claude Code implementation detail. A Claude Code agent reading the full skill sees both the main step AND the Notes, so it will use the tool. Do NOT flag this as functional just because the main step no longer names the tool. | 
| Section reformatted or reordered with identical content | Presentation change only |

### Functional changes

These alter what an agent following the skill will actually do. Any functional change, regardless of how small, is evidence for DIVERGENT.

| Pattern | Why functional |
|---|---|
| `"use TodoWrite to track progress"` → `"track progress using your task system, if available"` | Tool invocation made optional — the tracking may not happen |
| A tool call removed entirely without a conditional replacement | Capability lost |
| A CLI command removed from the main workflow with no equivalent step | Workflow step missing |
| An output format section simplified, fields removed, or structure changed | Different output produced |
| A mandatory step reworded to vague language: "handle as appropriate", "do your best", "proceed accordingly" | Instruction degraded — agent has less guidance |
| Tool call removed from main step AND replaced with weakened language: "if available", "mental checklist", "where possible", "if your runtime supports" | Step degraded — tool invocation is no longer required even in runtimes that support it |
| New "When NOT to use" conditions added that weren't in the original | Scope narrowed |

### What NOT to flag as a difference

These are expected outputs of the declaudeify process and should not be treated as changes at all:
- Addition of an "Environment-Specific Notes" section or equivalent
- Section titles reworded while content is preserved
- Whitespace, formatting, or markdown style differences
- A more neutral description in the frontmatter that preserves routing intent

## Classification

After collecting all differences:

**EQUIVALENT** — every difference found is cosmetic. The generic skill will produce equivalent behavior in any runtime, including Claude Code. The original can be safely retired.

**DIVERGENT** — at least one functional difference is found. The generic skill may behave differently than the original when run in Claude Code. Both versions serve a distinct purpose.

When uncertain whether a specific change is cosmetic or functional: lean toward classifying it as functional and flag it explicitly in the report. It is better to surface a borderline case than to miss a real capability loss.

## Output format

Produce the report in exactly this structure:

---

### Comparison Summary

**original:** `<filename or "inline content">`
**generic:** `<filename or "inline content">`
**sections compared:** `<list of sections analyzed>`

---

### Change Analysis

**cosmetic_changes:**
- `<snippet from generic>` ← was: `<snippet from original>` — `<why cosmetic>`
- *(none found)*

**functional_changes:**
- `<snippet from generic>` ← was: `<snippet from original>` — `<why functional>`
- *(none found)*

**borderline_cases:**
- `<snippet>` — `<why uncertain>` — classified as: `cosmetic` | `functional`
- *(none found)*

---

### Verdict

**classification:** `EQUIVALENT` | `DIVERGENT`

**rationale:**
- [2–4 bullets explaining the verdict. Reference specific findings from the Change Analysis above.]

**recommendation:**
- **If EQUIVALENT:** The generic version preserves full semantic intent. Retire the Claude Code–specific version and use the generic in all runtimes, including Claude Code.
- **If DIVERGENT:** The versions have meaningful differences. Keep both: use the original in Claude Code where the specific instructions matter, and the generic for other runtimes. Consider whether the functional changes can be addressed in a future declaudeify pass.

---
