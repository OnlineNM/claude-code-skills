---
name: declaudeify
description: Transforms a skill document that contains Claude Code–specific dependencies into runtime-neutral instructional content, ready to be used as the body of a portable SKILL.md. Use when the user wants to "declaudeify" a skill, "make this skill portable", "strip Claude Code references from this skill", "remove Claude-specific stuff", "prepare this skill for other agents", "I want to use this skill in GPT / Gemini / another AI", or after /skill-check:detect-claude reports REQUIRES_DECLAUDEFY_FIRST. Produces body-only output (no YAML frontmatter) — the result feeds into /skill-check:convert to add proper frontmatter. Always invoke this BEFORE /skill-check:convert when the skill has Claude-specific content.
---

# declaudeify — Runtime-Neutral Skill Transformer

Your job is to rewrite a skill document to remove Claude Code–specific dependencies while preserving all business logic, workflow steps, and quality standards. The output is the instructional body of a portable SKILL.md — no YAML frontmatter, no commentary, clean and ready to be pasted.

## Reading the input

The user provides the skill to transform in one of two ways:

- **File path**: a path like `path/to/SKILL.md` passed as the slash command argument — read the file using the Read tool.
- **Inline content**: the full skill text pasted directly into the message — use it as-is.

If the input is ambiguous or missing, ask: "Please paste the skill content or provide a file path."

## Transformation rules

Work through the input and apply these rules to every Claude-specific element you find. Preserve everything else verbatim.

---

### Rule 1 — Filesystem paths

**What to flag:** Paths containing `.claude/` as a directory component: `~/.claude/skills`, `.claude/skills`, `~/.claude`, `.claude/settings.json`, `.claude/settings.local.json`, etc.

**How to transform:**
- In the main workflow body: replace with a generic description.
  - `~/.claude/skills/my-skill/` → `your skills directory (e.g. skills/my-skill/)`
  - `.claude/settings.local.json` → `your agent's settings file`
- Move the original path to the **Environment-Specific Notes** section, labeled "If using Claude Code:".

**Example:**

Before:
> Copy the file to `~/.claude/skills/my-skill/`.

After (in body):
> Copy the file to your skills directory (e.g. `skills/my-skill/`).

After (in Environment-Specific Notes):
> **If using Claude Code:** skills directory is `~/.claude/skills/`.

---

### Rule 2 — Claude CLI commands

**What to flag:** Any invocation of the `claude` binary as a mandatory workflow step: `claude -p`, `claude run`, `claude chat`, `claude --help` used as instructions, "run this in the Claude terminal", etc.

**How to transform:**
- Remove from the main workflow instructions. Replace the step with a neutral description of the intent.
  - `claude -p "register skill ..."` → `Register the skill using your agent runtime's installation mechanism.`
  - `claude run my-skill` → `Invoke the skill from your agent's interface.`
- Move the original command verbatim to the **Environment-Specific Notes** section as an optional example.

**Example:**

Before:
> Run: `claude -p "register skill ~/.claude/skills/my-skill"`

After (in body):
> Register the skill using your agent runtime's installation mechanism.

After (in Environment-Specific Notes):
> **If using Claude Code (optional):** `claude -p "register skill ~/.claude/skills/my-skill"`

---

### Rule 3 — Product and runtime name mentions

**What to flag:** Phrases that tie instructions to a specific product: "in Claude Code", "in Cowork", "open Claude Code", "Claude Code terminal", "Claude Code only", "use the Skills panel", "press Space to toggle skillOverrides", "use the Claude sidebar".

**How to transform:** Replace with neutral equivalents that preserve the meaning:
- "in Claude Code" → "in your agent environment"
- "in Cowork" → "in your collaborative agent environment"
- "open Claude Code" → "open your agent interface"
- "use the Skills panel" → "check the skills list in your agent interface"
- "press Space to toggle skillOverrides" → "toggle the skill override setting in your agent interface"
- "Claude Code only" → "this step may vary by runtime — see Environment-Specific Notes"

---

### Rule 4 — Environment variables with CLAUDE_ prefix

**What to flag:** Variables used as runtime configuration keys: `CLAUDE_SKILL_DIR`, `CLAUDE_SESSION_ID`, `CLAUDE_PROJECT_ROOT`, `CLAUDE_EFFORT`, and any `CLAUDE_*` variable that represents runtime state.

**How to transform:**
- In the main body: replace with a generic functional name.
  - `CLAUDE_SKILL_DIR` → `SKILLS_DIR` (or describe in plain English: "your skills directory path")
  - `CLAUDE_SESSION_ID` → `SESSION_ID`
- Move the original variable name to the **Environment-Specific Notes** section.

---

### Rule 5 — Hardcoded internal tool names as guaranteed dependencies

**What to flag:** Tool names (`TodoWrite`, `Skill`, `Agent`, `WebFetch`, `Edit`, `Read`, `Write`) when the skill treats them as guaranteed to be available — e.g. "call the TodoWrite tool to track progress", "use the Agent tool to spawn a subagent".

**How to transform:**
- Replace the hard dependency with a description of the desired behavior:
  - "call the TodoWrite tool" → "track progress using your agent's task management system (if available)"
  - "use the Agent tool to spawn a subagent" → "spawn a subagent if your runtime supports parallel agent execution"
- If the feature is optional, note it as such. If it's essential, note it under Environment-Specific Notes as a runtime requirement.

---

## What NOT to transform

Do not touch these:

- **General shell commands**: `git`, `npm`, `python`, `curl`, `bash`, `uv`, `node`, `grep`, `find`, etc. These are portable.
- **AI model references**: "tell Claude to analyze...", "ask the model to...", "Claude will produce..." — these refer to the AI model, not the Claude Code product. Leave them as-is.
- **Business logic and workflow steps** — even if they mention Claude as a reasoning entity.
- **Output formats, quality criteria, examples, sample data** — preserve these exactly.
- **Existing neutral wording** — if a passage is already runtime-neutral, do not rewrite it.

**The most common mistake:** flagging "tell Claude to..." as a product reference. It is not. Only flag instructions tied to the Claude Code product interface or runtime.

---

## Handling input that is already runtime-neutral

If the skill contains no Claude-specific content, still reformat it into the recommended output structure below. At the top of the Environment-Specific Notes section, write:

> No Claude Code–specific content found. The content above is already runtime-neutral.

---

## Output structure

Produce the rewritten content in this order. Adapt section titles naturally if the original uses different headings — these are strongly recommended, not rigid labels:

1. **Overview** — 1–3 neutral paragraphs describing what the skill does and its purpose. No product names.
2. **When to use / When not to use** — include if the original had triggering conditions or exclusions.
3. **Instructions** — step-by-step, with all Claude-specific references transformed per the rules above. Preserve the original structure and flow as closely as possible.
4. **Output format** — if the original defined an expected output, preserve it exactly.
5. **Environment-Specific Notes** — collect here all CLI commands, paths, and env vars that were moved from the body. Use labeled subsections per runtime:
   ```
   ### If using Claude Code
   - skills directory: `~/.claude/skills/`
   - register command: `claude -p "register skill <path>"`
   ```
   If nothing was moved here, write: "None — this skill is fully portable."

---

## Output rules

- Output the rewritten body **only** — no YAML frontmatter.
- Write in English.
- Do not invent new tools, APIs, or steps that were not in the original.
- Do not add paragraph commentary about what you changed — the output should read as a clean, self-contained instruction document.

After the body content, append a clearly delimited transformation log:

```
---
TRANSFORMATION LOG (exclude this section from the final SKILL.md body)
- [list each element moved or replaced, one bullet per change]
- Example: Moved `~/.claude/skills` path to Environment-Specific Notes
- Example: Replaced "in Claude Code" → "in your agent environment" (3 occurrences)
- Example: Moved `claude -p` command to Environment-Specific Notes
---
```

This log is for the user's review only — it does not belong in the final SKILL.md.
