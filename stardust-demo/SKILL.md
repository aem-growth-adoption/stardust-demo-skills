---
name: stardust-demo
description: |
  Use this when the user asks to "run a stardust demo", "presales demo for
  <URL>", "uplift and deploy <site>", "demo this site to a customer", or
  otherwise wants the full end-to-end presales flow: uplift a live URL,
  open pipeline / audit / brand-review / variants / complete sprinkles,
  wait for variant selection, and deploy the picked variant to EDS. Runs
  inside SLICC and assumes DA token + GitHub access are pre-provisioned by
  the Stardust Lab. For a single-shot redesign without the sprinkle-driven
  demo choreography, use `stardust:uplift` directly instead.
allowed-tools: bash, read_file, write_file, edit_file
user-invocable: true
---

# stardust-demo

One URL in. Four sprinkles open. A deployed EDS site out.

Orchestrates `stardust:uplift` (split across multiple scoops) → deliverables to EDS → sprinkle opening → user variant selection → `stardust:deploy` inside SLICC.

## Prerequisites

- `stardust` skill installed (`upskill adobe/skills --skill stardust`)
- `stardust:uplift` sub-skill installed (`upskill adobe/skills --skill uplift`)
- `stardust:deploy` sub-skill installed (`upskill adobe/skills --skill deploy`)
- `impeccable` skill installed (`upskill pbakaus/impeccable`)
- DA token available via `oauth-token adobe`
- GitHub access configured by the Stardust Lab
- EDS repo + DA org pre-created by the Stardust Lab

## Bundled resources

- **`scripts/pipeline-step.jsh`** — pushes a pipeline update *and* rewrites the sprinkle `.shtml` data island so late-joining followers see current state. Use this instead of hand-rolling `sprinkle send` + shtml rewrite each step.
- **`scripts/shot-eds.jsh`** — screenshot a live EDS URL with the reveal-clamp injection and stdout-path resolution baked in.
- **`references/uplift-scoop-brief.md`** — the shared brief fed to the two uplift scoops (Phase 1 and Phase 2 scope blocks).
- **`references/deploy-scoop-brief.md`** — the brief fed to the deploy scoop.
- **`references/screenshot-recipe.md`** — the canonical screenshot sequence if `shot-eds.jsh` is unavailable.
- **`templates/*.tpl`** — sprinkle HTML templates with `{{PLACEHOLDER}}` slots.

## Sibling Slicc skills — read these instead of re-teaching

- **`/workspace/skills/delegation/SKILL.md`** — when a scoop is stuck, drop and re-spawn with a better brief; do not feed corrections.
- **`/workspace/skills/sprinkles/SKILL.md`** — sprinkle lifecycle, why fresh names, `.shtml` structure.
- **`/workspace/skills/mount/SKILL.md`** — DA mount semantics; the cone owns the mount call (see Step 6b).
- **`/workspace/skills/playwright-cli/SKILL.md`** — underlying tool for screenshots.

## Model

Do NOT set a `model` on scoops — all scoops inherit the cone's model. This avoids failures when a specific model isn't available in the environment.

## Slug derivation

Derive from URL hostname + 4 random hex chars:
- `https://wknd.site` → `wknd-a3f1`
- `https://www.knack.com` → `knack-9c2e`

Strip `www.`, take first segment before `.`, lowercase, append `-$(openssl rand -hex 2)`.

## Key rules

- **Never reference `/workspace/` or `file://` in anything a follower sees** — use EDS URLs.
- **Cone owns ALL `sprinkle send` calls** — never delegate pipeline updates to scoops. Use `pipeline-step.jsh`.
- **Always mint fresh sprinkle names** per demo — never reuse/overwrite.
- **Commit deliverables to EDS BEFORE opening sprinkles** that reference them.
- **Commit brand-review assets** (logos, screenshots in `assets/`) alongside `brand-review.html` to `deliverables/`.
- **Screenshots via live EDS URLs** — never `file://`, never `/workspace/`.
- **Lick payloads use `{action, data: {}}`** — extra sibling keys get stripped by the bridge.
- **Cherry followers can't open URLs from sprinkles** — cone posts clickable URL in chat instead.

## Pipeline sprinkle updates — how

The cone owns every pipeline update. NEVER delegate `sprinkle send` to a working scoop; scoops are too busy with their main work and will skip or forget updates.

Use the bundled helper — it does both the live push and the `.shtml` data-island rewrite in one call:

```bash
pipeline-step --slug {{SLUG}} --step audit --status done --summary "5 tensions identified"
```

Step IDs, in demo order: `extract`, `audit`, `brand-review`, `direction`, `prototypes`, `deploy`.
Statuses: `pending`, `active`, `done`, `error`.

Why the shtml rewrite matters: `sprinkle send` pushes live to *connected* followers only. Without the data-island rewrite, anyone who joins mid-demo sees all steps as `pending`. The helper handles both.

## Procedure

### Step 1 — Setup & open pipeline sprinkle

1. Derive slug from the URL.
2. Read `/workspace/skills/stardust-demo/templates/pipeline.shtml.tpl`.
3. Replace `{{URL}}` and `{{SLUG}}`.
4. Replace `{{INITIAL_STATE_JSON}}` with:
   ```json
   {"steps":[
     {"id":"extract","status":"active","summary":"Crawling homepage...","link":null},
     {"id":"audit","status":"pending","summary":"Identify design tensions","link":null},
     {"id":"brand-review","status":"pending","summary":"Extract palette, type, motifs","link":null},
     {"id":"direction","status":"pending","summary":"Define 3 variant directions","link":null},
     {"id":"prototypes","status":"pending","summary":"Generate 3 variant prototypes","link":null},
     {"id":"deploy","status":"pending","summary":"Convert to EDS site","link":null}
   ]}
   ```
5. Write to `/shared/sprinkles/{{SLUG}}-pipeline/{{SLUG}}-pipeline.shtml`.
6. Run: `sprinkle open {{SLUG}}-pipeline`.
7. Push the initial live state (matches the baked-in default; keeps followers in sync):
   ```bash
   pipeline-step --slug {{SLUG}} --step extract --status active --summary "Crawling homepage..."
   ```

### Step 2 — Uplift Phase 1: extract + audit + brand review (scoop)

Spawn:

```
scoop_scoop({
  name: "{{SLUG}}-uplift-1-scoop",
  writablePaths: ["/shared/", "/tmp/", "/.playwright/"]
})
```

Feed it the **shared preamble** and the **SCOPE — Phase 1** block from `references/uplift-scoop-brief.md`. Substitute `{{URL}}` and `{{SLUG}}` before feeding.

**When the scoop completes, verify these files exist at `/shared/stardust/`:**
- `uplift-improvements.md`
- `current/brand-review.html`
- `current/assets/`
- `current/_brand-extraction.json`
- `current/PRODUCT.md`, `current/DESIGN.md`, `current/DESIGN.json`

If any file is missing, treat it as a failure (see [Failure & recovery](#failure--recovery)).

**Then the cone runs Tracks A and B IN PARALLEL — do NOT sequence them:**

**Track A — Report sprinkles:**

1. Push pipeline updates:
   ```bash
   pipeline-step --slug {{SLUG}} --step extract --status done --summary "Homepage crawled"
   pipeline-step --slug {{SLUG}} --step audit --status done --summary "5 tensions identified"
   pipeline-step --slug {{SLUG}} --step brand-review --status done --summary "Palette + type extracted"
   ```
2. Commit audit + brand-review deliverables to EDS (so sprinkles can reference them):
   - Build `audit.html` from `templates/audit.html.tpl`.
   - Copy `/shared/stardust/current/brand-review.html` to `{repo}/deliverables/brand-review.html`.
   - Copy the whole `assets/` directory: `cp -r /shared/stardust/current/assets {repo}/deliverables/assets`.
   - `git add deliverables/ && git commit && git push`.
   - Trigger EDS preview for both pages **and** assets (so images resolve).
3. Open audit + brand-review sprinkles:
   - Read `audit.shtml.tpl`, replace `{{URL}}` and `{{AUDIT_URL}}` → write & `sprinkle open`.
   - Read `brand-review.shtml.tpl`, replace `{{URL}}` and `{{BRAND_REVIEW_URL}}` → write & `sprinkle open`.

**Track B — Phase 2 spawn:**

1. `pipeline-step --slug {{SLUG}} --step direction --status active --summary "Defining variant directions..."`
2. Spawn the Phase 2 uplift scoop immediately (Step 3).

Phase 2 only needs `/shared/stardust/` from Phase 1 — it does NOT depend on the EDS commits or sprinkle opens in Track A.

### Step 3 — Uplift Phase 2: direction + prototypes (scoop)

Spawn:

```
scoop_scoop({
  name: "{{SLUG}}-uplift-2-scoop",
  writablePaths: ["/shared/", "/tmp/", "/.playwright/"]
})
```

Feed it the **shared preamble** and the **SCOPE — Phase 2** block from `references/uplift-scoop-brief.md`.

**Verify on completion:**
- `/shared/stardust/prototypes/home-A-proposed.html`
- `/shared/stardust/prototypes/home-B-proposed.html`
- `/shared/stardust/prototypes/home-C-cinematic.html`
- `/shared/stardust/direction.md`

Then push pipeline updates:
```bash
pipeline-step --slug {{SLUG}} --step direction --status done --summary "3 variant directions resolved"
pipeline-step --slug {{SLUG}} --step prototypes --status done --summary "3 variants ready for review"
```

### Step 4 — Commit prototypes, screenshot, open variants sprinkle

`EDS_BASE` = `https://{branch}--{repo}--{owner}.aem.page/deliverables`

#### 4a. Commit prototypes to EDS

> **Static vs content:** deliverables (variant HTML, screenshots) are served from the **code bus** after `git push`. Do NOT call the preview API for them. Only call `admin.hlx.page/preview/...` for **content pages** (`index`, `nav`, `footer`) that live in DA.

```bash
cd {repo}
cp /shared/stardust/prototypes/home-A-proposed.html deliverables/variant-A.html
cp /shared/stardust/prototypes/home-B-proposed.html deliverables/variant-B.html
cp /shared/stardust/prototypes/home-C-cinematic.html deliverables/variant-C.html
git add deliverables/variant-A.html deliverables/variant-B.html deliverables/variant-C.html
git commit -m "Add variant prototypes"
git push origin {branch}
```

Trigger EDS preview:
```bash
DA_TOKEN=$(oauth-token adobe)
for page in variant-A variant-B variant-C; do
  curl -X POST -H "Authorization: Bearer $DA_TOKEN" \
    https://admin.hlx.page/preview/{owner}/{repo}/{branch}/deliverables/$page
done
```

#### 4b. Screenshots from live EDS URLs

Use the bundled helper:

```bash
shot-eds "$EDS_BASE/variant-A.html" /shared/{{SLUG}}-variant-A.png
shot-eds "$EDS_BASE/variant-B.html" /shared/{{SLUG}}-variant-B.png
shot-eds "$EDS_BASE/variant-C.html" /shared/{{SLUG}}-variant-C.png
```

If `shot-eds` is unavailable, fall back to `references/screenshot-recipe.md`.

Commit screenshots to EDS:
```bash
cp /shared/{{SLUG}}-variant-A.png {repo}/deliverables/variant-A.png
cp /shared/{{SLUG}}-variant-B.png {repo}/deliverables/variant-B.png
cp /shared/{{SLUG}}-variant-C.png {repo}/deliverables/variant-C.png
cd {repo}
git add deliverables/variant-A.png deliverables/variant-B.png deliverables/variant-C.png
git commit -m "Add variant screenshots"
git push origin {branch}
```

Trigger preview for the images:
```bash
for page in variant-A.png variant-B.png variant-C.png; do
  curl -X POST -H "Authorization: Bearer $DA_TOKEN" \
    https://admin.hlx.page/preview/{owner}/{repo}/{branch}/deliverables/$page
done
```

#### 4c. Open variants sprinkle

1. Read `/shared/stardust/direction.md` and extract per variant: key (A/B/C), title, pitch, what-if, moves, role; the recommended key; and shared fixes.
2. Read `templates/variants.shtml.tpl`.
3. Replace `{{URL}}` and `{{SLUG}}`.
4. Replace `{{VARIANTS_JSON}}` with (EDS URLs only — NOT base64, NOT `file://`):
   ```json
   {
     "variants": [
       {"key":"A","url":"{EDS_BASE}/variant-A.html","screenshot":"{EDS_BASE}/variant-A.png","title":"...","pitch":"...","whatif":"...","moves":["move 1","move 2"],"role":"..."},
       {"key":"B","...":"..."},
       {"key":"C","...":"..."}
     ],
     "fixes": ["fix 1","fix 2"],
     "recommended": "B"
   }
   ```
5. Write to `/shared/sprinkles/{{SLUG}}-variants/{{SLUG}}-variants.shtml`.
6. `sprinkle open {{SLUG}}-variants`.

### Step 5 — Wait for variant selection (lick)

The variants sprinkle fires:
```json
{"action":"select-variant","data":{"variant":"B"}}
```

Note the payload shape — `data.variant`, not a sibling `variant` key. The bridge strips sibling keys; only `action` and `data` are preserved.

On lick:
1. Confirm with the user: "Deploy variant {{VARIANT}}? This will convert it to an EDS site."
2. If confirmed → Step 6.
3. If the user wants a different variant, wait for another lick.

**Cherry follower limitation:** iframe sandbox blocks navigation from within sprinkles. When the user wants to preview a variant, post the EDS URL as a clickable link in chat.

### Step 6 — Deploy

#### 6a. Push pipeline status

```bash
pipeline-step --slug {{SLUG}} --step deploy --status active --summary "Deploying variant {{VARIANT}} to EDS..."
```

#### 6b. Cone mounts DA (before spawning the scoop)

The cone MUST mount DA itself — do NOT delegate the mount to the scoop.

```bash
mount --source da://{org}/{repo} /mnt/da
```

Verify with `ls /mnt/da` (should list content or be empty, not error). Only proceed once the mount is confirmed. See `/workspace/skills/mount/SKILL.md` for `EACCES` diagnostics.

#### 6c. Spawn deploy scoop

```
scoop_scoop({
  name: "{{SLUG}}-deploy-scoop",
  writablePaths: ["/shared/", "/workspace/{REPO}/", "/mnt/", "/tmp/", "/.playwright/"]
})
```

Feed it the brief from `references/deploy-scoop-brief.md`, with `{{VARIANT}}`, `{REPO}`, `{org}`, `{repo}`, `{branch}` substituted.

**If the deploy asks naming questions:**
- Read `/shared/stardust-demo/deploy-questions.json`.
- Present them to the user in chat.
- Feed answers back: `feed_scoop("{{SLUG}}-deploy", "Answers: ...")`.

#### 6d. On completion

Read `/shared/stardust-demo/deploy-status.json`, then:

```bash
pipeline-step --slug {{SLUG}} --step deploy --status done \
  --summary "Live at {{PREVIEW_URL}}" --link "{{PREVIEW_URL}}"
```

`PREVIEW_URL` = `https://{branch}--{repo}--{org}.aem.page/`.

### Step 7 — Open completion sprinkle

Read `templates/complete.shtml.tpl`, replace `{{SLUG}}` and `{{COMPLETE_JSON}}`:

```json
{
  "liveUrl": "https://{branch}--{repo}--{org}.aem.page/",
  "stats": [
    {"value":"4","label":"blocks created"},
    {"value":"12","label":"assets uploaded"}
  ],
  "nextSteps": [
    {"icon":"✏️","title":"Edit your content","description":"Open Experience Workspace to edit pages, images, and copy","url":"https://da.live/canvas#/{org}/{repo}/index","linkLabel":"open"},
    {"icon":"🚀","title":"Migrate your site","description":"Use Edge Migration Accelerator to bring over more pages","url":"https://ema.aem.live","linkLabel":"open"},
    {"icon":"💬","title":"Reach out to Adobe","description":"Learn more about AEM Edge Delivery Services","url":"mailto:aem-growth@adobe.com","linkLabel":"contact"}
  ]
}
```

Populate `stats` from `deploy-status.json` (`blocks_created`, `assets_uploaded`) or count them from the git commit.

Write to `/shared/sprinkles/{{SLUG}}-complete/{{SLUG}}-complete.shtml` and `sprinkle open {{SLUG}}-complete`.

### Step 8 — Report

```
✓ Demo ready — {{URL}}

Sprinkles open:
  {{SLUG}}-pipeline       — live pipeline status
  {{SLUG}}-audit          — 5 tensions found
  {{SLUG}}-brand-review   — brand extraction
  {{SLUG}}-variants       — 3 variants
  {{SLUG}}-complete       — deploy summary + next steps

Deployed: {{PREVIEW_URL}}
```

## Failure & recovery

Every failure MUST end with an `error` status on the pipeline sprinkle so followers don't see a phase stuck in `active` forever.

| Situation | Cone action |
|---|---|
| Scoop returns but expected `/shared/stardust/…` files are missing | Do NOT feed a correction — drop the scoop and re-spawn with a sharper brief. Per `/workspace/skills/delegation/SKILL.md`: corrections compound the autonomy problem. |
| Scoop hangs or produces nonsense output | `drop_scoop`, then re-spawn. Push `pipeline-step --status error --summary "<reason>"` for the current phase before re-spawning if the retry will take noticeable time. |
| Deploy fails (no `deploy-status.json`, or `status:"error"` inside) | `pipeline-step --slug {{SLUG}} --step deploy --status error --summary "<reason>"`. Surface the error in chat with the last 30 lines of the scoop's log so the user can decide: re-spawn with a fix, or pick a different variant. |
| DA mount fails (`EACCES`) | See `/workspace/skills/mount/SKILL.md`. Do not spawn the deploy scoop until the mount succeeds. |
| Playwright screenshot returns non-zero, or wrong path | `shot-eds.jsh` retries the tab-close and copy step; if it still fails, fall back to `references/screenshot-recipe.md` and inspect stdout — usually a missing `--tab <id>` or a stale target. |
| Demo interrupted mid-pipeline (browser reload, cone restart) | See [Re-run behavior](#re-run-behavior). |

## Re-run behavior

If `/shared/stardust/state.json` exists for the same URL:
- Ask: "I have an existing uplift for `{{URL}}`. Re-run or reuse?"
- If **reuse**: skip Steps 2–3, go straight to Step 4 (prototypes + variants).
- If **re-run**: clear `/shared/stardust/` and start fresh.

Mid-pipeline resume (cone restart with sprinkles still open):
- Read the `.shtml` data island of `{{SLUG}}-pipeline` — the last-persisted step statuses are baked in there.
- Pick up from the first non-`done` step. If the previous step was `active`, it needs re-doing.

## Lick events

| Lick | Source | Cone action |
|------|--------|-------------|
| `{action:"select-variant", data:{variant:"A\|B\|C"}}` | variants sprinkle | Confirm with user, spawn deploy |

## Known limitations

- **Cherry followers can't open URLs from sprinkles** — iframe sandbox. Cone posts URLs in chat.
- **Sprinkle file size limit** — keep under ~350KB total. Use EDS URLs for images, never base64 embeds.
- **Sprinkle overwrite doesn't push to followers** — always mint fresh names.
- **All scoop outputs go to `/shared/stardust/`** — `/shared/` is not sandboxed, so cone and other scoops read outputs without copying. Never use `/workspace/stardust/` for scoop outputs.
