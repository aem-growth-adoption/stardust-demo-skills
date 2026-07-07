# Canonical screenshot recipe for live EDS URLs

Screenshots MUST come from live EDS URLs — never `file://`, never `/workspace/` paths, never base64 embeds in the sprinkle payload (they blow the ~350KB size limit).

The `shot-eds.jsh` helper in `../scripts/` encapsulates this entire recipe. Prefer it over hand-writing the sequence each time:

```bash
shot-eds "https://{branch}--{repo}--{org}.aem.page/deliverables/variant-A.html" /shared/{{SLUG}}-variant-A.png
```

If for some reason the helper is unavailable, run the recipe manually — exactly in this order, without shortcuts:

1. `playwright-cli open <url>` — parse the `targetId` from stdout.
2. Wait ~4s for the page to settle.
3. For cinematic / scroll-reveal variants, inject `* { opacity: 1 !important; animation: none !important; }` via devtools before capture — elements start at `opacity: 0` and full-page screenshots capture them invisible otherwise.
4. `playwright-cli screenshot --tab <targetId> --fullPage --max-width 1280 <target-path>`.
5. Parse the **actual output path** from stdout (may differ from the requested filename, e.g. `/tmp/screenshot-*.png`) — if it does, `cp` it to your target path.
6. `playwright-cli tab-close`.

## Why each step matters

- **Steps 1 + 6** are paired — leaving tabs open leaks CDP targets across the demo and eventually confuses `playwright-cli`.
- **Step 2** — without a settle wait, fonts and lazy images are missing from the shot.
- **Step 3** is easy to skip because "the page renders fine when I click through" — but full-page screenshots run *before* scroll-triggered reveals fire. Any variant that uses scroll-reveal, `AOS`, or `IntersectionObserver` for entrance animations needs the opacity clamp.
- **Step 5** — `playwright-cli screenshot` normalises the output path in ways that vary by float; trusting the requested filename bites you on cloud floats where `/shared/` writes may be redirected through `/tmp/`.

See also: `/workspace/skills/playwright-cli/SKILL.md` for the underlying tool.
