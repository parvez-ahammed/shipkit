---
name: make-demo
description: >-
  Build a pixel-exact, clickable HTML demo of a planned workflow from a DOM and CSS snapshot of the
  running, signed-in app (or a WinForms app's own controls), so it looks exactly like the real
  product. Use for "make an HTML demo", "clickable mockup", "pixel perfect prototype", "show the
  product owner how this workflow will look". Not for free-form design exploration or Figma work (use
  a design tool), or an animated promo (use make-video).
argument-hint: "[ticket-id or story]"
license: MIT
compatibility: "Needs the target web app running locally and signed in, a browser-automation tool that can run page JavaScript (Playwright MCP, Claude in Chrome or similar) and Python 3. Optional desktop adapter is Windows-only and needs the .NET 10 SDK (or the version the desktop app targets)."
---

# make-demo

Build a demo of a new workflow from the app's own rendered components, not from look-alikes. The
main path is web: the live page's DOM and CSS, captured from the running app. An optional adapter
covers Windows desktop apps built with WinForms: the app's own controls, rendered to PNG.
No product code changes.

Work folder: pick one per demo, outside the product source or git-ignored (for example `demos/<ticket>/`;
ask if the project has no convention). Below it is `<work-dir>`. It holds `capture/` (scripts, snapshots,
parts) and `demo/` (the static HTML you hand over).

Prerequisites: Python 3.11+ (`python` on Windows, often `python3` on macOS/Linux), a browser-automation tool
that can evaluate JavaScript in the signed-in page, and the app's dev server running.

The value is the capture technique and its traps. A hand-written mockup that is "close to" the app
drifts in spacing, fonts and colours, and stakeholders then argue about the drift instead of the
workflow.

## When to use / not use

- Use when: a planned change to an existing app must be shown as it will really look, step by step,
  before or while it is built.
- Do not use when: the app does not exist yet or the screen is new from scratch (use a design tool),
  the user wants a UX critique of today's screen (use `audit-app` or `find-ux-gaps`), or an
  animated promo video rather than a clickable demo (use `make-video`).

## Principle: stay as close as possible to the current app

This decides every design question:

1. Extend today's flow. For N items, repeat today's single-item content once per item (sections,
   blocks, rows). Do not design a new layout.
2. Reuse today's texts, components and behaviour. Search the codebase for an existing string first
   (tab labels, shared upload components, wait captions, grid captions, server messages).
3. A text is New only when the app has no text for the case. Aim for a handful. A first demo that
   invents fifty texts gets cut back to four after review - do the cutting before you build.
4. Research findings that need new UI (summary chips, progress lines, extra buttons) go to "Open
   questions" in the demo. They are not added to the demo.

## Workflow (each phase ends at a gate)

1. **Ticket and flow shape.** Read the ticket or story, including acceptance criteria. Ask one
   question at a time. Gate: the user picks the flow shape.
2. **Research.** Run two background agents in parallel:
   - public UX sources (NN/g, GOV.UK, USWDS, Carbon, Fluent, W3C WAI), ending with numbered rules
     and the findings that contradict the chosen direction;
   - repo side: the feature's code, earlier decisions and stakeholder feedback, backend limits,
     reusable components, and what breaks when one item becomes several.

   Present the changed design as a table (change, why) and ask only the product questions the code
   cannot answer. Gate: the user approves the design.
3. **Text register, before any HTML.** Fill `demo/text-register.md` (template below). Show the
   counts per category and every New and Reworded row. Gate: the user accepts the register. Web and
   desktop use one string for one meaning. The build scripts may only write texts from the register.
4. **Capture the web.** See `references/capture.md` > Web capture (read its Gotchas too: fonts, CSS-in-JS, faked writes). Load `scripts/helpers.js` into
   the signed-in tab. Fake every write call the flow can reach (upload, delete, save, submit)
   **before** you click anything. Open every existing state the new flow reuses and snapshot each
   one. Then run `extract.py` and `build.py`.
5. **Compose.** New states use only class names found in the captured parts. `demo.css` holds only
   layout the new sections add (gap, flex), plus the demo step panel. Keep today's unchanged screen
   as its own page.
6. **Desktop (optional adapter, Windows + WinForms only).** Skip unless the change also touches a
   WinForms desktop app. See `references/capture.md` > Desktop capture. `scripts/deskshot` renders
   real WinForms forms off-screen with `PrintWindow` and composites them over a screenshot of the
   running app. Other desktop stacks need their own renderer; the principle (real controls, not
   look-alikes) still holds.
7. **Verify.** Screenshot every step with browser automation, then look at each image. Check:
   - every web font and icon font reports `loaded` (`document.fonts`);
   - no page errors in the console;
   - the unchanged page matches the capture;
   - one full click-through of the main path, with every button in it;
   - the app's API log shows no write calls during capture.
8. **Deliver.** `demo/index.html` holds the step thumbnails, the rules with their sources, the text
   register and the open questions. Open it for the user. List every process you started (API,
   dev server, desktop app, http server).

## Text register template

| # | Text | Where (web, plus desktop if used) | Category | Source or reason |
|---|------|------|----------|------------------|
| 1 | Upload Files | web toolbar | Reworded | Ticket: several files. Was "Upload File" |

Categories:
- **Reused**: today's text, cite `file:line`.
- **Reworded**: today's text changed; the reason must come from the ticket.
- **New**: text that is not in the app today.
- **Sample data**: invented server messages or names. Mark them as sample in the demo too.

A reworded text that the ticket does not require goes back to today's wording.

## Common mistakes

| Mistake | Fix |
|---|---|
| Hand-written CSS "close to" the app | Only captured classes; measure against the capture page |
| Web and desktop wording drift (when both are demoed) | One register row per meaning, both places filled |
| Inventing server messages | Copy real messages from backend code, or list them as Sample data |
| Treating the scripts as finished tools | They are a starting point: state names, faked methods, text replacements and new screens change per demo |
| New wording, chips or progress lines because research suggests them | Reuse the existing text or component; list the idea as an open question |
| Skipping phases because the user is in a hurry | Nothing is skipped. Keep questions short instead, and say which phases remain |
| Patch scripts written in a shell heredoc | Backslashes get lost; write the file with a file-write tool |

## Reference map

All paths below are relative to this skill's folder (`${CLAUDE_SKILL_DIR}`).

- `references/capture.md` - read before phase 4 (web) and phase 6 (desktop): exact steps and Gotchas (font fallback, CSSOM, faked writes, UTF-8, `http.server`). Read the Gotchas before you capture, not after something breaks.
- `scripts/helpers.js` - load into the signed-in page: `__snap`, `__download`, `__blockWrites`,
  `__fakeModule`, `__dropFiles`, `__findByComponent`.
- `scripts/extract.py` - snapshots to `demo/assets/app.css` + `capture/parts/*.body.html`.
- `scripts/build.py` - parts to demo pages; edit `PAGES` and `REPLACEMENTS` per demo.
- `scripts/demo.css` - the demo step panel and a few layout helpers.
- `scripts/deskshot/` - optional Windows adapter: a net10.0-windows tool that renders WinForms forms to
  PNG and composites them. Only needed for phase 6.
