---
name: universal
description: Transforms a user's request into a full 7-component structured prompt for complex tasks (Role, Task, Audience, Context, Rules, Format, Success criteria) with a confirmation pause before the final response. Use for complex projects, official reports, strategies, detailed deliverables, or whenever the user wants total control over the AI output. Trigger when the user says "universal prompt", "structured prompt", "help me write a prompt for a complex task", or shares a task that needs careful handling. Also trigger when the user wants guaranteed quality and is willing to spend a moment on setup.
---

# Universal Prompt Builder

Your job is to take the user's request and produce a complete, ready-to-use universal prompt using all 7 structured components. The goal is total control over the AI's output — no ambiguity, no guessing.

## The 7 Components

| Component | What it defines |
|---|---|
| **Role** | Who AI is in the conversation (expert, teacher, evaluator, editor) |
| **Task** | Precise description of the desired output (not "help me with something") |
| **Audience** | The audience's level — 5th graders vs. specialists |
| **Context** | Topic, discipline, source, what already exists |
| **Rules** | What you don't want: complex language, made-up information, overly long responses |
| **Format** | What the deliverable looks like: worksheet, essay, table, lesson, presentation |
| **Success criteria** | What an excellent response means: clear, actionable, verifiable |

## The Confirmation Pause

Every universal prompt ends with an instruction for the AI to pause before delivering the final result. This prevents wasted effort on misunderstood requests.

Before the final response, the AI must:
1. Confirm it understood the request
2. Briefly state what it will produce
3. Flag any missing information
4. Propose a structure

Only after the user's approval (the `go` command) does it continue. At the end, it also performs a **self-evaluation** (strengths, weaknesses, what can be improved).

## How to Build the Prompt

1. Read the user's request and extract or infer each of the 7 components.
2. For anything genuinely unknown, use `[...]` as a placeholder so the user knows to fill it in.
3. Write the prompt in clear, direct language — as if commissioning a capable expert.
4. Always include the confirmation pause and self-evaluation instructions at the end.

## Output Format

Present the result in a fenced code block (easy to copy), with a one-line note about assumptions made. List any placeholders after the block.

**Template:**

```
I want you to act as an expert in [domain].

Task: [precise description of the final deliverable]

Audience: [level, context, what they already know]

Important context: [topic, discipline, existing materials, constraints]

Constraints: clear language, no made-up information, no digressions, logical structure.

Style to follow: [examples of style or structure if you have them]

Success criteria: [what an excellent response means to you]

Before the final response: confirm you understood the request, state what you will produce, flag missing info, propose a structure. Wait for GO.

At the end, add a self-evaluation: strengths, weaknesses, what can be improved.
```

---

Respond in the same language the user wrote their request in.
