#!/usr/bin/env node
const { execFileSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const installDir = path.join(__dirname, '..');
const pcPath = path.join(installDir, 'node_modules', 'puppeteer-core');

if (!fs.existsSync(pcPath)) {
  console.log('Installing puppeteer-core (one-time setup)...');
  execFileSync('npm', ['install', 'puppeteer-core'], { cwd: installDir, stdio: 'inherit' });
}

const puppeteer = require(pcPath);

function findChrome() {
  const candidates = [
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium',
    '/usr/bin/chromium-browser',
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Chromium.app/Contents/MacOS/Chromium',
  ];
  for (const p of candidates) {
    if (fs.existsSync(p)) return p;
  }
  console.error([
    'Chrome/Chromium not found. Install it or set CHROME_PATH:',
    '  Linux:   sudo apt install google-chrome-stable',
    '  macOS:   brew install --cask google-chrome',
    '  Or set:  CHROME_PATH=/path/to/chrome node extract-styles.js <url>',
  ].join('\n'));
  process.exit(1);
}

const args = process.argv.slice(2);
const url = args[0];
const selectorArg = args[1] && !args[1].endsWith('.css') ? args[1] : 'body';
const outputArg = args.find(a => a.endsWith('.css'));

if (!url) {
  console.error('Usage: node extract-styles.js <url> [selector] [output.css]');
  console.error('  selector defaults to "body"');
  process.exit(1);
}

function urlToFilename(u, selector) {
  const slug = u.replace(/^https?:\/\//, '').replace(/[^a-z0-9]/gi, '-').replace(/-+/g, '-').replace(/^-|-$/g, '');
  const selSlug = selector.replace(/[^a-z0-9]/gi, '-').replace(/-+/g, '-').replace(/^-|-$/g, '');
  return `${slug}-${selSlug}.css`;
}

const outputPath = outputArg || urlToFilename(url, selectorArg);

(async () => {
  const browser = await puppeteer.launch({
    executablePath: process.env.CHROME_PATH || findChrome(),
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage'],
    headless: true,
  });

  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 1440, height: 900 });
    await page.goto(url, { waitUntil: 'networkidle2', timeout: 30000 });
    await new Promise(r => setTimeout(r, 800));

    const result = await page.evaluate((selector) => {
      // 1. CSS custom properties from all stylesheets
      const customProps = {};
      for (const sheet of document.styleSheets) {
        try {
          for (const rule of sheet.cssRules) {
            if (rule.style) {
              for (const prop of rule.style) {
                if (prop.startsWith('--')) {
                  customProps[prop] = rule.style.getPropertyValue(prop).trim();
                }
              }
            }
          }
        } catch (e) { /* cross-origin stylesheet */ }
      }

      // 2. @font-face rules from all stylesheets
      const fontFaces = [];
      for (const sheet of document.styleSheets) {
        try {
          for (const rule of sheet.cssRules) {
            if (rule.type === 5) { // CSSRule.FONT_FACE_RULE
              fontFaces.push(rule.cssText);
            }
          }
        } catch (e) { /* cross-origin stylesheet */ }
      }

      // 3. Computed styles for the target element
      const el = document.querySelector(selector);
      if (!el) return { error: `Element not found: ${selector}` };

      const computed = window.getComputedStyle(el);
      const computedStyles = {};
      for (const prop of computed) {
        computedStyles[prop] = computed.getPropertyValue(prop).trim();
      }

      return { customProps, fontFaces, computedStyles };
    }, selectorArg);

    if (result.error) {
      console.error('Error:', result.error);
      process.exit(1);
    }

    const lines = [];

    if (result.fontFaces.length > 0) {
      lines.push('/* Font Faces */');
      for (const rule of result.fontFaces) {
        lines.push(rule, '');
      }
    }

    const customEntries = Object.entries(result.customProps);
    if (customEntries.length > 0) {
      lines.push('/* CSS Custom Properties */');
      lines.push(':root {');
      for (const [prop, val] of customEntries.sort()) {
        lines.push(`  ${prop}: ${val};`);
      }
      lines.push('}', '');
    }

    lines.push(`/* Computed styles for: ${selectorArg} */`);
    lines.push(`/* Source: ${url} */`);
    lines.push(`${selectorArg} {`);
    for (const [prop, val] of Object.entries(result.computedStyles)) {
      lines.push(`  ${prop}: ${val};`);
    }
    lines.push('}');

    const css = lines.join('\n');
    fs.writeFileSync(outputPath, css);
    console.log(`Saved: ${path.resolve(outputPath)}`);
    console.log(`  Font faces: ${result.fontFaces.length}`);
    console.log(`  Custom properties: ${Object.keys(result.customProps).length}`);
    console.log(`  Computed styles: ${Object.keys(result.computedStyles).length}`);
  } finally {
    await browser.close();
  }
})().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
