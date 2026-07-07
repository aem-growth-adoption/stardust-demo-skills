# Uplift scoop brief (Phase 1 & Phase 2)

Two scoops share this brief — the shared preamble is identical, only the scope block differs. Feed the appropriate `## SCOPE — Phase N` section verbatim after the shared preamble.

Substitute `{{URL}}` and `{{SLUG}}` before feeding.

## Shared preamble (both phases)

```
## STEP 1 — MANDATORY

Run: read_file /workspace/skills/stardust/skills/uplift/SKILL.md
Then follow those instructions for URL: {{URL}}

## STEP 2 — Load impeccable

Run: read_file /workspace/skills/impeccable/SKILL.md
The uplift skill uses impeccable for design quality. You MUST follow
impeccable's craft loop when generating or evaluating design work.
If the uplift skill invokes impeccable, follow those instructions.

## Context

- URL: {{URL}}
- Slug: {{SLUG}}
- State dir: /shared/stardust/

## DA Auth

- Get IMS token: DA_TOKEN=$(oauth-token adobe)
```

## SCOPE — Phase 1 (extract + audit + brand-review)

Append to the shared preamble when spawning `{{SLUG}}-uplift-1-scoop`:

```
## IMPORTANT — SCOPE LIMIT

You are responsible for the FIRST 3 PHASES ONLY:
1. Extract (crawl + capture)
2. Audit (identify design tensions)
3. Brand Review (extract palette, type, motifs)

STOP after brand-review completes. Do NOT proceed to direction or prototypes.
Write a completion marker when done:
  echo '{"phase":"brand-review","status":"done"}' > /shared/stardust-demo/uplift-1-done.json
```

**Expected outputs at `/shared/stardust/` on completion:**
- `uplift-improvements.md`
- `current/brand-review.html`
- `current/assets/` (logos, screenshots referenced by brand-review.html)
- `current/_brand-extraction.json`
- `current/PRODUCT.md`, `current/DESIGN.md`, `current/DESIGN.json`

## SCOPE — Phase 2 (direction + prototypes)

Append to the shared preamble when spawning `{{SLUG}}-uplift-2-scoop`:

```
## IMPORTANT — SCOPE LIMIT

The first 3 phases (extract, audit, brand-review) are ALREADY DONE.
Their outputs are in /shared/stardust/. Do NOT re-run them.

You are responsible for the LAST 2 PHASES ONLY:
4. Direction (define 3 variant directions from the audit + brand review)
5. Prototypes (generate 3 HTML variant prototypes)

Prior outputs already available:
  - /shared/stardust/uplift-improvements.md (5 tensions)
  - /shared/stardust/current/brand-review.html
  - /shared/stardust/current/_brand-extraction.json
  - /shared/stardust/current/PRODUCT.md
  - /shared/stardust/current/DESIGN.md
  - /shared/stardust/current/DESIGN.json

Write a completion marker when done:
  echo '{"phase":"prototypes","status":"done"}' > /shared/stardust-demo/uplift-2-done.json
```

**Expected outputs at `/shared/stardust/` on completion:**
- `prototypes/home-A-proposed.html`
- `prototypes/home-B-proposed.html`
- `prototypes/home-C-cinematic.html`
- `direction.md`
