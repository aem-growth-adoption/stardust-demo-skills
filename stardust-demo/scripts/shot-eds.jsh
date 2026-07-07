// shot-eds — capture a live-EDS-URL full-page screenshot at a stable width,
// with the scroll-reveal opacity clamp applied for cinematic variants, and
// resolve the actual output path (which may differ from the requested path
// across floats).
//
// Usage:
//   shot-eds <url> <out.png> [--wait 4000] [--width 1280] [--no-reveal-clamp]
//
// Behavior:
//   1. `playwright-cli open <url>` and parse the target id from stdout
//   2. Wait --wait ms (default 4000) for fonts / images to settle
//   3. Unless --no-reveal-clamp: inject a CSS rule setting opacity:1 and
//      animation:none on every element (so scroll-reveal variants aren't
//      captured mid-transition or fully invisible)
//   4. `playwright-cli screenshot --tab <target> --fullPage --max-width <width> <out>`
//   5. If stdout reports an output path that differs from <out.png>, cp it over
//   6. Close the tab

const fs = require('fs');
const { exec } = require('sliccy:exec');
const cli = require('sliccy:cli');

const { positional, flags } = process.argv.parseFlags();
const [url, outPath] = positional;

if (!url || !outPath) {
  cli.help('Usage: shot-eds <url> <out.png> [--wait 4000] [--width 1280] [--no-reveal-clamp]');
  process.exit(1);
}

const waitMs = Number(flags.wait ?? 4000);
const width = Number(flags.width ?? 1280);
const clampReveal = flags['no-reveal-clamp'] !== true;

async function run(argv) {
  const res = await exec.spawn(argv);
  if (res.exitCode !== 0) {
    cli.die(`${argv[0]} failed (exit ${res.exitCode}): ${res.stderr || res.stdout}`, {
      prefix: 'shot-eds',
    });
  }
  return res;
}

// 1) Open the URL.
const openRes = await run(['playwright-cli', 'open', url]);
const targetMatch = (openRes.stdout + '\n' + openRes.stderr).match(
  /(?:target(?:\s*id)?|tab)[^A-Z0-9]*([A-F0-9]{16,}|[a-f0-9-]{20,})/i
);
const targetId = targetMatch ? targetMatch[1] : null;

// 2) Settle.
await new Promise((r) => setTimeout(r, waitMs));

// 3) Reveal clamp for scroll-triggered animations.
if (clampReveal) {
  const css = '* { opacity: 1 !important; animation: none !important; transition: none !important; }';
  const evalScript =
    "(() => { var s = document.createElement('style'); s.textContent = " +
    JSON.stringify(css) +
    "; document.head.appendChild(s); return 'ok'; })()";
  const evalArgs = ['playwright-cli', 'eval'];
  if (targetId) evalArgs.push('--tab', targetId);
  evalArgs.push(evalScript);
  const evalRes = await exec.spawn(evalArgs);
  if (evalRes.exitCode !== 0) {
    console.warn(`[shot-eds] reveal-clamp inject failed (continuing): ${evalRes.stderr.trim()}`);
  }
  // Give the paint a beat.
  await new Promise((r) => setTimeout(r, 250));
}

// 4) Screenshot.
const shotArgs = ['playwright-cli', 'screenshot'];
if (targetId) shotArgs.push('--tab', targetId);
shotArgs.push('--fullPage', '--max-width', String(width), outPath);
const shotRes = await run(shotArgs);

// 5) Resolve actual output path. `playwright-cli screenshot` may report a
// different path than requested (e.g. `/tmp/screenshot-*.png`) on cloud floats.
const stdout = shotRes.stdout + '\n' + shotRes.stderr;
const pathMatch = stdout.match(/(?:saved(?:\s+to)?|wrote|output|path)[:\s]+([^\s'"]+\.png)/i);
let actualPath = pathMatch ? pathMatch[1] : null;

const outExists = await fs.exists(outPath);
if (!outExists && actualPath && actualPath !== outPath && (await fs.exists(actualPath))) {
  console.warn(`[shot-eds] playwright reported ${actualPath}, expected ${outPath} — copying`);
  const buf = await fs.readFileBinary(actualPath);
  await fs.writeFileBinary(outPath, buf);
} else if (!outExists) {
  cli.die(`screenshot did not produce ${outPath} (stdout: ${stdout.trim().slice(-200)})`, {
    prefix: 'shot-eds',
  });
}

// 6) Close the tab.
const closeArgs = ['playwright-cli', 'tab-close'];
if (targetId) closeArgs.push('--tab', targetId);
const closeRes = await exec.spawn(closeArgs);
if (closeRes.exitCode !== 0) {
  console.warn(`[shot-eds] tab-close failed (leaking target ${targetId ?? '?'}): ${closeRes.stderr.trim()}`);
}

console.log(`[shot-eds] ${url} → ${outPath}`);
