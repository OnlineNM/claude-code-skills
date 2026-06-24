---
name: lint
description: Validates a SKILL.md file against the standard portable skill format and returns a structured PASS/WARN/FAIL report with actionable recommendations. Use when the user wants to "lint this skill", "validate this SKILL.md", "check if this skill meets the format", "is this skill ready to install?", "check skill quality", "does this skill pass the standard?", or after /skill-check:convert to verify the output before installation. Also useful as an initial check before /skill-check:detect-claude to get a full quality overview.
---

# lint — SKILL.md Format Validator

Your job is to analyze a SKILL.md file and produce a structured lint report. Do not rewrite or fix anything — only analyze and report. Be specific: when flagging an issue, quote the relevant snippet. Be actionable: every recommendation must tell the user exactly what to change.

## Reading the input

The user provides the SKILL.md in one of two ways:

- **File path**: read the file using the Read tool.
- **Inline content**: use the content as-is.

If the input is ambiguous or missing, ask: "Please paste the SKILL.md content or provide a file path."

---

## Validation rules

Work through each check in order and collect findings before writing the report.

### Check 1 — `name` field

The following are **FAIL-level** issues:
- Field is absent or empty
- Value contains uppercase letters
- Value contains spaces or underscores (only lowercase letters, digits, and hyphens are allowed)
- Value is over 64 characters

If the name is present and valid, mark as **OK**.

### Check 2 — `description` field

Absence or empty value is a **FAIL-level** issue.

If present, assess quality:

- **OK** — the description reads as a routing signal: it specifies *when* to activate the skill. Signs: uses "Use when...", "Activate when...", "Trigger when...", or describes concrete user scenarios and phrases ("use when the user wants to...", "activate on requests like 'review this PR'").

- **WARN** — the description describes what the skill does but not when to use it. Example: "Summarizes meeting notes into action items." This is still usable but not optimized for routing.

- **WARN** — the description is marketing copy: contains adjectives like "powerful", "comprehensive", "intelligent", "robust", "advanced", "best", or frames the description around benefits rather than activation conditions.

### Check 3 — Other frontmatter fields

List any fields beyond `name` and `description`. Comment briefly:
- Is the field recognized as a standard SKILL.md field?
- Does it look unnecessary or potentially confusing?
- If there are no extra fields, say so.

### Check 4 — Overview section

Look for a heading that introduces the skill's purpose. Recognize these heading variants: "Overview", "Summary", "About", "What this does", "Background", or the skill name itself as an H1.

An opening paragraph without a heading also counts as an implicit overview.

- **Present**: any of the above found
- **Missing**: no introductory content before the first subsection (WARN — not FAIL)

### Check 5 — When to use / When NOT to use

Look for sections that define activation conditions and exclusions. Headings may vary: "When to use", "Use cases", "Use when", "Triggers", "Activation", "When NOT to use", "Don't use when", "Exclusions", "Limitations".

- "When to use" equivalent absent → **WARN**
- "When NOT to use" equivalent absent → **WARN** (lighter — omitting it is acceptable but not recommended)

### Check 6 — Instructions section

Look for a section with step-by-step agent instructions. Headings may vary: "Instructions", "Steps", "How to", "Workflow", "Process", "Usage".

Absence is a **FAIL-level** issue.

If present, rate quality:
- **Good**: numbered or clearly bulleted steps in execution order, concrete actions, no vague language ("just do your best", "handle as appropriate", "proceed accordingly")
- **Medium**: steps are present but some are vague, not ordered, or the sequence is implied rather than explicit
- **Poor**: only a single sentence, or "see above", or language equivalent to "do your best" — technically present but not useful

Poor quality → **WARN**.

### Check 7 — Output format section

Look for a section describing expected output structure. Headings may vary: "Output format", "Output", "Response format", "Expected output", "Result".

An output format implied by a template or example inside the instructions also counts.

- **Present**: found
- **Missing**: not found → **WARN** (not FAIL — some skills have implicit output)

### Check 8 — Runtime / Tooling issues

Scan the entire body for content that creates unmarked hard dependencies on specific runtimes:

- Paths like `~/.claude/`, `.claude/skills/`, `.claude/settings.json` in the main workflow body
- CLI commands `claude -p`, `claude run`, `claude chat` as mandatory steps
- Phrases "in Claude Code", "in Cowork" in instructions (not in Notes)
- `CLAUDE_*` environment variables in the main body

**If these appear inside a Notes/Tooling section** (or equivalent, clearly marked as environment-specific): rate as **OK** — they are properly isolated. Still list them for transparency.

**If these appear in the main workflow body** (Overview, Instructions, or Output format) without any Notes caveat: rate as **WARN**.

Do not flag generic shell commands (git, npm, python, curl, etc.) or AI model references ("tell Claude to...", "the model will...").

---

## Status determination

After completing all checks, determine the overall status:

### FAIL
At least one of the following is true:
- `name` is missing, empty, contains uppercase/spaces/underscores, or exceeds 64 characters
- `description` is missing or empty
- No instructions section (or equivalent) found in the body

### WARN
No FAIL conditions, but at least one of the following is true:
- `description` is a weak routing signal or marketing copy
- "When to use" section is absent
- "When NOT to use" section is absent
- Instructions quality is medium or poor
- Output format section is absent
- Runtime-specific content in main workflow body (not in Notes)
- Extra frontmatter fields that look unnecessary

### PASS
No FAIL or WARN conditions found. The skill meets all required criteria.

---

## Output format

Produce the report in exactly this structure:

---

### Frontmatter Summary

**name:** OK | ISSUE — `<value or "missing">` — `<details if not OK>`

**description:** OK | WARN | FAIL — `<details about quality or what is missing>`

**other fields:**
- `<field>`: `<comment>`
- *(none beyond name and description)*

---

### Body Structure

**overview:** present | missing

**when-to-use:** present | missing

**when-not-to-use:** present | missing

**instructions:** present | missing — quality: good | medium | poor | n/a

**output-format:** present | missing

---

### Runtime / Tooling Issues

- `<snippet>` — location: `<section>` — `<OK: in Notes | WARN: in main body>`
- *(none found)*

---

### Lint Result

**status:** PASS | WARN | FAIL

**recommendations:**
- [3–7 concrete, actionable bullets. Each must name specifically what to change and ideally how. Even on a PASS, include 1–2 optional polish suggestions.]

---

## Rules

- Do NOT rewrite the skill. Only analyze and report.
- Be specific: when flagging an issue, quote the relevant snippet.
- Be actionable: "Rename `name` to `my-skill` (lowercase kebab-case)" is good. "Fix the name" is not.
- On a clean PASS, still provide 1–2 optional polish recommendations (e.g., adding a "When NOT to use" section, improving routing language).
- If the file has no YAML frontmatter at all, report FAIL immediately and note that the file may be a declaudeify output intended to be passed to /skill-check:convert first.
