// pipeline-step — push a stardust pipeline update AND persist it into the
// sprinkle's .shtml data island so late joiners see current state.
//
// Without the .shtml rewrite, followers who join mid-demo see all steps as
// "pending" — sprinkle send only pushes live to currently-connected clients.
//
// Usage:
//   pipeline-step --slug wknd-a3f1 --step audit --status active
//                 [--summary "..."] [--link "https://..."]
//
// Step IDs (in demo order):
//   extract, audit, brand-review, direction, prototypes, deploy
// Statuses: pending | active | done | error

const fs = require('fs');
const { exec } = require('sliccy:exec');
const cli = require('sliccy:cli');

const { flags } = process.argv.parseFlags();

const slug = flags.slug;
const step = flags.step;
const status = flags.status;
const summary = flags.summary ?? null;
const link = flags.link ?? null;

if (!slug) cli.die('--slug is required', { prefix: 'pipeline-step' });
if (!step) cli.die('--step is required', { prefix: 'pipeline-step' });
if (!status) cli.die('--status is required', { prefix: 'pipeline-step' });

const VALID_STEPS = ['extract', 'audit', 'brand-review', 'direction', 'prototypes', 'deploy'];
const VALID_STATUSES = ['pending', 'active', 'done', 'error'];
if (!VALID_STEPS.includes(step)) {
  cli.die(`invalid --step "${step}" (expected: ${VALID_STEPS.join(', ')})`, { prefix: 'pipeline-step' });
}
if (!VALID_STATUSES.includes(status)) {
  cli.die(`invalid --status "${status}" (expected: ${VALID_STATUSES.join(', ')})`, { prefix: 'pipeline-step' });
}

const shtmlPath = `/shared/sprinkles/${slug}-pipeline/${slug}-pipeline.shtml`;

// 1) Push the live update to connected followers.
const payload = { step, status };
if (summary !== null) payload.summary = summary;
if (link !== null) payload.link = link;

const sendRes = await exec.spawn(['sprinkle', 'send', `${slug}-pipeline`, JSON.stringify(payload)]);
if (sendRes.exitCode !== 0) {
  cli.die(`sprinkle send failed: ${sendRes.stderr || sendRes.stdout}`, { prefix: 'pipeline-step' });
}

// 2) Rewrite the .shtml data island so joiners get current state.
if (!(await fs.exists(shtmlPath))) {
  console.warn(`[pipeline-step] warning: ${shtmlPath} not found — live push succeeded but state not persisted`);
  process.exit(0);
}

const shtml = await fs.readFile(shtmlPath);
const ISLAND_RE = /(<script id="initial-state" type="application\/json">)([\s\S]*?)(<\/script>)/;
const m = shtml.match(ISLAND_RE);
if (!m) {
  console.warn(`[pipeline-step] warning: no <script id="initial-state"> data island in ${shtmlPath}`);
  process.exit(0);
}

let state;
try {
  state = JSON.parse(m[2].trim());
} catch {
  // Fresh sprinkle before the cone baked initial state — start from defaults.
  state = { steps: VALID_STEPS.map((id) => ({ id, status: 'pending', summary: null, link: null })) };
}

if (!Array.isArray(state.steps)) state.steps = [];
let target = state.steps.find((s) => s.id === step);
if (!target) {
  target = { id: step, status: 'pending', summary: null, link: null };
  state.steps.push(target);
}
target.status = status;
if (summary !== null) target.summary = summary;
if (link !== null) target.link = link;

const nextIsland = `${m[1]}\n${JSON.stringify(state, null, 2)}\n${m[3]}`;
await fs.writeFile(shtmlPath, shtml.replace(ISLAND_RE, nextIsland));

console.log(`[pipeline-step] ${slug} ${step} → ${status}`);
