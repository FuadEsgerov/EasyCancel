#!/usr/bin/env node
// Composes branded, captioned App Store marketing screenshots from the raw
// device captures in Screenshots/AppStore-*. Renders with headless Chrome so the
// output PNGs are exactly the App Store pixel dimensions. Re-run after editing a
// caption: `node scripts/marketing/generate-screenshots.mjs`.

import { readFileSync, writeFileSync, mkdirSync, existsSync, rmSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(fileURLToPath(import.meta.url), '../../..');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

const captions = {
  '01-home':     'Track every subscription and what you really spend',
  '02-detail':   'Never miss the 14-day cooling-off deadline',
  '03-letter':   'Generate a GDPR cancellation letter in one tap',
  '04-settings': 'Your data, your control — export or delete anytime',
  '05-paywall':  'Go Pro: unlimited tracking and Family Sharing',
};

const sizes = [
  { name: '6.9', w: 1320, h: 2868, src: 'Screenshots/AppStore-6.9' },
  { name: '6.5', w: 1242, h: 2688, src: 'Screenshots/AppStore-6.5' },
];

function slideHTML(w, h, caption, dataUri) {
  const cap  = Math.round(w * 0.066);
  const top  = Math.round(h * 0.05);
  const side = Math.round(w * 0.07);
  const ph   = Math.round(h * 0.70);
  const rad  = Math.round(w * 0.055);
  const pad  = Math.round(h * 0.03);
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  html,body{margin:0;padding:0}
  .slide{width:${w}px;height:${h}px;box-sizing:border-box;display:flex;flex-direction:column;
    align-items:center;overflow:hidden;
    background:linear-gradient(160deg,#48cf90 0%,#2f9e6b 55%,#1c7a52 100%);
    font-family:-apple-system,BlinkMacSystemFont,"SF Pro Display","Segoe UI",Roboto,Arial,sans-serif}
  .caption{color:#fff;font-weight:800;text-align:center;font-size:${cap}px;line-height:1.12;
    letter-spacing:-.02em;margin:${top}px auto 0;padding:0 ${side}px;max-width:92%;
    text-shadow:0 2px 24px rgba(0,0,0,.14)}
  .wrap{flex:1;display:flex;align-items:flex-end;justify-content:center;width:100%;padding-bottom:${pad}px}
  img.phone{height:${ph}px;border-radius:${rad}px;box-shadow:0 28px 70px rgba(0,0,0,.38);
    outline:1px solid rgba(255,255,255,.10)}
  </style></head><body><div class="slide">
  <div class="caption">${caption}</div>
  <div class="wrap"><img class="phone" src="${dataUri}"></div>
  </div></body></html>`;
}

let rendered = 0;
for (const s of sizes) {
  const outDir = join(ROOT, `Screenshots/Marketing-${s.name}`);
  mkdirSync(outDir, { recursive: true });
  for (const [file, caption] of Object.entries(captions)) {
    const imgPath = join(ROOT, s.src, `${file}.png`);
    if (!existsSync(imgPath)) { console.warn('skip (missing):', imgPath); continue; }
    const dataUri = `data:image/png;base64,${readFileSync(imgPath).toString('base64')}`;
    const htmlPath = join(outDir, `.${file}.tmp.html`);
    const out = join(outDir, `${file}.png`);
    writeFileSync(htmlPath, slideHTML(s.w, s.h, caption, dataUri));
    execFileSync(CHROME, [
      '--headless=new', '--disable-gpu', '--hide-scrollbars', '--no-sandbox',
      '--force-device-scale-factor=1', `--window-size=${s.w},${s.h}`,
      '--virtual-time-budget=4000', `--screenshot=${out}`, `file://${htmlPath}`,
    ], { stdio: 'pipe' });
    rmSync(htmlPath, { force: true });
    console.log('rendered', out.replace(ROOT + '/', ''));
    rendered++;
  }
}
console.log(`\nDone — ${rendered} marketing screenshots.`);
