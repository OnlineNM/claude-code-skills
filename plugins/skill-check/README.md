# skill-check

A plugin for checking whether a Claude Code skill is portable to other AI agent runtimes, and for converting it to a runtime-neutral format.

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| detect-claude | `/skill-check:detect-claude` | Detects Claude Code–specific dependencies inside a SKILL.md file and reports whether the skill is portable or needs cleanup first. |
| declaudeify | `/skill-check:declaudeify` | Removes Claude Code–specific instructions from a skill and replaces them with runtime-neutral equivalents. |
| convert | `/skill-check:convert` | Converts a skill into a standard portable SKILL.md format usable by other AI agents. |
| lint | `/skill-check:lint` | Validates that a SKILL.md file conforms to the standard portable format. |

## Typical workflow

### initial check

```
/skill-check:detect-claude path/to/SKILL.md
  → tells if the skill contains claude-specific instructions

/skill-check:lint path/to/SKILL.md
  → validation report
```

### claude-code skill to be converted
```
/skill-check:declaudeify path/to/SKILL.md
  → cleaned skill

/skill-check:convert path/to/SKILL.md
  → portable SKILL.md

/skill-check:lint path/to/SKILL.md
  → validation report
```
