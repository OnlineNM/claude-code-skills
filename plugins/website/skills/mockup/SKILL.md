---
name: mockup
description: >
  Full-pipeline clone of any live webpage: captures a screenshot, extracts CSS styles,
  then recreates the page as pixel-perfect HTML/Tailwind — all from a single URL.
  Use this skill whenever the user gives a URL and wants to clone, copy, replicate,
  or recreate a webpage as code. Also trigger for phrases like "make a mockup of",
  "recreate this site", "clone this page", "build something like this URL",
  or "turn this website into HTML". This skill runs the complete workflow automatically —
  screenshot → CSS extraction → HTML/Tailwind recreation — without any manual steps.
---

## What this skill does

Given a URL, runs three steps in sequence:

1. **Screenshot** — captures the full page as a PNG reference image
2. **CSS extraction** — extracts CSS custom properties, `@font-face` rules, and computed `body` styles
3. **Recreation** — uses the screenshot + CSS as inputs to build a pixel-perfect HTML/Tailwind clone

## Workflow

### Step 1 — Capture screenshot

```bash
node <SCREENSHOT_SKILL_PATH>/scripts/screenshot.js <url>
```

Resolve `<SCREENSHOT_SKILL_PATH>` from the active skill paths (the `screenshot` skill in the same `website` plugin). This saves a PNG in the current working directory.

### Step 2 — Extract CSS

```bash
node <CSS_SKILL_PATH>/scripts/extract-styles.js <url>
```

Resolve `<CSS_SKILL_PATH>` from the active skill paths (the `css` skill in the same `website` plugin). This saves a `.css` file in the current working directory.

### Step 3 — Recreate as HTML/Tailwind

With both files saved, invoke the `design-recreation` skill. Pass it:
- The PNG from Step 1 as the reference image
- The CSS file from Step 2 as style context (use the design tokens and `@font-face` rules verbatim)

The design-recreation skill handles the rest: generating `index.html`, screenshotting, comparing, and iterating until the output matches the reference.

## Notes

- All output files land in the current working directory (where Claude was invoked from).
- If the user specifies a custom output directory, pass it as the output argument to both scripts.
- Steps 1 and 2 are fast (~5–10s each). Step 3 is iterative and takes longer — set the right expectation with the user upfront.
- If either script is missing its `node_modules`, it auto-installs `puppeteer-core` on first run (~15s).
