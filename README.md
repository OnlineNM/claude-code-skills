# claude-code-skills

Personal collection of Claude Code skills and plugins.

## Structure

```
skills/       — standalone skills: single-purpose slash commands that don't warrant a full plugin
plugins/      — multi-skill plugins grouped by domain
docs/         — design docs, plans, session notes
```

### `skills/` vs `plugins/`

A skill lives in `skills/` when it does one thing and has no natural siblings.
A group of related skills becomes a plugin in `plugins/` with its own namespace and `plugin.json`.

## Skills

| Skill | Path | Purpose |
|---|---|---|
| `brief` | [skills/brief/SKILL.md](skills/brief/SKILL.md) | Toggle response verbosity: `on` (terse), `lite` (concise), `off` (normal) |

## Plugins

| Plugin | Path | Skills |
|---|---|---|
| `pmpt` | [plugins/prompt/](plugins/prompt/) | `gcao`, `universal`, `short` — prompt engineering transforms |
| `ppc` | [plugins/paperclip/](plugins/paperclip/) | `define`, `deploy`, `pull`, `push`, `update`, `hire-config` — Paperclip agent lifecycle |
| `sdd` | [plugins/spec-driven-development/](plugins/spec-driven-development/) | Spec-driven development workflow |
| `dbg` | [plugins/debug/](plugins/debug/) | `diagnose`, `critique`, `handoff`, `improve-codebase-architecture` |
| `skill-check` | [plugins/skill-check/](plugins/skill-check/) | `detect-claude`, `declaudeify`, `convert`, `lint` — skill portability |
| `wbs` | [plugins/website/](plugins/website/) | `mockup`, `screenshot`, `css`, `design-recreation` |
| `telegram` | [plugins/telegram/](plugins/telegram/) | `notify`, `status`, `toggle` |
