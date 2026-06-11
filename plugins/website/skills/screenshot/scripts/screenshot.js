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
    // Linux
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium',
    '/usr/bin/chromium-browser',
    // macOS
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
    '  Or set:  CHROME_PATH=/path/to/chrome node screenshot.js <url>',
  ].join('\n'));
  process.exit(1);
}

const [url, outputArg] = process.argv.slice(2);

if (!url) {
  console.error('Usage: node screenshot.js <url> [output.png]');
  process.exit(1);
}

function urlToFilename(u) {
  return u.replace(/^https?:\/\//, '').replace(/[^a-z0-9]/gi, '-').replace(/-+/g, '-').replace(/^-|-$/g, '') + '.png';
}

const outputPath = outputArg || urlToFilename(url);

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
    await page.screenshot({ path: outputPath, fullPage: true });
    console.log(`Saved: ${path.resolve(outputPath)}`);
  } finally {
    await browser.close();
  }
})().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
