# coursiv

Plugin for processing lessons from [Coursiv.io](https://coursiv.io).

More skills will be added incrementally to `skills/` as lesson-processing workflows are defined.

## Skills

### `question` — `/coursiv:question`

Converts a screenshot of a Coursiv.io quiz question into a clean, copy/paste-ready Markdown block (question, unchecked answer options, correct answer(s), and explanation).

- **Input:** a `.png` screenshot, given as an explicit path or just a bare filename. If only a filename is given and it doesn't resolve relative to the current directory, the skill falls back to looking in the `0_Inbox` folder of the user's "SecondBrain" Obsidian vault.
- **Output:** a single Markdown block, ready to paste into notes or a question bank — no preamble, no commentary.

See [skills/question/SKILL.md](skills/question/SKILL.md) for the full behavior and formatting rules.

### `prompt` — `/coursiv:prompt`

Converts a pair of screenshots from a Coursiv.io "complete the prompt" exercise (incomplete prompt + option chips, and completed prompt + AI response) into a clean, copy/paste-ready Markdown block.

- **Input:** two `.png` screenshots (order doesn't matter — the skill tells them apart by content), each resolved the same way as `question`'s single image (explicit path, or bare filename falling back to `0_Inbox`).
- **Output:** a Markdown block with the exercise title/instruction, the incomplete prompt with its placeholder options (in the screenshot's visual order), the completed final prompt, and the AI's response.

See [skills/prompt/SKILL.md](skills/prompt/SKILL.md) for the full behavior and formatting rules.

### `columns` — `/coursiv:columns`

Converts a pair of screenshots from a Coursiv.io "match the columns" exercise (unsolved two-column layout, and solved/matched pairs) into a clean, copy/paste-ready Markdown block.

- **Input:** two `.png` screenshots (order doesn't matter — the skill tells them apart by content), each resolved the same way as `question`'s single image (explicit path, or bare filename falling back to `0_Inbox`).
- **Output:** a Markdown block with the title/instruction, both columns in the unsolved screenshot's original order, and the correct left-to-right mapping worked out from the solved screenshot.

See [skills/columns/SKILL.md](skills/columns/SKILL.md) for the full behavior and formatting rules.

### `workflow` — `/coursiv:workflow`

Converts a pair of screenshots from a Coursiv.io "put the steps in order" exercise (scrambled step cards, and the same cards rearranged into the correct order) into a clean, copy/paste-ready Markdown block.

- **Input:** two `.png` screenshots (order doesn't matter — the skill tells them apart by content), each resolved the same way as `question`'s single image (explicit path, or bare filename falling back to `0_Inbox`).
- **Output:** a Markdown block with the title/instruction, the steps in the scrambled screenshot's original order (using each card's own printed letter), and the correct sequence worked out from the solved screenshot.

See [skills/workflow/SKILL.md](skills/workflow/SKILL.md) for the full behavior and formatting rules.

### `lesson` — `/coursiv:lesson`

Expands the `%id_kind%` placeholder markers (e.g. `%1_q%`, `%5q%`, `%6p%`, `%7c%`, `%8w%`) inside a Coursiv.io lesson Markdown export into real content, by dispatching each marker to the matching sub-skill and substituting its output in place.

- **Input:** a path to a lesson Markdown file exported from Coursiv.io.
- **Output:** the same file, overwritten in place with the markers expanded (no separate output file). Markers of kind `q` are resolved via the `question` skill; kind `p` via `prompt` (`<id>pq.png` / `<id>pa.png`); kind `c` via `columns` (`<id>cq.png` / `<id>ca.png`); kind `w` via `workflow` (`<id>wq.png` / `<id>wa.png`); markers of any other kind have no registered sub-skill yet and are left untouched.

See [skills/lesson/SKILL.md](skills/lesson/SKILL.md) for the full behavior.
