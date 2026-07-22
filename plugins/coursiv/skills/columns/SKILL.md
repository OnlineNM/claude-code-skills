---
name: columns
description: Converts a pair of screenshots from a Coursiv.io "match the columns" exercise (one showing the unsolved two-column layout, one showing the solved/matched pairs) into a clean, copy/paste-ready Markdown block with both columns and the correct mapping between them. Use this skill whenever the user gives two image paths from a Coursiv column-matching exercise and asks to turn them into Markdown, or invokes `/coursiv:columns`. Trigger it even if they just paste two `.png` paths from a Coursiv lesson without spelling out the format they want — that's exactly this skill's job.
---

# Coursiv Match-the-Columns Exercise → Markdown

Convert a pair of screenshots from a Coursiv.io column-matching exercise into a clean Markdown block, ready to paste into notes or an exercise bank.

## Input

Two `.png` files, from the same exercise:
- one shows the exercise's **unsolved state**: a title, an instruction, and two columns of boxes — left-hand items and right-hand items — in whatever order the exercise first presents them, with no indication yet of which left item goes with which right item.
- one shows the exercise's **solved state**: the same items, but rearranged into matched pairs (often shown as rows, each numbered) so the correct left-right pairing is visible.

### Telling the two images apart

Filenames for this exercise type usually follow a naming convention: `<id>c<q|a>.png` — a numeric `id`, then `c` for "columns", then either `q` (question — the unsolved state) or `a` (answer — the solved state). So `600cq.png` is the unsolved state and `600ca.png` is the solved state of the same exercise (id `600`).

Use that when both filenames follow it — it's the fastest way to know which is which. But don't treat it as gospel; if the naming is unclear or the two files don't share an `id`, fall back to reading both images: the one where left and right items appear in two independent, unmatched columns is the unsolved state; the one where items are grouped into paired rows (often with matching numbers on both boxes in a pair) is the solved state.

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

##### Left column
1. <left item 1>
2. <left item 2>
3. <left item 3>

##### Right column
A. <right item A>
B. <right item B>
C. <right item C>

##### Correct matches
1 → <letter>
2 → <letter>
3 → <letter>
```

Blank line placement: a heading is always immediately followed by its own content on the next line, no gap. A blank line separates the title+instruction from the rest, and separates each of the three `#####` sections from the one before it — but there's no blank line between the heading and its own list.

### Title and instruction
Transcribe both exactly as they appear in the unsolved screenshot — same wording, same punctuation.

### Left column and right column
Transcribe strictly from the **unsolved** screenshot — the solved one rearranges items into matched rows, which is not the order to record here:
- Left column: number the items starting at 1, in the order they appear in the unsolved screenshot (top to bottom).
- Right column: letter the items starting at A, in the order they appear in the unsolved screenshot (top to bottom, or left to right if right-column items are laid out that way).
- Transcribe each item's text exactly — same wording, punctuation, and capitalization as shown. Don't reorder either column to anticipate the solution; the whole point of these two lists is to preserve the exercise's original, unsolved presentation.

### Correct matches
This is the one place the **solved** screenshot matters. It typically regroups items into paired rows (sometimes with a shared number badge on both boxes of a pair) — use those pairings to figure out which left item goes with which right item, then translate that pairing back into the numbers/letters you assigned above (from the *unsolved* screenshot's order), not into the item text again.

- One line per left item, in numeric order: `1 → <letter>`.
- Only the number-to-letter mapping — never repeat the item text here.
- Don't add extra formatting, explanations, or anything beyond the plain `N → L` lines.

## Ignore all UI chrome

Same principle as the rest of this plugin: badges, checkmarks, colors, borders, "Continue" buttons, and any other platform decoration are rendering details, not content — never transcribe them. The only thing borrowed from the solved screenshot's visual grouping is the *pairing itself*, not any numbers or styling it displays.

## Example

Given an unsolved screenshot titled "Which Format Fits the Purpose?" with instruction "Match each purpose with the most suitable writing format," left column (top to bottom) "Presenting progress to your manager", "Teaching a concept", "Sharing a quick overview", "Explaining trade-offs", and right column (top to bottom) "Status update email", "Comparison table", "Bullet summary", "Step-by-step guide" — and a solved screenshot that regroups them into matched rows: "Presenting progress to your manager" + "Status update email", "Explaining trade-offs" + "Comparison table", "Teaching a concept" + "Step-by-step guide", "Sharing a quick overview" + "Bullet summary" — the output would be:

```markdown
#### Which Format Fits the Purpose?
Match each purpose with the most suitable writing format.

##### Left column
1. Presenting progress to your manager
2. Teaching a concept
3. Sharing a quick overview
4. Explaining trade-offs

##### Right column
A. Status update email
B. Comparison table
C. Bullet summary
D. Step-by-step guide

##### Correct matches
1 → A
2 → D
3 → C
4 → B
```

Note how the solved screenshot's own row order (1: Presenting/Status, 2: Explaining/Comparison, 3: Teaching/Step-by-step, 4: Sharing/Bullet) doesn't appear anywhere in the output — it was only used to work out the pairing. The output's left and right columns keep the unsolved screenshot's original order, and "Correct matches" is sorted by left-column number (1, 2, 3, 4), not by the solved screenshot's row order.
