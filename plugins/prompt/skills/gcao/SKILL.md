---
name: gcao
description: Transforms a user's raw prompt into a structured GCAO prompt (Goal, Context, Actions, Output) for better LLM responses. Use whenever the user wants to improve a prompt, asks to "structure this prompt", "make this prompt better with GCAO", "apply GCAO to", "reformulate this prompt", or shares a rough request and wants a more effective version before sending it to an LLM. Trigger even when GCAO is not explicitly named — if the user shares a vague prompt and says "help me make this clearer for AI" or "improve this prompt", use this skill.
---

# GCAO Prompt Transformer

Your job is to take the user's raw prompt and restructure it using the GCAO framework, then present the result so the user can review, copy, or edit it before sending it to an LLM.

## The GCAO Framework

GCAO improves LLM responses by giving the model full context up front:

- **Goal** — the specific objective or question the user wants answered
- **Context** — background the LLM needs: domain, product, audience, constraints, prior state
- **Actions** — clear, step-by-step instructions for what the LLM should do
- **Output** — the desired format, length, tone, and structure of the response

## How to Transform a Prompt

1. Read the user's prompt carefully.
2. Extract or infer each GCAO component — sometimes all four are explicit, sometimes you need to infer from context.
3. If something is genuinely unknown (e.g., the user didn't mention the audience), note it as a placeholder using `[...]` so the user knows to fill it in.
4. Write the GCAO prompt in clear, direct language — as if you're briefing a capable assistant.

## Output Format

Present the result in a fenced code block (so it's easy to copy), preceded by a one-line summary of what you inferred or assumed.

If you made assumptions or left placeholders, list them briefly after the block so the user knows what to review.

**Template:**

```
## Goal
[What the user wants to achieve — specific and measurable if possible]

## Context
[Who the user is, what they're working on, relevant domain/product/audience/constraints]

## Actions
[Numbered steps the LLM should follow to produce the result]

## Output
[Format, length, tone, structure — be specific: "a bulleted list", "a 3-paragraph email", "a JSON object with fields X, Y, Z"]
```

## Example

**User input:**
> Vreau un email catre clienti despre o intarziere in livrare

**GCAO output:**
```
## Goal
Redactează un email profesional prin care anunți clienții că comanda lor va fi livrată cu întârziere.

## Context
Companie de e-commerce din România. Clienții sunt persoane fizice care au plasat comenzi online. Întârzierea se datorează unor probleme logistice. Tonul trebuie să fie empatic și profesional.

## Actions
1. Deschide emailul cu o recunoaștere a întârzierii și o scuză sinceră.
2. Explică pe scurt motivul întârzierii (fără detalii tehnice excesive).
3. Indică noua dată estimată de livrare.
4. Oferă o compensație sau gest de bunăvoință (ex: voucher, prioritizare).
5. Închide cu un mesaj de mulțumire pentru răbdare și loialitate.

## Output
Email formal, în română, de 150–200 de cuvinte. Ton empatic și profesional. Fără jargon tehnic.
```

**Assumptions made:** client name and new delivery date left as `[...]` — fill these in before sending.

---

Respond in the same language the user wrote their prompt in.
