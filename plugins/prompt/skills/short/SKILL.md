---
name: short
description: Transforms a user's request into a compact 8-field structured prompt for daily use (Role, Desired output, Topic, Audience, Essential context, Rules, Format, Success criteria) with a quick confirmation before the final response. Use for emails, summaries, quick ideas, recurring tasks, or any situation where the user needs a well-structured prompt fast. Trigger when the user says "short prompt", "quick prompt", "daily prompt", "compress this into a prompt", or wants a prompt they can reuse regularly. Ideal when setup time matters and the task doesn't need complex multi-step control.
---

# Short Prompt Builder

Your job is to take the user's request and produce a compact, ready-to-use structured prompt. Same logic as the universal prompt — but compressed for speed. Ideal for daily use: emails, summaries, quick ideas, recurring tasks.

## The 8 Fields

| Field | What it defines |
|---|---|
| **Role** | Expert, teacher, editor — who AI is |
| **Desired output** | What it must produce, precisely |
| **Topic** | The subject matter |
| **Audience** | Who the result is for |
| **Essential context** | Key information the AI needs |
| **Rules** | What you don't want |
| **Format** | What the deliverable looks like |
| **Success criteria** | Definition of a good response |

## The Confirmation Pause

Even in the short format, the AI pauses before delivering the final result — it proposes a structure and flags missing info, then waits for the `go` command.

## How to Build the Prompt

1. Read the user's request and fill in all 8 fields.
2. Use `[...]` for anything genuinely unknown — the user can fill these in before sending.
3. Keep every field tight: one line each, no padding.
4. Always end with the confirmation pause instruction.

## Output Format

Present the result in a fenced code block (easy to copy), with a one-line note about assumptions made. List any placeholders after the block.

**Template:**

```
Role: [expert/teacher/editor]
Desired output: [what it must produce]
Topic: [subject]
Audience: [target audience]
Essential context: [key information]
Rules: [what you don't want]
Format: [what the deliverable looks like]
Success criteria: [definition of a good response]

Propose a structure and flag missing info before the final response. Wait for GO.
```

---

Respond in the same language the user wrote their request in.
