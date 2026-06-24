---
name: convert
description: Converts any skill document — a raw prompt, SOP, instruction set, or existing SKILL.md — into a complete, portable SKILL.md file ready to install in Paperclip or other agent runtimes. Use when the user says "convert this to a SKILL.md", "package this as a skill", "make this a portable skill", "create a SKILL.md from this prompt", "I want to share this skill", "wrap this in SKILL.md format", or after /skill-check:declaudeify produces cleaned body content that needs frontmatter and final structure. Always produces a complete file (frontmatter + body) — unlike /skill-check:declaudeify which produces body only.
---

# convert — Portable SKILL.md Generator

Your job is to produce a **complete, ready-to-save SKILL.md file** from any input skill document. The output must be fully self-contained: valid YAML frontmatter followed by a structured markdown body, with no runtime-specific dependencies unless absolutely essential for meaning.

## Reading the input

The user provides the source in one of these ways:

- **File path**: a path passed as the slash command argument — read the file using the Read tool.
- **Inline content**: skill text pasted directly into the message.
- **Optional name hint**: the user may pass a proposed skill name alongside the file (e.g. `path/to/file.md release-notes-writer`). If provided, use it as the `name` field.

If the input is ambiguous or missing, ask: "Please paste the skill content or provide a file path."

---

## Step 1 — Determine the skill name

Derive the `name` field using this priority order:

1. **User-provided name** (passed explicitly as an argument) — use it; silently fix if not kebab-case.
2. **Existing YAML frontmatter** `name:` field in the source — use it as-is.
3. **H1 heading** in the source — convert to lowercase kebab-case (replace spaces with `-`, strip special characters, trim to 64 chars).
4. **Infer from content** — derive a short, descriptive kebab-case name from the skill's topic and purpose.

If none of these produce a clear candidate, ask: "What name should this skill have? (e.g. `release-notes-writer`)"

---

## Step 2 — Craft the routing description

The `description` field is a **routing signal for the agent**, not marketing copy. An agent uses it to decide whether to activate this skill for a given user request. Getting this right is the most important part of the conversion.

### What makes a good routing description

A good routing description answers: *"In what situations should this skill be invoked?"*

It should:
- Use concrete trigger language: "Use when the user wants to...", "Activate when the user asks to...", "Trigger on phrases like..."
- Be specific enough to distinguish this skill from adjacent skills
- Be 1–3 sentences

**Contrast — bad vs. good:**

| Bad (marketing copy) | Good (routing description) |
|---|---|
| "A powerful tool for reviewing pull requests efficiently." | "Use when the user wants to review a PR, get code review feedback, or analyze a diff. Activate on 'review this PR', 'code review', 'check this diff'." |
| "Helps you write better release notes for your projects." | "Use when the user needs to write or draft release notes from a git log, changelog, or list of changes." |

### How to craft the description

1. If the source has a YAML `description:` that already reads as routing language (starts with "Use when...", "Activate when...", lists user phrases) → keep it.
2. If the source description reads as marketing copy → rewrite it as a routing description, drawing on the skill's Instructions and When to use sections.
3. If there is no description → derive one from the skill's purpose, who would invoke it, and what they would say.

---

## Step 3 — Structure the body

Produce the body in this section order. All sections are required unless marked optional. Do not invent content that was not in the source.

### `# Overview`
1–3 paragraphs describing what the skill does and why it exists. Write for an agent following instructions, not for a human end-user. No runtime-specific product names.

### `## When to use`
Bullet list of scenarios in which this skill should activate. These should be more specific than the routing description — concrete examples of requests or contexts.

### `## When NOT to use`
Bullet list of scenarios where this skill is NOT appropriate. Derive from:
- Explicit exclusions already stated in the source
- Natural domain boundaries (what adjacent skills would handle instead)
- Cases where the input is too incomplete for the skill to produce useful output

If the source does not specify exclusions, infer 2–3 reasonable ones based on the skill's scope.

### `## Instructions`
Step-by-step instructions the agent must follow to complete the task, in execution order. Preserve the source's original steps as faithfully as possible. Number the steps. Do not add steps that were not in the source.

### `## Output format`
How the agent should structure its response: sections, fields, lists, templates. If the source defines an output format or template, reproduce it exactly. If not, describe the format that naturally follows from the instructions.

### `## Examples` *(optional)*
Include 1–2 adapted examples if the source has good examples. Omit this section entirely if the source has no examples. Do not invent examples.

### `## Notes / Tooling`
All environment-specific content belongs here:
- CLI commands that are optional or runtime-specific
- API or SDK references
- File paths that are environment-specific (if the source came through `/skill-check:declaudeify`, its **Environment-Specific Notes** section maps directly here)
- Known limitations or compatibility notes

If nothing belongs here, write: "None — this skill has no external dependencies."

---

## Step 4 — Handle any remaining runtime-specific content

While structuring the body, if you encounter Claude Code–specific references that were not removed upstream (e.g. `~/.claude/skills`, `claude -p`, "Skills panel"):
- Move them to **Notes / Tooling**, labeled as environment-specific
- Replace with neutral wording in the body
- Do not return an error — handle silently

---

## Output format

Your response MUST be **only** the complete SKILL.md file — starting with `---` and ending after the last content line. No explanation, no commentary, no preamble, no transformation log.

Required output shape:

```
---
name: <skill-name>
description: <routing description, 1–3 sentences>
---

# Overview
<content>

## When to use
<content>

## When NOT to use
<content>

## Instructions
<content>

## Output format
<content>

## Examples
<content>   ← omit entire section if source has none

## Notes / Tooling
<content>
```

---

## Faithfulness rule

Do not invent new functionality, steps, output fields, or examples that were not present in the source. When in doubt, omit rather than invent. The source's intent and scope define the ceiling of what the output can contain.
