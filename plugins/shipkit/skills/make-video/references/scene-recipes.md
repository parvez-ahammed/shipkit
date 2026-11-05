# Scene recipes and the stage.js API

## Contents
1. Page skeleton
2. stage.js API
3. Recipes: chaos-to-order hook, logo arrival carried into the next scene, data moving between two windows, field mapping,
   form that types itself + cursor click, calendar sweep, dashboard with a failure that gets fixed, benefits as a phrase swap,
   call to action, background motif
4. Layout for any aspect ratio

## 1. Page skeleton

```html
<!doctype html><html><head><meta charset="utf-8">
<link rel="stylesheet" href="brand.css">
<style>/* scene styles: --vm-* colours, calc(var(--u) * N) sizes */</style>
</head><body>
<div id="stage"></div>
<script src="build/timeline.js"></script>   <!-- written by plan.mjs -->
<script src="/engine/lib/stage.js"></script>  <!-- served by render.mjs -->
<script>
const hook = scene("hook");                     // full-frame layer shown during the planned scene
const title = sayLine(hook.root, H * .2, "hook", { highlight: ["hand"] });
onFrame(t => {
  if (!hook.visible(t)) return;                 // skip work while the scene is hidden
  title.update(t);
});
</script></body></html>
```

The scripts go in `<body>` after `#stage`. `stage.js` needs `document.body`.

## 2. stage.js API

| Name | What it does |
|---|---|
| `W`, `H`, `U` | frame width, height, and a size unit (1 at a 1080 px short side). Write sizes as `40 * U`. |
| `TL` | the timeline: `scenes`, `lines` (with `at`, `end`, `words`), `captions`, `sfx`, `duration` |
| `S(id, off)`, `E(id, off)` | scene start and end in seconds |
| `L(id, off)`, `LE(id, off)` | when a voice line starts and stops speaking |
| `Wd(line, word, off)` | estimated time a word is spoken (`"and#2"` gives the second "and") |
| `prog(t, a, b)` | 0 -> 1 as t goes from a to b (clamped) |
| `lerp`, `clamp`, `rand(seed)` | maths. `rand` is repeatable; never use `Math.random()`. |
| `ease.soft` / `ease.exit` / `ease.inOut` / `ease.back` | arriving / leaving / camera moves / overshoot (once per film). `ease.out`, `ease.in` also exist. |
| `el(tag, cls, parent, html)` | create an element (parent defaults to the stage) |
| `at(e, x, y)` | absolute position (also sets `position:absolute`) |
| `place(e, {x, y, s, r, o})` | transform and opacity; also hides the element at o = 0 |
| `pop(e, t, t0, extra)` | arrive at t0: scale from 0.9 plus blur. `{ spring: true }` overshoots instead (once per film). |
| `rise(e, t, t0, dy)` / `slide(e, t, t0, dx)` | arrive moving up / sideways, with blur |
| `blur(e, p, px)` | blur that clears as `p` goes 0 -> 1; pair it with your own `place()` arrivals |
| `drift(t, seed, amp)` | `{x, y}` slow wander to add to anything held longer than about 1 s |
| `typed(text, t, a, b)` | the part of `text` typed so far |
| `countUp(t, a, b, to, from)` | a number counting up |
| `scene(id, {fadeIn, fadeOut, fade})` | layer + `visible(t)`. Cuts hard by default (`fade: 0`); a fade between scenes reads as a slideshow. |
| `headline(parent, y, lines, {size})` | words rise in one by one: `[[["Every", t], ["tool", t2, true]]]` (true = highlight) |
| `sayLine(parent, y, lineId, {text, breakAfter, highlight, size})` | headline timed to the spoken words of a line |
| `column(parent, {x, y, width, eyebrow, title, t0, bullets})` | eyebrow + title + check-mark points -> returns `update(t)`. Reads as a slide: not for proof beats. |
| `cursor(parent)` -> `move(t, [[time, x, y], ...], clickAt)` | mouse pointer that glides between points, with a click ripple |
| `onFrame(fn)` | register a per-frame update |
| CSS classes | `vm-card`, `vm-pill` (`ok`, `fail`, `run`, `info`), `vm-btn`, `vm-eyebrow`, `vm-title`, `vm-bullet`, `vm-hl`, `vm-headline`, `vm-ground` (scene filled with the brand colour) |
| `window.CAPTIONS = false` | turn off burned-in captions (set before stage.js loads) |

Swap content in one frame when a state changes (a status pill Running -> Succeeded): set `className` and `textContent`
from `t`. A fade between two states looks hesitant.

## 3. Recipes

### Chaos-to-order hook
File chips and envelopes around the headline show the pain. In the next scene they collapse into the logo.
```js
const files = [["Report_v7_FINAL.xlsx", "Out of date"], ["Plan_rev2_old.mpp", "Conflict"], ["export (2).csv", "Which one?"]];
const chips = files.map(([name, badge], i) => {
  const c = at(el("div", "vm-card chip", hook.root, `${name}<b class="badge">${badge}</b>`), W * (.12 + .3 * i), H * .62);
  return { c, badge: c.querySelector(".badge"), t: S("hook", .6 + i * .35) };
});
onFrame(t => {
  if (!hook.visible(t)) return;
  const stress = prog(t, E("hook", -2), E("hook", -.5));           // shake more near the end
  chips.forEach((k, i) => {
    pop(k.c, t, k.t, { r: Math.sin(t * 2 + i) * 3, x: stress * 5 * Math.sin(t * 40 + i) });
    pop(k.badge, t, k.t + 1.2);
  });
});
```
Envelopes flying between cards: for each envelope `k` with launch time `t0 = S("hook", 3 + k * .33)` and a pair of cards,
`p = prog(t, t0, t0 + 1)`, `x = lerp(x0, x1, ease.inOut(p))`, `y = yMid - Math.sin(Math.PI * p) * 190 * U`, opacity `Math.min(1, Math.sin(Math.PI * p) * 4)`.

### Logo arrival carried into the next scene
The logo arrives big (1.3-1.6x) and settles, then shrinks into the spot it takes in the next scene (the title bar of the
product window), and that scene's own copy takes over. Never park it in a frame corner for the rest of the film: a
corner logo reads as a TV channel badge. Inline the logo SVG, and wrap the icon's inner parts and the wordmark in `<g>`
groups, so they can move on their own.
```js
const logo = el("div", "vm-abs", stage, LOGO_SVG);   // stage, not the scene root: it must outlive the scene
logo.style.transformOrigin = "0 0";
const home = { x: (W - LOGO_W) / 2, y: H * .36 }, corner = { x: winX + 24 * U, y: winY + 18 * U, s: .2 };   // next scene's title bar
onFrame(t => {
  const pIn = ease.soft(prog(t, S("meet"), S("meet", .6)));
  const pWord = ease.soft(prog(t, S("meet", .3), S("meet", .9)));
  const pCorner = ease.inOut(prog(t, E("meet", -.5), E("meet", .1)));
  const pOut = prog(t, S("full", .1), S("full", .15));             // the window's own logo takes over
  word.style.opacity = pWord;
  word.setAttribute("transform", `translate(${-30 * (1 - pWord)},0)`);
  logo.style.transform = `translate(${lerp(home.x, corner.x, pCorner)}px,${lerp(home.y, corner.y, pCorner)}px) scale(${lerp(lerp(1.5, 1, pIn), corner.s, pCorner)})`;
  logo.style.opacity = clamp(pIn * 3) * (1 - pOut);
});
```
Draw order: the logo is added after the scenes it must sit on top of. Anything appended later covers it.

### Data moving between two windows
Two app windows (`vm-card` with a title bar: logo + name + role pill), each with the same rows. Rows appear in the target window when a small "packet" arrives.
```js
rows.forEach((r, i) => {
  const t0 = L("full", .9) + i * .3;
  const p = prog(t, t0, t0 + .5);
  place(packets[i], { x: lerp(xA, xB, ease.inOut(p)), y: rowY(i), o: p > 0 && p < 1 ? Math.sin(Math.PI * p) * 1.5 : 0 });
  slide(targetRows[i], t, t0 + .45);
});
// Chips like "Prices" jump across on the spoken word, then show "12 prices ✓":
const pm = ease.inOut(prog(t, Wd("full", "prices"), Wd("full", "prices", .7)));
place(chip, { x: lerp(xA, xB, pm), y: y - Math.sin(Math.PI * pm) * 40 * U });
```

### Field mapping (translation)
Three columns: source value -> shared term (filled accent card) -> target value. Per row at `t0`: left card `pop` at t0,
a connector (`div` with `transform: scaleX(p)`, `transform-origin: left`) at t0+.25, middle card at t0+.45, second connector at t0+.65,
right card at t0+.85. Then loop a dot along each connector: `f = ((t - start) / 1.2) % 1`, opacity `Math.sin(Math.PI * f)`.
Give the side cards a coloured left border in each system's colour.

### Form that types itself, and a cursor click
```js
fields.forEach(f => {
  f.val.textContent = typed(f.text, t, f.a, f.b);
  const active = t >= f.a - .1 && t < f.b + .25;
  f.input.style.borderColor = active ? "var(--vm-accent)" : "";
  f.caret.style.opacity = active && Math.floor(t * 4) % 2 === 0 ? 1 : 0;   // blink from t, not a timer
});
moveCursor(t, [[S("agree", 5), W * .8, H * .9], [S("agree", 5.7), btnX, btnY]], S("agree", 5.8));
const pAct = prog(t, S("agree", 6.1), S("agree", 6.4));
place(draftPill, { o: 1 - pAct }); place(activePill, { s: ease.back(pAct), o: clamp(pAct * 2) });
```
Pair it with `{"type": "typing", "at": ..., "until": ...}`, `click` and `success` sounds.

### Calendar sweep (it runs on its own)
A 7x2 grid of day cells. Day `i` is "done" at `t_i = S("auto", .9) + i * .28`: pop a green "06:00 ✓" pill and briefly
outline the cell in accent (`t_i < t < t_i + .5`). Update a counter pill with `done` cells ("14 syncs").
Add a second chip on some days ("Sent back with updates") to show a round trip. Pair with quiet `pop` sounds rising in pitch (`pitch: i % 7`).

### Dashboard with a failure that gets fixed
Stats boxes count up (`countUp`). One row is marked failed: a red inset border and background (`hi = prog(...) * (1 - prog(fixed...))`),
and a reason line appears under it with a "Retry" button. A cursor clicks Retry; the status goes Failed -> Running (spinner rotated by `t * 540` deg) -> Succeeded;
the failed count drops to 0 and the success count rises by 1. This small story shows value better than a static dashboard.

### Benefits as a phrase swap
Not a row of same-size icon tiles (that is the most common generated-video frame). Show one benefit at a time, big
(`90-110 * U`), on the word that says it, replacing the previous one: the old phrase leaves with `ease.exit` in 0.2 s while
the new one arrives with `rise`. Behind it, keep the product card from the last proof beat in view and change the one
detail each benefit is about (an error count dropping to 0, a time stamp updating).

### Call to action
The logo arriving from 1.25x with blur, the closing line via `sayLine` with the key phrase highlighted, and the address as
plain text in the accent colour. No button shape, no "by <company>" line, no row of links. The scene holds 1-1.5 s after
the voice with a slow `drift` on the logo group. Fill it with `.vm-ground` if the scene before it was light.
It is the last scene, so it does not fade out, and its last frame becomes `thumbnail.png`.

### Background motif
A large shape from the brand drifts slowly behind everything: `translate(${Math.sin(t * .25) * 14}px, 0)`. The landing
page's hero art is often the right source. Give it real presence (a filled shape at 10-20% of the ground colour's
strength), not a ghost at 5% opacity, and never faint text. A frame that still looks empty needs a bigger hero, not more
background.

## 4. Layout for any aspect ratio

`const portrait = H > W;` Landscape: a short headline at the top (y about 0.08-0.12 H) and the demonstration as the hero below
it, at least 0.55 W wide, centred or slightly off centre. Not a left text column with a picture on the right: that is a slide.
Portrait: headline on top (y about 0.1 H), demonstration below (y ~ H * .36), full width minus 60U margins. Square: the same
as portrait with fewer rows. Captions sit at 4.5% from the bottom. Keep important things out of the bottom 20% and top 10%
in vertical video: TikTok, Reels and Shorts draw their buttons there.

Vertical (1080x1920) is its own layout, not the landscape or square layout with space above and below. Rules: headline in
the top third, the visual filling the middle, cards at full width with about 60 px side margins, the bottom kept for
captions. On a phone, text a viewer must read is at least 24 px; on landscape at least 16 px (check.mjs fails or warns below
that; labels of 4 letters or fewer, like "XLSX" on a file icon, are not checked). Show 2-3 rows in a table, not 5.
