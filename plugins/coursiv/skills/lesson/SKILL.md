---
name: lesson
description: Expands `%id_kind%` markers inside a Coursiv.io lesson Markdown export (e.g. `%1_q%`, `%5q%`, `%6p%`, `%7c%`, `%8w%`) into real content, by dispatching each marker to the matching Coursiv sub-skill (`question` for quiz markers, `prompt` for fill-in-the-blank prompt exercises, `columns` for column-matching exercises, `workflow` for step-ordering exercises) and substituting its output in place. Use this whenever the user gives a path to a lesson Markdown file exported from Coursiv.io and wants those `%...%` placeholders filled in, or invokes `/coursiv:lesson`. Trigger it even if they just paste a `.md` path and say something like "process this lesson" or "fill in the questions" — that's exactly this skill's job.
---

# Coursiv Lesson Expander

Coursiv.io lesson exports (Markdown, via a clipper like Obsidian Web Clipper) contain placeholder markers where interactive elements — quiz questions, prompt/column/step exercises — used to be. This skill walks the file, resolves each marker to real content, and overwrites the file in place with the expanded result.

## Input

One path to a Markdown file exported from Coursiv.io (e.g. `tmp/Coursiv.md`).

## Step 1: Find the markers

Markers look like `%<id><kind>%` or `%<id>_<kind>%` — one or more digits (the `id`), optionally followed by an underscore, followed by one or more letters (the `kind`). For example: `%1_q%`, `%5q%`, `%6p%`.

For each marker found, keep track of:
- its exact original text, including the `%` signs (you'll search-and-replace on this)
- `id`: the digit portion
- `kind`: the letter portion

The `id` and the underscore (if present) are both part of the marker's identity — `%1_q%` and `%1q%` are different markers, so preserve the marker exactly as written when you need to reference the underlying file.

## Step 2: Dispatch each marker by kind

Go through the markers in order and handle them by `kind`:

**`kind == "q"` (quiz question):** This maps to the `question` skill (`/coursiv:question`, at `../question/SKILL.md` relative to this file). Follow that skill's instructions to produce a Markdown block for this question, passing it the filename `<marker text>.png` — e.g. for marker `%1_q%` pass `1_q.png`, for marker `%5q%` pass `5q.png`. That's a bare filename with no path, so `question`'s own fallback logic will look for it relative to the current directory and then in the `0_Inbox` Obsidian folder — you don't need to duplicate that search here, just hand off the filename and let it resolve the file itself.

Take the Markdown block that comes back and use it as the replacement for this marker.

**`kind == "p"` (fill-in-the-blank prompt exercise):** This maps to the `prompt` skill (`/coursiv:prompt`, at `../prompt/SKILL.md` relative to this file). That skill needs two images — the exercise's initial state and its completed state — so build both filenames from the marker's `id` and `kind` by appending `q` and `a` respectively, then `.png`: for marker `%6p%`, pass `6pq.png` (initial state) and `6pa.png` (completed state), in that order. Both are bare filenames with no path, so `prompt`'s own fallback logic will look for them relative to the current directory and then in `0_Inbox` — hand off the two filenames and let it resolve them itself, the same way you already do for `question`.

Take the Markdown block that comes back and use it as the replacement for this marker.

**`kind == "c"` (match-the-columns exercise):** This maps to the `columns` skill (`/coursiv:columns`, at `../columns/SKILL.md` relative to this file). Same two-image pattern as `prompt`: build both filenames from the marker's `id` and `kind` by appending `q` and `a`, then `.png` — for marker `%7c%`, pass `7cq.png` (unsolved state) and `7ca.png` (solved state), in that order. Both are bare filenames; let `columns`'s own fallback resolve them (current directory, then `0_Inbox`).

Take the Markdown block that comes back and use it as the replacement for this marker.

**`kind == "w"` (step-ordering exercise):** This maps to the `workflow` skill (`/coursiv:workflow`, at `../workflow/SKILL.md` relative to this file). Same two-image pattern again: for marker `%8w%`, pass `8wq.png` (scrambled state) and `8wa.png` (solved state), in that order, as bare filenames.

Take the Markdown block that comes back and use it as the replacement for this marker.

**Any other `kind`:** There's no sub-skill for it yet. Leave the marker exactly as it appears in the source file — untouched, not commented out, not flagged. Don't guess at what it might mean or try to improvise a replacement; a future skill will handle it once one exists. It's fine (expected, even) for the expanded output to still contain markers of an unhandled kind.

## Step 3: Substitute and save

Replace each resolved marker in the document with its generated Markdown block (surrounded by the same blank-line spacing the marker had, so the result reads as normal Markdown rather than everything jammed together). Leave unresolved markers (unknown `kind`) in place.

Write the result back to the same file you read it from, overwriting it in place — there's no separate `.expanded.md` output file.

Tell the user that the file was overwritten in place, how many markers you resolved, and list any markers you had to leave untouched (with their `kind`) so they know what's still pending — that's especially important here since, unlike a sibling output file, there's no separate copy left to compare against.

## Example

Given a snippet like:

```markdown
## Before we start, what do you think is the hardest part in this kind of situation?

%1_q%

## Meet Gemini
```

Resolving `%1_q%` means: run the `question` skill against `1_q.png`, get back its Markdown block, and substitute it in:

```markdown
## Before we start, what do you think is the hardest part in this kind of situation?

#### Before we start, what do you think is the hardest part in this kind of situation?

- [ ] Remembering where you saved each file
- [ ] Finding the time to read and connect everything together
- [ ] Understanding the content of each individual piece

##### Correct answer

- Finding the time to read and connect everything together

##### Explanation

Most professionals can handle individual documents. The real challenge is synthesizing multiple inputs when you're already stretched thin.

## Meet Gemini
```

A marker like `%6p%` resolves the same way, just via `prompt` instead of `question`: run the `prompt` skill against `6pq.png` and `6pa.png`, get back its Markdown block, and substitute it in. `%7c%` and `%8w%` follow the identical pattern via `columns` (`7cq.png` / `7ca.png`) and `workflow` (`8wq.png` / `8wa.png`) respectively.

A marker of a kind with no sub-skill registered yet (say, hypothetically, `%9x%`) stays as `%9x%` in the output, untouched.
