---
name: workflow
description: Converts a pair of screenshots from a Coursiv.io "put the steps in order" exercise (one showing the steps in scrambled order, one showing them rearranged into the correct order) into a clean, copy/paste-ready Markdown block. Use this skill whenever the user gives two image paths from a Coursiv step-ordering exercise and asks to turn them into Markdown, or invokes `/coursiv:workflow`. Trigger it even if they just paste two `.png` paths from a Coursiv lesson without spelling out the format they want — that's exactly this skill's job.
---

# Coursiv Step-Ordering Exercise → Markdown

Convert a pair of screenshots from a Coursiv.io step-ordering ("put these in the right order") exercise into a clean Markdown block, ready to paste into notes or an exercise bank.

## Input

Two `.png` files, from the same exercise:
- one shows the exercise's **scrambled state**: a title, an instruction, and a single column of draggable item cards, each already printed with its own letter label (`a.`, `b.`, `c.`, …), in whatever order the exercise first presents them.
- one shows the exercise's **solved state**: the same lettered cards, rearranged top-to-bottom into the correct order.

The letters aren't something you assign — they're already printed on each card as part of its text in both screenshots. Your job is to record which order the cards were *shown* in (scrambled screenshot) and which order they were *rearranged into* (solved screenshot), using the letters that are already there.

### Telling the two images apart

Filenames for this exercise type usually follow a naming convention: `<id>w<q|a>.png` — a numeric `id`, then `w` for "workflow", then either `q` (question — the scrambled state) or `a` (answer — the solved state). So `500wq.png` is the scrambled state and `500wa.png` is the solved state of the same exercise (id `500`).

Use that when both filenames follow it. But don't treat it as gospel; if the naming is unclear or the two files don't share an `id`, fall back to reading both images and telling them apart by content — in the scrambled state, the item letters won't read in order top-to-bottom; in the solved state, they will.

### Resolving the file paths

Apply this to each of the two images independently — one might be given as an explicit path while the other is just a bare filename:

If given an explicit path (absolute, or relative to a location that clearly exists), just use it as given.

If given a bare filename with no path and it doesn't resolve relative to the current directory, don't give up — this user drops screenshots into their Obsidian inbox before asking for them to be processed. Look for the file in `/Users/lairimia/Obsidian/SecondBrain/0_Inbox` (the `0_Inbox` folder of their "SecondBrain" Obsidian vault) before concluding it doesn't exist.

If either file isn't found in either place, say so clearly — name both locations you checked, and which of the two files is missing — rather than guessing at a path or silently producing partial output.

Read both images directly once located (they're normal image files, so a plain `Read` on each path works).

### Cleaning up the inbox

For each image that lives inside `0_Inbox` — whether given as an explicit path pointing there, or found there via the fallback above — delete that file once you've successfully produced the Markdown output. That folder is a drop point for screenshots waiting to be processed, not permanent storage. Only delete after the transcription actually succeeded, and only the files that actually came from `0_Inbox` — leave alone any image given via an explicit path elsewhere (e.g. the current directory).

## Output format

Output ONLY the Markdown block below — no preamble, no closing remarks, no extra explanation, no emoji. Just the block itself, so it can be copy/pasted straight into a note.

```markdown
#### <Title>
<Instruction>

##### Initial order
**<letter>.** <item text>
**<letter>.** <item text>
**<letter>.** <item text>

##### Correct order
1. **<letter>**
2. **<letter>**
3. **<letter>**
```

Blank line placement: a heading is always immediately followed by its own content on the next line, no gap. A blank line separates the title+instruction from the rest, and separates the two `#####` sections from each other — but there's no blank line between a heading and its own list, and none between the individual lines of either list.

### Title and instruction
Transcribe both exactly as they appear above the item cards in the scrambled screenshot — same wording, same punctuation. Don't confuse the instruction with the generic helper line above the cards (usually something like "Drag the items below into order") — that's UI chrome, not the exercise's actual instruction; leave it out entirely (see "Ignore all UI chrome" below).

### Initial order
Transcribe strictly from the **scrambled** screenshot, top to bottom, one line per card: `**<letter>.**` (the letter already printed on that card, bold, followed by a period) then the card's text. Use the order the cards actually appear in that screenshot — don't reorder to alphabetical or to the solution, and don't renumber; the letters already printed on the cards are the only labels you need.

If a card's text wraps across multiple visual lines only because the card is narrow, join it back into one line — that's a layout artifact, not a real line break. Keep it as an actual multi-line item only if the card clearly shows a real paragraph break.

### Correct order
This is the one place the **solved** screenshot matters: read off the letters in the order the cards were rearranged into, top to bottom, and number that sequence starting at 1. Only the letter (bold) on each line — never repeat the item text here.

## Ignore all UI chrome

Same principle as the rest of this plugin: the generic "Drag the items below into order" helper text, drag handles, borders, highlight colors, and buttons like "Check" or "Continue" are rendering details of the platform, not exercise content — never transcribe them. Success banners ("Amazing!", etc.) on the solved screenshot are the same — ignore them, they're not part of the correct order itself.

## Example

Given a scrambled-state screenshot titled "Editing With Precision" with instruction "You prepared a speech for your team but want to make the intro sound more friendly. Order the steps for refining the first paragraph." and four cards, top to bottom: "a. Give Gemini a specific goal for just that selection in the pop-up window.", "b. Get the final draft ready or refine further.", "c. Paste your draft into the prompt and pick Canvas.", "d. Select specific portions of the text you want to change." — and a solved-state screenshot showing the same cards rearranged top to bottom as c, d, a, b — the output would be:

```markdown
#### Editing With Precision
You prepared a speech for your team but want to make the intro sound more friendly. Order the steps for refining the first paragraph.

##### Initial order
**a.** Give Gemini a specific goal for just that selection in the pop-up window.
**b.** Get the final draft ready or refine further.
**c.** Paste your draft into the prompt and pick Canvas.
**d.** Select specific portions of the text you want to change.

##### Correct order
1. **c**
2. **d**
3. **a**
4. **b**
```

Note the "Initial order" section keeps the letters in the scrambled screenshot's own printed order (a, b, c, d here — but don't expect that alphabetically-clean an order in general, since the letters are fixed to their cards and the scrambled screenshot can show them in any order at all), while "Correct order" is a completely separate sequence read from the solved screenshot.
