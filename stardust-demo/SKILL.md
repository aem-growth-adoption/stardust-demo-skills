---
name: stardust-demo
description: |
  Use this when the user wants to run a stardust presales demo for a website — uplift a URL
  and automatically open three sprinkles (audit report, brand review, and variants review) 
  populated with the results. Covers the full stardust:uplift pipeline plus auto-generating
  and opening the three demo sprinkles. Use this instead of running stardust:uplift manually
  when the goal is a complete, ready-to-present demo package.
allowed-tools: bash, read_file, write_file, edit_file
---

# stardust-demo

One command. One URL. Three demo sprinkles ready to present.

`stardust-demo` runs `stardust:uplift` on a URL and then automatically generates and opens
three sprinkles in the stardust design system style:

| Sprinkle | Icon | Content |
|---|---|---|
| `<slug>-audit` | triangle-alert | 5 tensions found by the uplift audit |
| `<slug>-brand-review` | palette | Brand review HTML from the extraction |
| `<slug>-variants` | layout-panel-left | 3 variant cards with recommendation |

## Setup

1. Verify `stardust` skill is installed (`skill list | grep stardust`). If not: `upskill adobe/skills --skill stardust`.
2. Verify `impeccable` skill files are at `/workspace/skills/impeccable/`. If not, fetch from `pbakaus/impeccable`.
3. Check `/workspace/stardust/state.json` — if a previous uplift ran for the same URL, ask the user whether to re-run or use existing artifacts.

## Architecture: hybrid scoop + workflow

The demo uses two execution models:

| Component | Model | Why |
|---|---|---|
| **Uplift** | Scoop (cone-orchestrated) | Needs full context, may ask user questions mid-run |
| **Sprinkle generation** | Workflow (parallel fan-out) | Pure template population, no interaction, parallelizable |

The cone orchestrates:
1. Launches the uplift scoop (interactive — can relay questions to user)
2. When uplift completes, launches the workflow to generate all 4 sprinkles in parallel
3. Handles deploy when the user picks a variant

## Procedure

### Step 1 — Run the uplift (scoop, interactive)

Delegate the full `stardust:uplift` pipeline to a scoop:
```
scoop_scoop("<slug>-uplift")
feed_scoop("<slug>-uplift", "<full uplift prompt for URL>")
```

The scoop runs all 6 uplift phases in sequence with full context. If the uplift agent
encounters a stop condition (brand surface too thin, improvements list empty, etc.) it
**surfaces the question to the cone** which relays it to the user. The cone feeds the
user's answer back:
```
feed_scoop("<slug>-uplift", "User answered: <answer>. Continue.")
```

This preserves the monolithic reasoning chain while allowing mid-run interaction.

Outputs when complete:
- `/workspace/stardust/uplift-improvements.md` — 5 tensions
- `/workspace/stardust/current/brand-review.html` — brand review
- `/workspace/stardust/current/_brand-extraction.json` — palette + type
- `/workspace/stardust/prototypes/home-A-proposed.html`
- `/workspace/stardust/prototypes/home-B-proposed.html`
- `/workspace/stardust/prototypes/home-C-cinematic.html`
- `/workspace/stardust/direction.md` — variant directions + recommendation

### Step 2 — Generate sprinkles (workflow, parallel)

Once the uplift scoop completes, launch the workflow:
```bash
workflow run /workspace/stardust-demo-skills/stardust-demo/stardust-demo.workflow.js \
  --args '{"url":"<URL>","slug":"<slug>"}'
```

The workflow handles (in parallel):
- Serving prototypes + taking screenshots
- Generating and opening all 4 sprinkles from templates (pipeline, brand-review, audit, variants)

### Step 3 — Report

When the workflow completes (delivered as a lick), print:
```
demo ready — <URL>

sprinkles open:
  <slug>-pipeline       — live status
  <slug>-audit          — 5 tensions
  <slug>-brand-review   — brand extraction
  <slug>-variants       — 3 variants, B recommended

Next: pick a variant (click Deploy → in the variants sprinkle)
```

## Template system

Templates live in `/workspace/skills/stardust-demo/templates/`:
- `audit.shtml` — audit sprinkle template with `{{TENSIONS}}`, `{{SLUG}}`, `{{URL}}` tokens
- `brand-review.shtml` — brand review template with `{{BRAND_REVIEW_URL}}`, `{{URL}}` tokens
- `variants.shtml` — variants template with `{{VARIANT_A_URL}}`, `{{VARIANT_B_URL}}`, `{{VARIANT_C_URL}}`, `{{SCREENSHOT_A}}`, `{{SCREENSHOT_B}}`, `{{SCREENSHOT_C}}`, `{{FIXES}}`, `{{URL}}` tokens

Read the template, replace the tokens with content from the uplift artifacts, write the populated file.

## Slug derivation

Derive a short slug from the URL hostname + a random 4-character hex ID:
- `https://wknd.site` → `wknd-a3f1`
- `https://www.knack.com` → `knack-9c2e`
- `https://adobe.com` → `adobe-7b04`

Strip `www.`, take the first hostname segment before `.`, lowercase, then append `-` and 4 random hex characters (e.g. `$(openssl rand -hex 2)`).

## Re-run behavior

If `/workspace/stardust/state.json` exists and was written for the same URL:
- Ask: "I have an existing uplift for `<URL>` from `<date>`. Re-run the extraction or use the existing artifacts?"
- If reuse: skip Step 1, go straight to Steps 2–5.
- If re-run: clear `/workspace/stardust/` and start fresh.

## Step 5b — Commit all artifacts to the EDS repo under `deliverables/`

Before deploying, commit all stardust artifacts to the EDS repo so they are accessible
from the preview URL and version-controlled alongside the code.

```
<eds-repo>/deliverables/<slug>/
├── audit.md                  ← uplift-improvements.md (5 tensions)
├── what-if-candidates.md     ← uplift-questions.md
├── direction.md              ← variant directions + rationale
├── PRODUCT.md                ← brand product description (current state)
├── DESIGN.md                 ← brand design description (current state)
├── brand-extraction.json     ← palette, type, motifs, voice
├── brand-review.html         ← full brand review page
├── state.json                ← stardust pipeline state
├── home-A-proposed.html      ← variant A prototype
├── home-B-proposed.html      ← variant B prototype
├── home-C-proposed.html      ← variant C static prototype
├── home-C-cinematic.html     ← variant C cinematic prototype
├── variant-A.png             ← screenshot of variant A
├── variant-B.png             ← screenshot of variant B
└── variant-C.png             ← screenshot of variant C
```

Copy from the stardust workspace:
```bash
mkdir -p <eds-repo>/deliverables/<slug>
cp /workspace/stardust/uplift-improvements.md <eds-repo>/deliverables/<slug>/audit.md
cp /workspace/stardust/uplift-questions.md    <eds-repo>/deliverables/<slug>/what-if-candidates.md
cp /workspace/stardust/direction.md           <eds-repo>/deliverables/<slug>/direction.md
cp /workspace/stardust/current/PRODUCT.md     <eds-repo>/deliverables/<slug>/PRODUCT.md
cp /workspace/stardust/current/DESIGN.md      <eds-repo>/deliverables/<slug>/DESIGN.md
cp /workspace/stardust/current/_brand-extraction.json <eds-repo>/deliverables/<slug>/brand-extraction.json
cp /workspace/stardust/current/brand-review.html      <eds-repo>/deliverables/<slug>/brand-review.html
cp /workspace/stardust/state.json             <eds-repo>/deliverables/<slug>/state.json
cp /workspace/stardust/prototypes/home-A-proposed.html  <eds-repo>/deliverables/<slug>/
cp /workspace/stardust/prototypes/home-B-proposed.html  <eds-repo>/deliverables/<slug>/
cp /workspace/stardust/prototypes/home-C-proposed.html  <eds-repo>/deliverables/<slug>/
cp /workspace/stardust/prototypes/home-C-cinematic.html <eds-repo>/deliverables/<slug>/
cp /shared/<slug>-variant-A.png <eds-repo>/deliverables/<slug>/variant-A.png
cp /shared/<slug>-variant-B.png <eds-repo>/deliverables/<slug>/variant-B.png
cp /shared/<slug>-variant-C.png <eds-repo>/deliverables/<slug>/variant-C.png

cd <eds-repo>
git add deliverables/
git commit -m "Add <slug> stardust deliverables — audit, brand review, 3 prototypes, screenshots"
git push origin <branch>
```

Deliverables are then accessible at:
`https://<branch>--<repo>--<org>.aem.page/deliverables/<slug>/brand-review.html`

## Step 6 — Deploy the chosen variant

Once the user has picked a variant (A, B, or C), invoke `stardust:deploy` to convert the
prototype HTML into a live Edge Delivery Services (AEM) site.

```
stardust:deploy stardust/prototypes/home-<X>-proposed.html
```

`stardust:deploy` owns:
- Converting each prototype `<section>` into an EDS block (`blocks/<name>/<name>.js` + `.css`)
- Authoring EDS content pages under `content/`
- Static header/footer fragments at `fragments/header.html` + `fragments/footer.html`
- Updating `styles/styles.css` with brand tokens
- Self-hosting fonts with metric-matched fallbacks (zero CLS)
- Deploying via DA Source API (`PUT admin.da.live/source/…`) + AEM preview/publish
- Visual + structural diff validation against the original prototype

Trigger phrase for the user: "deploy variant B" or "let's go with B".

## Saving to git

After generating sprinkles, offer to push to the templates repo:
```bash
cp /shared/sprinkles/<slug>-variants/<slug>-variants.shtml /workspace/stardust-sprinkles/sprinkles/<slug>-variants-review.shtml
# repeat for audit and brand-review
cd /workspace/stardust-sprinkles && git add sprinkles/ && git commit -m "Add <slug> demo sprinkles" && git push
```

## Design system

All three sprinkles share the same stardust design token system. The canonical token set:

```css
:root {
  --ink: #0a1024;
  --bg: #f5f0e6;
  --surface: #fffdf8;
  --sunken: #ece4d2;
  --amber: #e8b95e;
  --amber-deep: #c9822d;
  --amber-light: #ffd98a;
  --fg: rgba(26,31,56,0.95);
  --fg-muted: rgba(26,31,56,0.72);
  --fg-dim: rgba(26,31,56,0.52);
  --fg-faint: rgba(26,31,56,0.30);
  --hairline: rgba(26,31,56,0.14);
  --hairline-soft: rgba(26,31,56,0.08);
  --success: #5f9669;
  --danger: #c0453f;
  --display: "SF Pro Display", Inter, system-ui, sans-serif;
  --text: "SF Pro Text", Inter, system-ui, sans-serif;
  --mono: "SF Mono", "JetBrains Mono", ui-monospace, monospace;
  --ease: cubic-bezier(0.16, 1, 0.3, 1);
}
```

Never use S2 tokens in these sprinkles. The stardust design system is self-contained.

## References

- `/workspace/skills/stardust/SKILL.md` — master stardust skill
- `/workspace/skills/stardust/skills/uplift/SKILL.md` — uplift pipeline
- `/workspace/skills/stardust-demo/templates/` — sprinkle templates
- `/workspace/stardust-sprinkles/` — git repo for storing demo sprinkles
- `github.com/QuentinVecchio/stardust-sprinkles` — remote repo
