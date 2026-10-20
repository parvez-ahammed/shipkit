---
name: boost-seo
description: >-
  Audits and improves a public website's SEO and AEO (being found and cited by Google, ChatGPT,
  Perplexity), then proves it with local tests. Use for meta tags, JSON-LD / schema.org, robots.txt,
  sitemap.xml, llms.txt, canonical URLs, noindex, prerendering or SSR for crawlers, Lighthouse on a
  public page, share previews, or "does our site follow this SEO article". Works on a live URL or a
  local build of any stack. Not for pricing-page copy (use price-product) or a whole-app QA or
  UX review (use audit-app).
argument-hint: "[url or build-dir]"
license: MIT
compatibility: "Bundled scripts need Node 22+ (no packages). Optional: Playwright (Chromium) for no-JavaScript screenshots and Lighthouse via npx (needs Chrome) for speed cases."
---

# SEO and AEO: audit, fix, prove

The typical failure this skill fixes: a client-rendered single-page app whose public landing page is
invisible to crawlers (an empty `<div id="root">`). The full fix prerenders the page, adds head metadata
and JSON-LD, sets robots and sitemap rules per environment, adds `llms.txt`, returns real 404s, keeps the
landing page fast, and adds a build check that fails when any of this breaks. Server-rendered and static
sites usually need only a subset; the audit tells you which.

Not this skill: keyword research, backlink campaigns or paid search (marketing work, listed but not done
here), and general web performance work on signed-in app pages (only the public pages matter for crawlers).

The work has five phases. Do them in order. Stop after phase 2 if the user only asked "how are we doing".

1. Audit what a crawler gets today
2. Compare with the target list and report the gaps
3. Fix
4. Add a build check so the fixes stay fixed
5. Test locally, then list what can only be tested after deploy

## Phase 1 - Audit what a crawler gets

Crawlers and most answer-engine bots read the **first HTML response**. Many of them do not run JavaScript
(GPTBot, ClaudeBot, PerplexityBot, most social preview bots). Google runs JavaScript later, but slowly and
not always. So the first question is always: what is in the HTML before any script runs?

Run the bundled audit script. It needs Node 22+ and nothing else:

```bash
node "${CLAUDE_SKILL_DIR}/scripts/audit-url.mjs" https://example.com/
node "${CLAUDE_SKILL_DIR}/scripts/audit-url.mjs" http://localhost:4180/ --expect phrases.json
```

It fetches the page as a browser, Googlebot, GPTBot, OAI-SearchBot, PerplexityBot and ClaudeBot and reports:
title, meta description, canonical, robots meta, Open Graph and Twitter tags, JSON-LD types, heading
outline, visible text size, the first answer-length paragraph, `robots.txt` (and which bots it blocks),
`sitemap.xml`, `llms.txt`, and the status code of a URL that must not exist. It flags a different response
per user agent (cloaking risk, or a bot firewall that blocks answer engines).

For a local build of a single-page app, serve it with the bundled server first (see Phase 5).

If the page is behind a login or a bot wall, say so and audit what the public actually gets - that is what
the crawler gets too.

## Phase 2 - Compare and report

Read `references/checklist.md` and mark each item: done, missing, wrong, or not applicable. The checklist
has three parts: crawl and index, page metadata and structured data, and answer-ready content.

If the user pasted an article, map each of its tips to a checklist item and to the file in the repo that
does it (or does not). Separate the tips into: code work, content work (text users see), and marketing or
measurement work (Search Console, keyword tools, snippet tracking) that is not code.

Report as a table: item, status, where (`file:line`), what to change. Put the gaps first, biggest first.
End with a recommendation, not a list of options.

## Phase 3 - Fix

Work in this order. Each step depends on the ones before it.

1. **Content in the first HTML.** If the page is client-rendered, the crawler sees nothing. Options, best
   first: the framework's static generation or SSR (Next.js, Astro, Remix), then a build-time prerender of
   the public pages only, then a prerender service. For a Vite/CRA SPA, read `references/spa-prerender.md`
   - it has the full pattern and the traps that usually cost time.
2. **Head metadata** in the server HTML: unique `<title>` that says what the product does (not just the
   brand), meta description of about 150-160 characters, `<link rel="canonical">` with the absolute URL,
   Open Graph (`og:title`, `og:description`, `og:url`, `og:type`, `og:image` with an absolute https URL)
   and Twitter card tags. Keep `<meta charset>` in the first 1024 bytes.
3. **JSON-LD** (`references/checklist.md` has templates): `Organization` (with `sameAs` links to
   LinkedIn, Wikipedia, Crunchbase and similar, so engines can match the entity), `WebSite`, `WebPage`, and the product
   type (`SoftwareApplication`, `Product`, `LocalBusiness`, `Article`...). Link them with `@id`. Every
   fact in JSON-LD must also be on the visible page.
4. **robots.txt, sitemap.xml, llms.txt.** `robots.txt` allows the public pages and links the sitemap.
   Decide on purpose which AI bots to allow - blocking GPTBot or ClaudeBot keeps the site out of those
   answers. `llms.txt` is a short Markdown summary for language models: a one-line definition, who it is
   for and not for, main features, links.
5. **Index only production.** Test and staging sites must send `noindex` and `Disallow: /`. Make this a
   build or deploy setting (for example `VITE_ALLOW_SEARCH_INDEXING=true` set only in the production env file),
   not a host-name check - proxies and gateways often rewrite the Host header.
6. **Private pages:** app routes behind a login get `noindex`, no canonical, and are not in the sitemap.
7. **Real 404s.** An unknown URL must return status 404, not 200 with the app shell ("soft 404").
   Single-page app hosts that send `index.html` for every path get this wrong by default.
8. **Speed of the public page.** Do not load the whole application on the landing page. Split it so the
   landing page loads only what it needs, and set a byte budget that the build enforces.
9. **Answer-ready content** (AEO). See the "Answer-ready content" part of the checklist: a direct
   40-60 word answer to "What is X?" near the top, question-style headings, short paragraphs, lists and
   tables, a FAQ section with `FAQPage` JSON-LD that matches the visible questions word for word, a line
   that says what the product is NOT when the name is ambiguous.

**Text the user sees is not yours to change.** Metadata, JSON-LD, `llms.txt`, alt text and heading tags
(h2 vs p) are technical. Changing the words on the page, adding a FAQ, or renaming a heading changes the
product copy. Write proposed copy in a notes file and ask the owner before it goes in. Copy changes made
"for SEO" without being asked for tend to get reverted.

## Phase 4 - Build check

Fixes like these break silently: a new import pulls the app back into the landing page, someone edits the
title, a test deploy gets indexed. Add a script that runs after the build and fails it. Read
`references/build-check.md` for the list of checks and a starting script. Wire it into the build (the
`build` script in `package.json` for Node projects, or the equivalent CI build step) so CI runs it.

Make the check able to fail: after writing it, break one thing on purpose (remove the canonical, add a
second h1, flip the indexing flag) and confirm the build fails with a clear message. A check that never
failed has not been tested.

## Phase 5 - Test locally, then after deploy

Read `references/test-plan.md`. It has the case list (initial HTML, no-JavaScript view, metadata, schema
validation, robots and sitemap, 404 status, same response per bot, private routes, speed compared with
the base branch, hydration without duplicate content, deep links) and the recipes for each.

Serve a production build with the bundled server. It copies common host rules: `/` gives `index.html`,
app routes give the app shell, real files are served, anything else gives `404.html` with status 404,
text is gzip-compressed so Lighthouse numbers are close to production, and `/nojs` serves the page with its
scripts removed:

```bash
node "${CLAUDE_SKILL_DIR}/scripts/serve-build.mjs" <build-dir> 4180 --app-routes "^(app|dashboard|settings)(/|$)"
```

Run it in the background and stop it when done. On Windows, `Ctrl+C` in the same shell or
`Stop-Process -Id <pid>` works; find the pid with `Get-NetTCPConnection -LocalPort 4180`. On macOS
and Linux, `kill %1` or `kill $(lsof -t -i :4180)`. The audit prints a stand-in note when it sees this
server or a localhost URL: host-level behaviour from it is not production evidence.

Always compare against the base branch built the same way (`git worktree add` or `git archive` the base
into a folder, build it, serve it on another port). Numbers without a baseline mean nothing to a reviewer.

Some checks need the deployed public site. List them in the report as "not tested locally, and why",
never as passed: real host headers and compression, http to https and www redirects, Core Web Vitals
field data, Google Search Console and Bing Webmaster (submit sitemap, request indexing), Rich Results
Test by URL, and asking ChatGPT or Perplexity about the product (they cannot reach localhost).

## Report

For a review, reply with the phase 2 table. For finished work, produce a test report with one row per
case: case, what was done, result, evidence (file, screenshot, command output). Compare the base branch
with the latest state only - no history of rounds. Put what needs a person (copy approval, production
flag, post-deploy steps) in a separate short list at the end.
