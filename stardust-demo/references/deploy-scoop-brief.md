# Deploy scoop brief

Feed this verbatim to `{{SLUG}}-deploy-scoop`. Substitute `{{VARIANT}}` (A|B|C), `{REPO}`, `{org}`, `{repo}`, `{branch}` before feeding.

**Precondition:** cone has already mounted DA at `/mnt/da` (see main SKILL.md Step 6b). Do NOT delegate the mount.

```
## STEP 1 — MANDATORY

Run: read_file /workspace/skills/stardust/skills/deploy/SKILL.md
Then follow those instructions EXACTLY.

## STEP 2 — Load impeccable

Run: read_file /workspace/skills/impeccable/SKILL.md
Use impeccable's craft loop for all HTML/CSS generation — blocks, styles,
and content pages should meet impeccable's quality bar.

## Context

- Prototype to deploy: /shared/stardust/prototypes/home-{{VARIANT}}-proposed.html
  (if variant C: /shared/stardust/prototypes/home-C-cinematic.html)
- EDS repo: /workspace/{REPO}
- Org: {org}
- Repo: {repo}
- Branch: {branch}
- State dir: /shared/stardust-demo/

## DA Content — IMPORTANT

DA is ALREADY MOUNTED at /mnt/da by the cone. Do NOT run `mount` yourself.

To write content to DA:
   cp content/index.html /mnt/da/index.html
   cp content/nav.html /mnt/da/nav.html
   cp content/footer.html /mnt/da/footer.html

To trigger preview (hlx admin accepts the opaque token):
   DA_TOKEN=$(oauth-token adobe)
   curl -X POST -H "Authorization: Bearer $DA_TOKEN" \
     "https://admin.hlx.page/preview/{org}/{repo}/{branch}/index"
   curl -X POST -H "Authorization: Bearer $DA_TOKEN" \
     "https://admin.hlx.page/preview/{org}/{repo}/{branch}/nav"
   curl -X POST -H "Authorization: Bearer $DA_TOKEN" \
     "https://admin.hlx.page/preview/{org}/{repo}/{branch}/footer"

DO NOT use curl against admin.da.live — it will fail with 401.

## Git rules

- NEVER use `git add .` or `git add -A` — only add specific paths
- One commit + one push at the end

## Naming questions

If this is a multi-page deploy, you MUST ask naming questions.
Write them to /shared/stardust-demo/deploy-questions.json:
{"questions": ["question 1", "question 2", ...]}
Then STOP and wait for answers via feed_scoop.

## Output contract

Write to /shared/stardust-demo/deploy-status.json:
{"status":"done","preview_url":"https://{branch}--{repo}--{org}.aem.page/","summary":"...","blocks_created":N,"assets_uploaded":M}
```
