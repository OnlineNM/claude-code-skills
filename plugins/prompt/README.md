# pmpt — Prompt Engineering Tools

A Claude Code plugin for transforming raw user requests into structured, effective prompts before sending them to an LLM.

The core idea: vague prompts produce vague responses. These skills restructure what the user wants to say into a format that forces the model to produce clear, accurate, and actionable output.

## Skills

| Skill | Trigger | Best for |
|---|---|---|
| `pmpt:gcao` | "apply GCAO", "improve this prompt" | Any prompt — quick 4-part structure |
| `pmpt:universal` | "universal prompt", complex task description | Complex projects, reports, strategies |
| `pmpt:short` | "short prompt", "quick prompt" | Emails, summaries, recurring daily tasks |

---

### `pmpt:gcao` — GCAO Framework

Restructures a prompt using 4 components:

- **Goal** — the specific objective
- **Context** — domain, product, audience, constraints
- **Actions** — step-by-step instructions for the LLM
- **Output** — desired format, length, tone

Outputs a fenced code block ready to copy, with placeholders (`[...]`) for anything the user needs to fill in.

---

### `pmpt:universal` — Universal Prompt (7 components)

Full structured prompt for complex tasks requiring total control. Components:

| Component | Purpose |
|---|---|
| Role | Who the AI is (expert, teacher, editor) |
| Task | Precise description of the deliverable |
| Audience | Who the output is for |
| Context | Topic, discipline, existing materials |
| Rules | What you don't want |
| Format | Shape of the deliverable |
| Success criteria | Definition of a good response |

Includes a **confirmation pause**: the AI proposes a structure and flags missing info before producing the final result. Ends with a self-evaluation (strengths, weaknesses, improvements).

**Setup time:** longer | **Quality:** guaranteed

---

### `pmpt:short` — Short Prompt (8 fields)

Same logic as universal, compressed for daily use. Fits in ~15 seconds of setup:

```
Role / Desired output / Topic / Audience / Essential context / Rules / Format / Success criteria
```

Also includes a confirmation pause before the final response.

**Setup time:** ~15 seconds | **Use:** daily

---

## Output Format

All skills present the generated prompt in a fenced code block so it can be copied and edited before sending. Assumptions and placeholders are listed after the block.

All skills respond in the same language as the user's input (Romanian or English).
