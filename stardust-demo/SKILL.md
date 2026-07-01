---
name: stardust-demo
description: |
  Orchestrate a full stardust presales demo for a website — uplift a URL,
  open 4 sprinkles (pipeline, audit, brand review, variants), and deploy
  the user's chosen variant to EDS. Use inside SLICC with DA token and
  GitHub access pre-configured by the Stardust Lab.
user-invocable: true
---

# stardust-demo

One URL in. Four sprinkles open. A deployed EDS site out.

Orchestrates `stardust:uplift` → deliverables to EDS → sprinkle opening → user variant selection → `stardust:deploy` inside SLICC.

## Prerequisites

- `stardust` skill installed (`upskill adobe/skills --skill stardust`)
- `impeccable` skill installed (`upskill pbakaus/impeccable`)
- DA token available via `oauth-token adobe`
- GitHub access configured by the Stardust Lab
- EDS repo + DA org pre-created by the Stardust Lab

## Model

Do NOT set a `model` on scoops — all scoops inherit the cone's model. This avoids failures when a specific model isn't available in the environment.

## Slug Derivation

Derive from URL hostname + 4 random hex chars:
- `https://wknd.site` → `wknd-a3f1`
- `https://www.knack.com` → `knack-9c2e`

Strip `www.`, take first segment before `.`, lowercase, append `-$(openssl rand -hex 2)`.

## Key Rules for Follower-Facing Demos

- **Never reference `/workspace/` or `sliccy.ai/preview/` in anything a follower sees**
- Use EDS URLs (`https://{branch}--{repo}--{owner}.aem.page/deliverables/...`) for public access
- Always mint fresh sprinkle names per demo (never reuse)
- Commit deliverables to EDS BEFORE opening sprinkles that reference them
- Sprinkles are thin chrome (subheader + iframe or interactive UI) — content lives on EDS

## CRITICAL — Pipeline Sprinkle Updates

The pipeline sprinkle is the user's only window into what's happening. It MUST be updated in real time.

**During uplift:** the uplift scoop itself pushes status updates to the pipeline sprinkle. The cone does NOT need to wake up for this — the scoop handles it directly via `sprinkle send`.

**During deliverables/sprinkles:** the cone pushes status as it builds and commits deliverables.

**During deploy:** the cone pushes `active` before spawning the deploy scoop, and `done` when it completes.

Format: `sprinkle send {{SLUG}}-pipeline '{"step":"<id>","status":"active|done","summary":"...","link":"..."}'`

Step IDs in order: `extract`, `audit`, `brand-review`, `direction`, `prototypes`, `deploy`

## Procedure

### Step 1 — Setup & open pipeline sprinkle

1. Derive slug from the URL
2. Read `/workspace/skills/stardust-demo/templates/pipeline.shtml.tpl`
3. Replace `{{URL}}` and `{{SLUG}}`
4. Write to `/shared/sprinkles/{{SLUG}}-pipeline/{{SLUG}}-pipeline.shtml`
5. Run: `sprinkle open {{SLUG}}-pipeline`
6. Push initial status IMMEDIATELY — the user must see activity from the first second:
   ```
   sprinkle send {{SLUG}}-pipeline '{"step":"extract","status":"active","summary":"Crawling homepage..."}'
   ```

### Step 2 — Run uplift (scoop)

Spawn the uplift scoop:

```
scoop_scoop({
  name: "{{SLUG}}-uplift",
  writablePaths: ["/scoops/{{SLUG}}-uplift/", "/shared/", "/workspace/stardust/"]
})
```

Feed the scoop:

```
## STEP 1 — MANDATORY

Run: read_file /workspace/skills/stardust/skills/uplift/SKILL.md
Then follow those instructions EXACTLY for URL: {{URL}}

## Context

- URL: {{URL}}
- Slug: {{SLUG}}
- State dir: /workspace/stardust/
- Pipeline sprinkle: {{SLUG}}-pipeline

## DA Auth

- Get IMS token: DA_TOKEN=$(oauth-token adobe)

## CRITICAL — Pipeline status updates

You MUST push status updates to the pipeline sprinkle after EVERY phase.
Do NOT batch. Do NOT wait until the end. Push after EACH phase completes.

### After EXTRACT completes:
sprinkle send {{SLUG}}-pipeline '{"step":"extract","status":"done","summary":"Homepage crawled"}'
sprinkle send {{SLUG}}-pipeline '{"step":"audit","status":"active","summary":"Analyzing design tensions..."}'

### After AUDIT completes:
sprinkle send {{SLUG}}-pipeline '{"step":"audit","status":"done","summary":"5 tensions identified"}'
sprinkle send {{SLUG}}-pipeline '{"step":"brand-review","status":"active","summary":"Extracting brand surface..."}'

### After BRAND-REVIEW completes:
sprinkle send {{SLUG}}-pipeline '{"step":"brand-review","status":"done","summary":"Palette + type extracted"}'
sprinkle send {{SLUG}}-pipeline '{"step":"direction","status":"active","summary":"Defining variant directions..."}'

### After DIRECTION completes:
sprinkle send {{SLUG}}-pipeline '{"step":"direction","status":"done","summary":"3 variant directions resolved"}'
sprinkle send {{SLUG}}-pipeline '{"step":"prototypes","status":"active","summary":"Generating 3 HTML prototypes..."}'

### After PROTOTYPES complete:
sprinkle send {{SLUG}}-pipeline '{"step":"prototypes","status":"done","summary":"3 variants ready for review"}'
```

**If uplift asks about existing state** (prior `state.json` for same URL):
- The scoop surfaces the question. The cone relays it to the user.
- Feed the user's answer back: `feed_scoop("{{SLUG}}-uplift", "User answered: <answer>. Continue.")`

**Uplift outputs when complete:**
- `/workspace/stardust/uplift-improvements.md` — 5 tensions
- `/workspace/stardust/current/brand-review.html` — brand review page
- `/workspace/stardust/current/_brand-extraction.json` — palette + type
- `/workspace/stardust/prototypes/home-A-proposed.html`
- `/workspace/stardust/prototypes/home-B-proposed.html`
- `/workspace/stardust/prototypes/home-C-cinematic.html`
- `/workspace/stardust/direction.md` — variant directions + recommendation

### Step 3 — Build deliverables & commit to EDS

Once the uplift scoop completes, the cone builds standalone deliverables and commits them
to the EDS repo. This makes all content publicly accessible for followers via EDS URLs.

**Deliverable structure in the EDS repo:**
```
{repo}/deliverables/
├── audit.html            ← standalone, self-contained audit page
├── brand-review.html     ← standalone brand review page
├── variant-A.html        ← prototype A
├── variant-A.png         ← screenshot of A
├── variant-B.html        ← prototype B
├── variant-B.png         ← screenshot of B
├── variant-C.html        ← prototype C (cinematic)
└── variant-C.png         ← screenshot of C
```

**Steps:**

1. **Build audit.html:**
   - Read `/workspace/stardust/uplift-improvements.md`
   - Parse 5 tensions into JSON array: `[{"category":"...","title":"...","body":"..."},...]`
     Valid categories: `dated-pattern`, `ia-clutter`, `density`, `cliche`, `missed-opportunity`
   - Read `/workspace/skills/stardust-demo/templates/audit.html.tpl`
   - Replace `{{URL}}` and `{{TENSIONS_JSON}}` (data island — paste raw JSON)
   - Write to `{repo}/deliverables/audit.html`

2. **Copy brand-review.html:**
   - `cp /workspace/stardust/current/brand-review.html {repo}/deliverables/brand-review.html`

3. **Copy prototypes:**
   - `cp /workspace/stardust/prototypes/home-A-proposed.html {repo}/deliverables/variant-A.html`
   - `cp /workspace/stardust/prototypes/home-B-proposed.html {repo}/deliverables/variant-B.html`
   - `cp /workspace/stardust/prototypes/home-C-cinematic.html {repo}/deliverables/variant-C.html`

4. **Take screenshots:**
   - Open each prototype in the browser, take full-page screenshots
   - Save to `{repo}/deliverables/variant-A.png`, `variant-B.png`, `variant-C.png`

5. **Commit & push:**
   ```bash
   cd {repo}
   git add deliverables/
   git commit -m "Add stardust deliverables — audit, brand review, 3 prototypes + screenshots"
   git push origin {branch}
   ```

6. **Trigger EDS preview** so URLs are live before sprinkles open:
   ```bash
   DA_TOKEN=$(oauth-token adobe)
   curl -X POST -H "Authorization: Bearer $DA_TOKEN" \
     https://admin.hlx.page/preview/{owner}/{repo}/{branch}/deliverables/audit
   curl -X POST -H "Authorization: Bearer $DA_TOKEN" \
     https://admin.hlx.page/preview/{owner}/{repo}/{branch}/deliverables/brand-review
   # etc for each file
   ```

**EDS base URL:** `https://{branch}--{repo}--{owner}.aem.page/deliverables/`

### Step 4 — Open sprinkles (thin wrappers around EDS)

Now that deliverables are live on EDS, open the 3 remaining sprinkles.

**EDS_BASE** = `https://{branch}--{repo}--{owner}.aem.page/deliverables`

#### 4a. Audit sprinkle (iframe)

1. Read `/workspace/skills/stardust-demo/templates/audit.shtml.tpl`
2. Replace `{{URL}}`, `{{SLUG}}`, `{{AUDIT_URL}}` with `{EDS_BASE}/audit.html`
3. Write to `/shared/sprinkles/{{SLUG}}-audit/{{SLUG}}-audit.shtml`
4. Run: `sprinkle open {{SLUG}}-audit`

#### 4b. Brand review sprinkle (iframe)

1. Read `/workspace/skills/stardust-demo/templates/brand-review.shtml.tpl`
2. Replace `{{URL}}`, `{{BRAND_REVIEW_URL}}` with `{EDS_BASE}/brand-review.html`
3. Write to `/shared/sprinkles/{{SLUG}}-brand-review/{{SLUG}}-brand-review.shtml`
4. Run: `sprinkle open {{SLUG}}-brand-review`

#### 4c. Variants sprinkle (interactive — has deploy button)

1. Read `/workspace/stardust/direction.md` — extract:
   - Per variant: key (A/B/C), title, pitch, what-if question, moves array, role
   - Which variant is recommended
   - Shared fixes across all variants
2. Read `/workspace/skills/stardust-demo/templates/variants.shtml.tpl`
3. Replace `{{URL}}` and `{{SLUG}}`
4. Replace `{{VARIANTS_JSON}}` with a single JSON object in the data island:
   ```json
   {
     "variants": [
       {
         "key": "A",
         "url": "{EDS_BASE}/variant-A.html",
         "screenshot": "{EDS_BASE}/variant-A.png",
         "title": "...",
         "pitch": "...",
         "whatif": "...",
         "moves": ["move 1", "move 2"],
         "role": "..."
       },
       { "key": "B", ... },
       { "key": "C", ... }
     ],
     "fixes": ["fix 1", "fix 2", ...],
     "recommended": "B"
   }
   ```
5. Write to `/shared/sprinkles/{{SLUG}}-variants/{{SLUG}}-variants.shtml`
6. Run: `sprinkle open {{SLUG}}-variants`

### Step 5 — Wait for variant selection (lick)

The variants sprinkle fires a lick when the user clicks "Deploy":
```json
{"action": "select-variant", "variant": "B"}
```

When the cone receives this lick:
1. Confirm with the user: "Deploy variant {{VARIANT}}? This will convert it to an EDS site."
2. If confirmed, proceed to Step 6
3. If the user wants a different variant, wait for another lick

### Step 6 — Deploy (scoop)

1. Push pipeline status FIRST — before spawning the scoop:
   ```
   sprinkle send {{SLUG}}-pipeline '{"step":"deploy","status":"active","summary":"Deploying variant {{VARIANT}} to EDS..."}'
   ```

2. Spawn deploy scoop:
   ```
   scoop_scoop({
     name: "{{SLUG}}-deploy",
     writablePaths: ["/scoops/{{SLUG}}-deploy/", "/shared/", "/workspace/{REPO}/"]
   })
   ```

3. Feed the scoop:
   ```
   ## STEP 1 — MANDATORY

   Run: read_file /workspace/skills/stardust/skills/deploy/SKILL.md
   Then follow those instructions EXACTLY.

   ## Context

   - Prototype to deploy: /workspace/stardust/prototypes/home-{{VARIANT}}-proposed.html
     (if variant C: /workspace/stardust/prototypes/home-C-cinematic.html)
   - EDS repo: /workspace/{REPO}
   - State dir: /shared/stardust-demo/
   - Output contract: write status to /shared/stardust-demo/deploy-status.json

   ## DA Auth

   - Get IMS token: DA_TOKEN=$(oauth-token adobe)
   - Upload content via DA API (PUT admin.da.live/source/...)
   - Trigger preview: POST admin.hlx.page/preview/{owner}/{repo}/{branch}/{page}

   ## Git rules

   - NEVER use `git add .` or `git add -A`
   - One commit + one push at the end

   ## Naming questions

   If this is a multi-page deploy, you MUST ask naming questions.
   Write them to /shared/stardust-demo/deploy-questions.json:
   {"questions": ["question 1", "question 2", ...]}
   Then STOP and wait for answers via feed_scoop.

   ## Output contract

   Write to /shared/stardust-demo/deploy-status.json:
   {"status":"done","preview_url":"https://...","summary":"..."}
   ```

4. **If deploy asks naming questions:**
   - Read `/shared/stardust-demo/deploy-questions.json`
   - Present questions to the user in chat
   - Feed answers back: `feed_scoop("{{SLUG}}-deploy", "Answers: ...")`

5. On completion:
   ```
   sprinkle send {{SLUG}}-pipeline '{"step":"deploy","status":"done","summary":"Live at {{PREVIEW_URL}}","link":"{{PREVIEW_URL}}"}'
   ```

### Step 7 — Report

```
✓ Demo ready — {{URL}}

Sprinkles open:
  {{SLUG}}-pipeline       — live pipeline status
  {{SLUG}}-audit          — 5 tensions found
  {{SLUG}}-brand-review   — brand extraction
  {{SLUG}}-variants       — 3 variants

Deployed: {{PREVIEW_URL}}
```

## Re-run Behavior

If `/workspace/stardust/state.json` exists for the same URL:
- Ask: "I have an existing uplift for `{{URL}}`. Re-run or reuse?"
- If reuse: skip Step 2, go straight to Step 3 (deliverables)
- If re-run: clear `/workspace/stardust/` and start fresh

## Lick Events

| Lick | Source | Cone action |
|------|--------|-------------|
| `{action: "select-variant", variant: "A\|B\|C"}` | variants sprinkle | Confirm with user, spawn deploy |

## Design System

All sprinkles use the stardust token set:

```css
:root {
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
