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

## Updating an installed plugin after local changes

Plugins installed from the `claude-skills-laur` marketplace run from a **cached copy** under
`~/.claude/plugins/cache/claude-skills-laur/<plugin>/<version>/`, not from this repo's working
directory. Bumping a plugin's version here (`plugin.json`) does not update that cache — the
marketplace metadata and the plugin itself must be refreshed explicitly, then the session
restarted:

```
claude plugin marketplace update claude-skills-laur
claude plugin update <plugin>@claude-skills-laur
```

The `claude-skills-laur` marketplace is registered from the GitHub remote
(`https://github.com/OnlineNM/claude-code-skills.git`), not from this local working directory —
local commits must be pushed to `main` before `marketplace update` will see them.

Then restart the Claude Code session (or start a new one) for the refreshed skill list to load —
mid-session, the skill list injected into context is a snapshot taken at session start and won't
reflect the update.

**In the VS Code extension, starting a "New session" is not enough.** The extension host loads
the plugin cache once per VS Code window and doesn't rescan it for a new chat session. After
updating a plugin, open the Command Palette (`Cmd+Shift+P`) and run **"Developer: Reload
Window"** — that's what actually forces the extension host to re-read the updated plugin cache.
