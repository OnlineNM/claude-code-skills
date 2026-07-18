# coursiv

Plugin for processing lessons from [Coursiv.io](https://coursiv.io).

More skills will be added incrementally to `skills/` as lesson-processing workflows are defined.

## Skills

### `question` — `/coursiv:question`

Converts a screenshot of a Coursiv.io quiz question into a clean, copy/paste-ready Markdown block (question, unchecked answer options, correct answer(s), and explanation).

- **Input:** a `.png` screenshot, given as an explicit path or just a bare filename. If only a filename is given and it doesn't resolve relative to the current directory, the skill falls back to looking in the `0_Inbox` folder of the user's "SecondBrain" Obsidian vault.
- **Output:** a single Markdown block, ready to paste into notes or a question bank — no preamble, no commentary.

See [skills/question/SKILL.md](skills/question/SKILL.md) for the full behavior and formatting rules.
