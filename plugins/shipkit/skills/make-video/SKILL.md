---
name: make-video
description: >-
  Make an animated promo, explainer, launch, tutorial-teaser or social video entirely from code, as
  a ready-to-publish MP4 with voice-over, music, captions and a thumbnail. Use whenever the user
  asks for a video, promo, teaser, ad, reel, short, TikTok, LinkedIn or YouTube clip, or motion
  graphic, and to change or re-render a video made this way. Not for a click-through of the real
  app (use make-demo) or a written guide (use write-user-guide).
license: MIT
compatibility: "Requires Node.js 22+ and npm (engine deps installed once with npm ci; ffmpeg ships via ffmpeg-static), Playwright Chromium, about 1 GB free RAM per render worker, and network access on first run to download Chromium and the ~90 MB Kokoro voice model."
---

# Video maker

You write a small project (a script, a brand file, one HTML page of scenes). The shared engine turns it into a
finished video. Everything is free and local: no stock footage, no licensed music, no cloud service.

Engine: the `engine/` folder next to this SKILL.md, i.e. `${CLAUDE_SKILL_DIR}/engine` (below: `$E`). Paths in commands are examples; quote paths with spaces.

## What the user gets

- `dist/<name>-<W>x<H>.mp4` (H.264 + AAC, -14 LUFS, faststart), `dist/thumbnail.png` (last frame),
  `dist/captions.srt`, `dist/report.json` (measured length, frames, loudness, empty frames, smallest text, words to listen for)
- `claims.md` in the project: every spoken line and on-screen claim with its source
- A storyboard table and an honest list of what they must check before publishing (see step 9)

## One-time setup

Needs Node.js 22+ and npm. If `$E/node_modules` does not exist, install the pinned engine dependencies from the lockfile,
then the browser the renderer drives:

```
cd "$E" && npm ci && npx playwright install chromium
```

On Linux, use `npx playwright install --with-deps chromium` (it installs the system libraries Chromium needs).
ffmpeg comes from the `ffmpeg-static` package; no system ffmpeg is required. The voice model (about 90 MB) downloads
on the first `tts.mjs` run to `~/.cache/make-video/models` and is reused by every project. When the skill is installed
as a plugin, a plugin update can replace the engine folder; if `node_modules` is gone afterwards, run the setup again.

## Workflow

### 1. Learn what the product is, from the source

Read what the product says about itself: README, landing page components and copy, `llms.txt`, marketing
text, docs, the UI. Write down the claims you will use and where each came from. Use real numbers only when
a source states them ("about two hours to set up" from the landing page); never invent a statistic, customer
or quote. If the codebase has two names (an internal code name and a product brand), use the public brand.

Marketing copy does not state the product's rules, so read those in the code: which system can send and which
can receive, which states exist and in what order (Draft, Active, Archived), what a role may do. Any scene that shows
data moving, a sender and a receiver, or a status must respect them. Write these facts and their source lines into the "Product facts" table of `claims.md`
(template in the project), and check every pair and status in `index.html` against them before the render.

Unless the user already said, ask two things before the script: which examples to feature first (the systems, customers or use cases
their buyers know best), and whether the video should show the full range (every integration) or only the main ones.

### 2. Take the brand from the real theme, not from a guess

Find the product's actual design tokens: theme files, CSS variables, a design-system folder, the landing
page's colour constants, the logo SVG, the font. Then work out the *role* of each colour. A colour that exists
in the tokens is not automatically a brand colour. Check where each colour is used (logo, primary button, CTA,
headings, status) before you assign it. Put the values in the project's `brand.css`, with a comment naming the
source file. Copy the logo into `assets/`. If the product has a landing page, match it: it is the public face.
If the brand is really unclear, ask.

### 3. Decide format and length

| Where it will be posted | Size | `script.json` `size` |
|---|---|---|
| YouTube, LinkedIn, website, presentations | landscape 16:9 | `[1920, 1080]` |
| LinkedIn / Instagram / Facebook feed | square | `[1080, 1080]` |
| Reels, Shorts, TikTok, Stories | vertical 9:16 | `[1080, 1920]` |

Use what the user asked for. With no instruction: 20-30 s for a teaser, about 60 s for an explainer, landscape.
For a different aspect ratio, render the page again at the new size (`--size` in `new.mjs`, or edit `size`).
Use `W`, `H`, `U` and `portrait` in the layout. Never letterbox or blur-pad a render from another size: it looks cheap,
and a blurred copy puts ghost headlines at the top and bottom of the frame.

### 4. Write the story and the script

Read `references/storytelling.md` for structures and a worked 60 s example. The short version:
- Hook with the viewer's pain in the first 3 s, then the product, then 3-5 concrete things it does, then proof or benefits, then one call to action.
- One idea per scene. Each scene shows a title, 2-4 short points, and a visual that *demonstrates* the idea (a form filling in, a failed row turning green), not just icons.
- Keep speech to 55-70% of the runtime so viewers can read (about 100 words for 60 s; table in `storytelling.md`).
- Plain words. Short sentences. End users, not developers.
- Words the voice may mispronounce go in `voice.pronounce` (`"Acme": "Ack-me"`). Captions keep the real spelling.
  `tts.mjs` lists names, acronyms and codes without an entry; the user must listen to those.
- The closing line names the product ("Acme. Your data, always in sync."). Prefer a line the landing page already uses.
- After every script change, read the narration that `plan.mjs` prints as one paragraph. A line inserted between two
  that belonged together reads as nonsense ("...through the API. Customers, items and prices.").

### 5. Create the project, voice it, plan it

```
node $E/new.mjs <folder> --name <slug> [--size 1920x1080]
# edit script.json and brand.css, add assets
node $E/tts.mjs <folder>      # voice every line (unchanged lines are skipped on re-runs)
node $E/plan.mjs <folder>     # fits scenes to the voice + "target" length, writes build/timeline.js and captions
```

Put project folders where the user keeps generated work (in a repo, an ignored folder such as `videos/<name>/`).
`plan.mjs` prints each scene's start, end and length and warns when the script is too long for the target: cut words, don't speed up the voice past 1.1.

Before editing `script.json`, read `${CLAUDE_SKILL_DIR}/references/script-format.md`: every field, scene timing, anchors (`scene:id`, `word:lineId:word`), sound types and music layers.

### 6. Build the scenes in `index.html`

The template is a working 4-scene example. Replace its scenes with yours. Read `references/scene-recipes.md` for
proven scene patterns (chaos-to-order hook, logo reveal that moves to a corner, data moving between two app windows,
field mapping, a form that types itself and gets clicked, calendar sweep, dashboard with a failure that gets fixed,
benefit tiles, CTA) and the full `stage.js` API.

The rule that everything depends on: **every visual is a pure function of time**. `onFrame(t => ...)` sets each
element from `t` alone. The renderer seeks frames out of order in 4 browsers at once, so CSS animations,
transitions, timers, `Math.random()` and state carried between frames all produce broken video. Use `rand(seed)` for repeatable randomness.

Time cues come from the plan, never hard-coded seconds: `S("scene", +0.4)`, `E("scene")`, `L("line")`, `LE("line")`,
`Wd("line", "prices")`. When the script changes, everything re-times itself.

Use only `--vm-*` colours from `brand.css` and sizes in `U` units (`40 * U`, `calc(var(--u) * 40)`), so the page
works at any size and re-colours from one file.

Vertical (1080x1920) is its own layout, not landscape or square with space added: see `references/scene-recipes.md` section 4.

No dead air: each scene's first content is on screen before the cut, so no frame between scenes is empty for more than
0.3 s (check.mjs measures it). Hold the end card still for at least 2 s after the voice ends.

### 7. Review stills before the full render

```
node $E/render.mjs <folder> stills --every 3        # or: stills 2.5 9 14.2
```

Open `build/stills/sheet.png` (one labelled image) and look at it. Check a frame in the middle of every scene,
plus the moments just after key cues. Look for: elements stuck at the top-left (missing position), items hidden behind
others (draw order), text overflow or wrapping, empty areas in cards, captions covering content, low contrast,
wrong brand colours, the last frame faded out. The renderer prints page errors and missing files. Fix all of them.
Stills take seconds; a full render takes minutes. Iterate here.

### 8. Render, mix, check

```
node $E/build.mjs <folder> --from music     # music -> render -> text -> mix -> check
WORKERS=2 node $E/build.mjs <folder> --from render   # fewer browser workers when memory is low (bash/zsh)
```

In PowerShell set the variable first: `$env:WORKERS=2; node $E/build.mjs <folder> --from render`.

`build.mjs` with no `--from` also runs tts and plan. After a visual-only change use `--from render`.
A 60 s 1080p video renders in about 7 minutes with 4 workers. The default worker count also looks at free memory
(about 700 MB each). Run long renders in the background.

`check.mjs` fails when any of these is wrong, and lists each problem in `dist/report.json`:
- length, frame count, loudness (-14 +/-1 LUFS), true peak (<= -1 dBFS)
- an almost empty frame for more than 0.3 s (edge detail far below the video's median)
- text smaller than 24 px on a vertical or square video (a warning below 16 px on landscape)
- a spoken line, or an on-screen text of 4 or more words, without a sourced row in `claims.md`
  (shorter on-screen claims, like a 2-word slogan, still need a row; the reviewer checks those)

It also warns about other videos left in `dist/`, and writes `build/contact.png`: the frame at every whole second,
labelled with its exact time. Look at every frame of it before you report success.

### 9. Review with fresh eyes

The person who built the video passes its own defects. Before you deliver, have a reviewer who did not build it
(a fresh subagent, or a separate pass by you) go through `build/contact.png` and `claims.md` with this list:
every claim true and sourced; every sender, receiver and status matches the product facts; the featured examples
are the ones the user asked for; text readable at phone size; vertical layout uses the height; no empty or half-faded
frame; the narration reads well as a paragraph; the end card names the product and holds. Fix what it finds, then
run check.mjs again.

### 10. Deliver

Tell the user, briefly:
- the file paths (video, thumbnail, captions). If the video goes to executives or customers, offer plain names:
  `Acme - Product Overview (60 sec, Widescreen).mp4`, `... (30 sec, Mobile).mp4`. Name each file by its real size:
  a square render must never carry "portrait" in its name.
- which older videos sit next to it (check.mjs warns), so the user removes or moves them before sharing
- a storyboard table: time, scene, what the viewer learns
- the measured numbers from `report.json`
- what they must check, because you cannot:
  - **Listen to the audio.** You cannot hear it, so product names may be mispronounced. Give the `listenFor` list from `report.json`.
  - **Replace invented example data** (project names, numbers, error messages) with real data if needed.
  - **Get approval for third-party logos** and trademarks before paid ads.
  - **Check every claim** against its source.

To change the video later: edit, then re-run from the first step the change affects (text: `build.mjs` from the start; timing or
visuals: `--from render`; sound only: `--from music`).

## When something goes wrong

Read `${CLAUDE_SKILL_DIR}/references/pitfalls.md`. It lists every failure seen so far and its fix.
