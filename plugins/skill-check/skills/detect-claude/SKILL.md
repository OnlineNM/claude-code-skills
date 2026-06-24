---
name: detect-claude
description: Analyzes a SKILL.md file or any skill document and reports whether it contains Claude Code–specific dependencies that would prevent it from being used in other AI agent runtimes. Use whenever a user wants to check skill portability, asks "is this skill Claude-specific?", "can I use this skill in other agents?", "check for Claude dependencies", "is this skill portable?", "detect runtime coupling", "scan this skill for Claude-specific stuff", or wants to know whether to run /skill-check:declaudeify before converting or sharing a skill. Always invoke this before /skill-check:convert.
---

# detect-claude — Claude Dependency Detector

Your only job is to detect whether a skill document is tightly coupled to the Claude Code environment. Do not rewrite, fix, or evaluate the skill's quality or structure — only scan and report.

## Reading the input

The user provides the skill to analyze in one of two ways:

- **File path**: a path like `path/to/SKILL.md` passed as the slash command argument — read the file using the Read tool.
- **Inline content**: the full skill text pasted directly into the message — use it as-is without reading any file.

If the input is ambiguous or missing, ask: "Please paste the SKILL.md content or provide a file path to analyze."

## What to scan for

Work through each category below in order. For every finding, capture two things:
- **snippet** — the exact short excerpt (one line is enough to show context)
- **location** — where you found it: `"frontmatter"`, `"body: section '<name>'"`, or `"body: line ~N"` if there is no section heading

### Category 1 — Filesystem references

Flag paths or phrases pointing to Claude-specific directory locations:
- Paths that contain `.claude/` as a directory component: `.claude/skills`, `~/.claude/`, `.claude/settings.json`, `.claude/settings.local.json`, `.claude/rules/`, etc.
- Mentions of "Claude skills directory" or "skills dir" when clearly referring to `.claude/`

Skip generic project-relative paths like `./src/`, `~/projects/`, `/tmp/`, `./config/` — those are portable.

### Category 2 — Environment variable references

Flag env vars that are runtime configuration keys specific to Claude Code:
- Known Claude runtime vars: `CLAUDE_SKILL_DIR`, `CLAUDE_SESSION_ID`, `CLAUDE_PROJECT_ROOT`, `CLAUDE_EFFORT`
- Any variable with a `CLAUDE_` prefix used as a runtime config key, not just as a name that happens to contain the word "Claude"

Skip general-purpose vars like `NODE_ENV`, `HOME`, `PATH`, or vars where `CLAUDE` appears as a project or product name rather than a runtime identifier.

### Category 3 — UI / product references

Flag instructions that only make sense inside the Claude Code product interface:
- "open this file in Claude Code", "use the Skills panel in Claude"
- "press Space to toggle skillOverrides", "click the Run button in Claude Code"
- "use the Claude sidebar", "enable this in Claude Code settings", "toggle in the Claude interface"

Skip generic AI model mentions like "tell Claude to...", "ask the model to...", or "Claude will handle..." — those refer to the AI model, not the product UI.

### Category 4 — CLI / command references

Flag the `claude` CLI invoked as a runtime tool the skill depends on:
- `claude -p`, `claude run`, `claude chat` when used as executable instructions the user or skill must run
- Instructions like "run this in the Claude terminal" or "type /command in Claude Code"

Skip general shell commands that any environment can run: `git`, `npm`, `python`, `curl`, `bash`, `uv`, `node`, `grep`, etc.

### Category 5 — Hardcoded Claude-only APIs or tool names

Flag APIs, internal tool names, or slash commands that explicitly exist only in Claude Code and that the skill treats as guaranteed to be available:
- Slash commands described as Claude Code–specific: "use /skill-creator in Claude Code"
- Internal tool names — `TodoWrite`, `WebFetch`, `Skill`, `Agent`, `Edit`, `Read`, `Write`, etc. — **only flag these if the skill instructs Claude to call them as if they are guaranteed to exist in any runtime**
- Statements like "this only works in Claude Code" or "Claude Code only"

Skip mentions of these tools in examples or documentation, or cases where the skill explicitly notes they may not be available.

## Conservatism rule

When uncertain whether something is Claude-specific: include it under the relevant category with a note like `(uncertain — may be Claude-specific)`, but do not let uncertainty alone push the classification to `REQUIRES_DECLAUDEFY_FIRST`. Only use that classification when you have at least one clear, unambiguous finding.

If you find zero Claude-specific references, set `has_claude_specific: false` and explicitly say the skill appears safe to use across runtimes.

## Output format

Produce the report in exactly this markdown structure:

---

### Summary

**has_claude_specific:** `true` | `false`

**short_overview:** [1–3 sentences. State directly whether the skill is tightly coupled to Claude Code or appears runtime-neutral. Name the main source of coupling if there is one.]

---

### Findings

**filesystem_references:**
- `<snippet>` — location: `<where>`
- *(none found)*

**env_var_references:**
- `<snippet>` — location: `<where>`
- *(none found)*

**ui_references:**
- `<snippet>` — location: `<where>`
- *(none found)*

**cli_references:**
- `<snippet>` — location: `<where>`
- *(none found)*

**other_runtime_coupling:**
- `<snippet>` — location: `<where>` — note: `<why you flagged this>`
- *(none found)*

---

### Recommendation

**classification:** `SAFE_TO_USE_ACROSS_RUNTIMES` | `REQUIRES_DECLAUDEFY_FIRST`

**explanation:**
- [2–5 bullets summarizing why you chose this classification]

**suggested_next_steps:**
- [2–5 concrete bullets on what the user should do next, referencing /skill-check:declaudeify or /skill-check:convert as appropriate]

---

When `has_claude_specific` is `false`, the recommendation must include: "This skill appears safe to use across runtimes — you can proceed directly to `/skill-check:convert`."
