# Step 02 — Interview Loop

**Reads:** `<idea-slug>` and `docs/<idea-slug>-SESSION.md` from `01-slug-and-branch.md`.

**Does:**

Start with a hypothesis, then ask one focused question at a time.

**First message format:**
```
HYPOTHESIS: <one sentence summary of what you think the user wants>
CONFIDENCE: ~X% — missing: <what is still unclear>
```

**Each subsequent question format:**
```
Q: <one focused question>
GUESS: <your current hypothesis with brief reasoning>
```

**Rules:**
- One question per message — never batch multiple questions
- Each question targets the most important unknown
- Push back on vague answers — offer two concrete options if needed

## Interaction Style

Where a reasonable default can be inferred from context already gathered, propose it and ask for confirmation or correction, instead of asking an open question. State the default plainly, e.g.: "Default: <X>. Confirm or tell me what to change." Reserve fully open questions for inputs with no inferable default (e.g. the raw idea description, the problem statement, or the first question of an interview before any context exists). This does not relax any existing explicit-confirmation requirement: a default still requires a clear yes or an explicit alternative choice from the user — passive agreement ("sounds good", "whatever you think") is still rejected per the restat rule in `03-confirm.md`, and the same standard applies wherever this style is used.

This interview loop keeps "one question per message" as a hard rule. The default-proposal style applies to the `GUESS:` line already present in the format — `GUESS:` should commit to a specific default the user can simply confirm, not a vague restatement.

**Stop condition:** You can confidently predict the user's reaction to the next three questions you would ask.

**Hands off:** A set of confirmed answers (recorded in `docs/<idea-slug>-SESSION.md` under Decisions Reached) to `03-confirm.md`.

## Dialog Log

After each question is answered, append an entry to `docs/<idea-slug>-DIALOG.md` (format in SKILL.md's "Dialog Log" section) recording the question and the user's answer. Do this incrementally, one entry per question — do not batch the whole interview into a single write at the end.
