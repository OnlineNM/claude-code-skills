---
name: design-recreation
description: >
  Pixel-perfect recreation of UI designs from reference screenshots or images into HTML/CSS/Tailwind.
  Use this skill whenever the user provides a screenshot, image, or visual reference and asks you to
  build, recreate, replicate, implement, or match it as a webpage or component — even if they say
  "make something like this", "turn this into HTML", "copy this design", "match this layout",
  or just drop an image without explicit instructions. Also trigger when the user says things like
  "pixel-perfect", "match exactly", "same as the screenshot", or "make it look like this".
  This skill governs the full workflow: code generation, iterative screenshot comparison, and constraints.
---

## Technical Defaults

- Load Tailwind CSS via CDN: `<script src="https://cdn.tailwindcss.com"></script>`
- For missing images: use `https://placehold.co/` for placeholders, or `https://picsum.photos/` for realistic photos (landscapes, objects, people). Ask the user which to use if not specified.
- Mobile-first responsive design.
- Deliver a single `index.html` file with all styles inline unless the user requests otherwise.

## Workflow

Follow this iterative loop until the output matches the reference within ~2–3px:

1. **Generate** — Write the full `index.html` using Tailwind CSS. All content inline, no external files.

2. **Screenshot** — Render the page with Puppeteer:
   ```
   npx puppeteer screenshot index.html --fullpage
   ```
   Capture individual sections too if the page has distinct regions.

3. **Compare** — Diff your screenshot against the reference. For every mismatch, be specific:
   - Spacing/padding (e.g. "gap is 12px, should be 24px")
   - Font size, weight, line-height (e.g. "heading is 32px, reference shows ~24px")
   - Colors (exact hex values)
   - Alignment and positioning
   - Border-radius, shadows, effects
   - Image/icon sizing and placement

4. **Fix** — Edit the HTML/Tailwind code to address every mismatch found.

5. **Re-screenshot** — Capture again and compare.

6. **Repeat** steps 3–5 — Do not stop after one pass. Always complete at least 2 full comparison rounds. Stop only when the user says so or no visible differences remain.

## Constraints

- Do not add features, sections, or content not present in the reference image.
- Match the reference exactly — do not "improve" or "enhance" the design.
- If the user provides CSS classes or style tokens, use them verbatim.
- Keep code clean but avoid over-abstraction — inline Tailwind classes are fine.
- When reporting mismatches, always be specific with measurements (px, hex values, ratios).
