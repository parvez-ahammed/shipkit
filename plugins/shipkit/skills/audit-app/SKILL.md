---
name: audit-app
description: >-
  Runs a QA and UX audit of a whole RUNNING web app before a release and writes two screenshot-backed
  HTML reports (QA release report, product-experience audit). Use for "QA the app", "release
  readiness", "write a QA report", "UX review of the app", "is this ready to ship", "where would users
  hesitate". Both passes run unless scoped ("just QA", "only UX"). Not for one branch or PR (use
  test-branch), an app that cannot run or turning gaps into tickets (use find-ux-gaps), or a planned-change preview (use make-demo).
argument-hint: "[app-url] [qa|ux]"
license: MIT
compatibility: "Needs the web app running and reachable, plus a browser-automation tool that can screenshot and resize the viewport (Playwright MCP, Claude in Chrome or similar). ffprobe is optional, for media checks."
---

# audit-app

Put a **running** product through the fire and report back like a leadership-facing reviewer.

**Safety:** test against a local, dev or staging environment. Before any action with real-world
effects (charging a card, sending email or SMS, deleting or bulk-editing shared data, calling a
paid third-party API), stop and ask. On production, stay read-only unless the user says otherwise.

## Default: run BOTH passes -> TWO reports
By default audit-app runs both passes against the same running app and emits **two** self-contained HTML
reports into `<out>/` (default `.qa-reports/` in the repo root, or a folder the user names; suggest
adding it to `.gitignore`), sharing one `<out>/screenshots/` folder:

1. **QA pass** (engineering / release gate) -> `references/qa-mode.md` -> writes `qa-report.html`.
2. **UX pass** (product experience / design) -> `references/ux-mode.md` -> writes `ux-report.html`.

Run QA first (it boots the app, builds the test-case catalogue, and captures most desktop screenshots),
then UX (it reuses those screenshots and adds the mobile/journey passes). **Cross-link the two** (each
report links to the other in its nav/header), and open both when done. Screenshots are shared, so the UX
pass should reuse QA's captures and only add what it needs (mobile viewport, extra states).

**Scope to one pass only if the user explicitly asks** ("just QA" / "only a UX review") - then produce
that single report. If unsure, do both.

## Universal rules (both modes)
1. **Screenshots are the source of truth.** Capture every screen and every state. If it *feels* wrong
   (spacing, hierarchy, alignment, tone, weight), report it. Never write "works as expected" - describe
   the experience quality.
2. **Evidence or it didn't happen.** UI claims need a screenshot; correctness claims (balances, stored
   records, generated files, APIs) need a real number / status code / probe output (e.g. a DB row,
   a file's size or `ffprobe` result). A `200` or a status card is not proof a
   thing is real - probe the artifact.
3. **Never invent data.** Not observed -> `UNKNOWN` / `NOT RUN`. UNKNOWN is an honest result.
4. **Explore, don't speed-run.** Optimize for "how many moments would make a real user hesitate?",
   not test count. Spend the time on the high-traffic surfaces.
5. **Keep the main session lean.** Fan out independent work (test-case generation from code, API/data
   checks, file/media probes) to background subagents; the main session owns the single shared
   browser (serial). Capture the mobile journey with a viewport resize (e.g. 390x844).
6. **Self-contained HTML report**: dark theme, modern typography, generous spacing, Linear/Notion/Stripe
   feel - sticky side nav, severity color system, collapsible `<details>`, status/test badges, callout
   blocks, a CSS execution timeline, simple CSS charts/heatmaps, structured cards over long prose.
   Reference screenshots relatively from a `screenshots/` folder next to the HTML so they render inline.
   Open the finished report for the user when done.

## Shared workflow
1. Locate/boot the app. Record build: branch, commit SHA (`git rev-parse --short HEAD`), env, versions.
   Mark UNKNOWN if not derivable.
2. Map surfaces (routes, primary flows). QA: generate the test-case catalogue from code first.
3. Drive the browser per the mode's journeys/scenarios; screenshot every state; capture console.
4. Verify correctness out-of-band where it matters (API responses, DB deltas, file probes) via subagents.
5. Assemble the report in the mode's structure. No invented data. Open it.

## Severity (shared)
- **Critical** - blocks a real user or core flow; data/money correctness wrong.
- **High** - a paid feature or acquisition step broken; a screen users would abandon.
- **Medium** - degraded surface, real friction, looks unfinished/inconsistent.
- **Low** - minor polish / environment-only.
- **Info** - observation, cosmetic, config smell.

Release call: any open Critical, or a High with no workaround -> BLOCKED; Highs with workarounds or
open Mediums -> APPROVED WITH RISKS; only Low/Info -> APPROVED.

## Files
Paths are relative to this skill's folder (`${CLAUDE_SKILL_DIR}`). `VERSION` holds the skill version.
- `references/qa-mode.md` - 14-section QA release report spec.
- `references/ux-mode.md` - six-persona / six-journey Product Experience audit spec + output.
- `templates/qa-report-template.html` - QA report skeleton.
- `templates/ux-report-template.html` - UX audit skeleton.
