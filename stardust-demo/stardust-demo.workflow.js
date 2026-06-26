export const meta = {
  name: 'stardust-demo',
  description: 'Post-uplift workflow: takes existing stardust artifacts and generates + opens all 4 sprinkles in parallel. Run AFTER the uplift scoop completes.'
};

// --- Input (passed by the cone after uplift finishes) ---
const url = args?.url;
const slug = args?.slug;
if (!url || !slug) return 'Error: provide url and slug. Usage: stardust-demo \'{"url":"https://example.com","slug":"example-a3f1"}\'';

log(`Generating sprinkles for ${url} (slug: ${slug})`);

// ===========================================================================
// Serve artifacts first
// ===========================================================================
phase('serve');
log('Serving prototypes and brand review');

const serveResult = await agent(`
Serve the following files using the open command and return their preview URLs:

1. open /workspace/stardust/current/brand-review.html
2. open /workspace/stardust/prototypes/home-A-proposed.html
3. open /workspace/stardust/prototypes/home-B-proposed.html
4. open /workspace/stardust/prototypes/home-C-cinematic.html

Then take screenshots:
1. Run playwright-cli tab-list to find the prototype tabs (the ones with home-A, home-B, home-C in their URL)
2. Wait 3 seconds: sleep 3
3. Screenshot each:
   playwright-cli screenshot --tab <A-id> /shared/${slug}-variant-A.png
   playwright-cli screenshot --tab <B-id> /shared/${slug}-variant-B.png
   playwright-cli screenshot --tab <C-id> /shared/${slug}-variant-C.png
4. Serve screenshots:
   open /shared/${slug}-variant-A.png
   open /shared/${slug}-variant-B.png
   open /shared/${slug}-variant-C.png

Return a JSON object with all the preview URLs.
`, {
  schema: {
    type: 'object',
    properties: {
      brandReview: { type: 'string' },
      variantA: { type: 'string' },
      variantB: { type: 'string' },
      variantC: { type: 'string' },
      screenshotA: { type: 'string' },
      screenshotB: { type: 'string' },
      screenshotC: { type: 'string' }
    },
    required: ['brandReview', 'variantA', 'variantB', 'variantC', 'screenshotA', 'screenshotB', 'screenshotC']
  }
});

const urls = serveResult || {
  brandReview: `https://www.sliccy.ai/preview/workspace/stardust/current/brand-review.html`,
  variantA: `https://www.sliccy.ai/preview/workspace/stardust/prototypes/home-A-proposed.html`,
  variantB: `https://www.sliccy.ai/preview/workspace/stardust/prototypes/home-B-proposed.html`,
  variantC: `https://www.sliccy.ai/preview/workspace/stardust/prototypes/home-C-cinematic.html`,
  screenshotA: `https://www.sliccy.ai/preview/shared/${slug}-variant-A.png`,
  screenshotB: `https://www.sliccy.ai/preview/shared/${slug}-variant-B.png`,
  screenshotC: `https://www.sliccy.ai/preview/shared/${slug}-variant-C.png`
};

// ===========================================================================
// Generate all 4 sprinkles in parallel
// ===========================================================================
phase('sprinkles');
log('Generating 4 sprinkles in parallel');

const results = await parallel([
  // --- Pipeline sprinkle ---
  () => agent(`
Read the template at /workspace/stardust-demo-skills/stardust-demo/templates/pipeline.shtml.tpl.

Generate the pipeline sprinkle:
1. Read the template
2. Replace placeholders:
   - {{URL}} → "${url}"
   - {{SLUG}} → "${slug}"
   - {{BRAND_REVIEW_URL}} → "${urls.brandReview}"
   - {{AUDIT_URL}} → "https://www.sliccy.ai/preview/workspace/stardust/uplift-improvements.md"
   - {{VARIANT_A_URL}} → "${urls.variantA}"
   - {{VARIANT_B_URL}} → "${urls.variantB}"
   - {{VARIANT_C_URL}} → "${urls.variantC}"
   - {{PREVIEW_URL}} → "" (empty — deploy not started)
   - {{ORG}}/{{REPO}}/{{BRANCH}} → "" (empty)
3. Set Extract, Audit, Brand Review, Direction, Prototypes all as "done"
4. Set Deploy and Iterate as "pending"
5. Write to /shared/sprinkles/${slug}-pipeline/${slug}-pipeline.shtml
6. Run: sprinkle open ${slug}-pipeline

Return "done".
`),

  // --- Brand review sprinkle ---
  () => agent(`
Read the template at /workspace/stardust-demo-skills/stardust-demo/templates/brand-review.shtml.tpl.

Generate the brand review sprinkle:
1. Read the template
2. Replace {{URL}} with "${url}", {{SLUG}} with "${slug}", {{BRAND_REVIEW_URL}} with "${urls.brandReview}"
3. Write to /shared/sprinkles/${slug}-brand-review/${slug}-brand-review.shtml
4. Run: sprinkle open ${slug}-brand-review

Return "done".
`),

  // --- Audit sprinkle ---
  () => agent(`
Read the template at /workspace/stardust-demo-skills/stardust-demo/templates/audit.shtml.tpl and the audit data at /workspace/stardust/uplift-improvements.md.

Generate the audit sprinkle:
1. Read the template
2. Replace {{URL}} with "${url}", {{SLUG}} with "${slug}"
3. Populate the 5 tensions from uplift-improvements.md (extract categories, titles, full descriptions)
4. Write to /shared/sprinkles/${slug}-audit/${slug}-audit.shtml
5. Run: sprinkle open ${slug}-audit

Return "done".
`),

  // --- Variants sprinkle ---
  () => agent(`
Read the template at /workspace/stardust-demo-skills/stardust-demo/templates/variants.shtml.tpl, the direction at /workspace/stardust/direction.md, and the audit at /workspace/stardust/uplift-improvements.md.

Generate the variants sprinkle:
1. Read the template
2. Replace:
   - {{URL}} → "${url}"
   - {{SLUG}} → "${slug}"
   - {{SCREENSHOT_A}} → "${urls.screenshotA}"
   - {{SCREENSHOT_B}} → "${urls.screenshotB}"
   - {{SCREENSHOT_C}} → "${urls.screenshotC}"
   - {{VARIANT_A_URL}} → "${urls.variantA}"
   - {{VARIANT_B_URL}} → "${urls.variantB}"
   - {{VARIANT_C_URL}} → "${urls.variantC}"
3. Populate card content from direction.md (variant titles, pitches, what-if, moves, roles)
4. Populate shared fixes from uplift-improvements.md
5. Write to /shared/sprinkles/${slug}-variants/${slug}-variants.shtml
6. Run: sprinkle open ${slug}-variants

Return "done".
`)
]);

// ===========================================================================
// Done
// ===========================================================================
phase('complete');
log(`All 4 sprinkles open for ${url}`);

return {
  url,
  slug,
  sprinkles: [`${slug}-pipeline`, `${slug}-brand-review`, `${slug}-audit`, `${slug}-variants`],
  prototypes: { A: urls.variantA, B: urls.variantB, C: urls.variantC },
  screenshots: { A: urls.screenshotA, B: urls.screenshotB, C: urls.screenshotC },
  brandReview: urls.brandReview,
  nextStep: 'User picks a variant via Deploy button → triggers stardust:deploy'
};
