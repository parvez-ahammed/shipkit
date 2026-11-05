# Design rules for code-made videos

Read before writing `direction.md` (SKILL.md step 5) and again before building scenes. The numbers come
from measured motion-design films and from the design skills that produce the best-looking work. Sizes are
given as a share of the frame's short side (`H` in landscape): at 1080 px, 4% is about 43 px, written `43 * U`.

## 1. Pick a look before you build

A video built straight from the template looks like every other template video. Before any scene:

1. **Name the rut.** Write one line for the video every product in this category ships ("blue-white SaaS,
   centred headline, a row of icon cards, logo with a button at the end"), and one line for its obvious
   opposite. Both are off the table.
2. **List 5 looks from the viewer's world, not from other product videos.** Things the audience knows by heart:
   a shipping label, a train departure board, an invoice, a lab report, a kitchen order ticket. For each, note
   its ground colour, its type, and one mark that makes it recognisable. Pick the one that fits the product's
   real job best, and take one rule from it (a grid, a type habit, a colour) into the brand. Keep the brand's own
   colours and font; the look shapes how they are used.
3. **Pick a colour plan.**
   - *Committed:* one brand colour fills 30-60% of the frame in most scenes.
   - *Drenched:* the turn and the end card are the brand colour edge to edge.
   - *Restrained:* tinted neutrals and one accent. This needs the strongest type and motion to hold up.
   A light grey frame with one blue accent is not "restrained". It is the default this step exists to avoid.
4. **Write `direction.md`** in the project, about 150 words, six short blocks:
   - IDEA: the one thing the viewer should believe, and the rut it refuses.
   - LOOK: ground, colours by role, type, and the one recognisable mark.
   - STORY: the beats (section 2) with what each one proves.
   - FIRST 3 SECONDS: exactly what is on screen at frame 0 and at 1.5 s.
   - MOTION: the one big moment of the film, and the easing family (section 4).
   - END: the last frame, as it will look as the thumbnail.
   If a block reads like a mood ("modern, clean, bold"), it is not decided yet. Rewrite it as things on screen.

The reviewer in step 10 checks the video against this file, so keep it true to what you build.

## 2. Story beats and pacing

- **Frame 0 is already moving**: a card half-arrived, a word half-risen. Never open on a logo or an empty frame.
  The hook is decided in the first 1.5-2 s on TikTok and Reels.
- Each beat **proves** one thing. Write for each: "Buys: the viewer ___". If the sentence needs "and", split the beat.
- A beat lasts 3-7 s. For a longer video add beats; never stretch one.
- Proof (the product doing its job) takes about half the runtime. About one proof every 8-10 s.
- The brand name lands at the turn, around 20-30% in, said once. The end card names it again on screen.
- Beats get shorter towards the strongest moment (at 60-75% of the film), then the last one lingers.
- **Mute test:** cover the captions and the voice. The picture alone must still tell the story.
- Copy that marks a video as generated: "Meet X", "Unlock", "seamless", "the future of", "Not just X. It's Y.",
  three one-word sentences in a row. Write what the product does, in the viewer's words.

## 3. Layout and type

- **One hero per frame**, at most 2 supporting elements. A second element as big as the hero makes the frame shout.
- **The proof is the hero.** A product card or screen fills at least 55% of the frame width. Make it big by
  scaling the whole card (a slow push), not by making its font bigger than the UI would have it.
- Type sizes (share of the short side): headline 7-11% (`80-120 * U`), supporting line 5-7%, a hero number
  20-28%, anything a viewer must read at least 4% (`43 * U`). Below 2% is texture, not text.
- Display weight 500-650, letter spacing -0.02 to -0.04 em. Near-black ink, never pure `#000`.
- Keep text out of the outer 10% of the frame. Vertical: keep the top 10% and bottom 20% clear (app buttons).
- **Change the ground between beats.** The turn and one later beat (about 2/3 in) fill the frame with the brand
  colour (`.vm-ground`); the others sit on the light ground. Never two filled scenes in a row.
- Banned layouts, because they read as a slide deck: small label above a headline; headline on the left with
  points underneath and a picture on the right; a centred headline over a row of same-size icon cards; a small
  card alone in the middle of an empty frame; the same element pinned at the same spot for 3 scenes.

## 4. Motion

`stage.js` has these built in: `ease.soft` (arrivals), `ease.exit` (departures), `ease.inOut` (camera moves),
`ease.back` (overshoot, at most once per film), `blur()`, `drift()`.

| Move | Length | Curve |
|---|---|---|
| Word or small element arriving | 0.4-0.5 s | `ease.soft`, offset about 5% of the frame plus blur |
| Card or panel arriving | 0.45-0.6 s | `ease.soft`, scale 0.92-0.95 to 1 plus blur |
| The one big moment (logo, key result) | 0.6-1.0 s | `ease.soft`, from 1.3-1.6x size down to 1 |
| Leaving | 60-70% of the arrival time | `ease.exit` |
| Camera push on a held card | the whole beat | `ease.inOut`, 1 to 1.04-1.06 |

- Every arrival moves on two channels: offset or scale, plus blur. Opacity alone only for the first 0.15 s.
- **Stagger unevenly**, with gaps of 0.05-0.1 s that shrink (0.1, 0.07, 0.07, 0.06). An even 0.1 s step looks machine-made.
- **Nothing stays frozen for more than about 1 s.** Give a held element `drift()` or a slow scale creep (1 to 1.03).
- A status change swaps in one frame (Syncing to In sync), it does not fade.
- On-screen words land about 0.1 s before the voice says them (`sayLine` does this). Time other events with
  `Wd()` to the word they belong to, not to round numbers.
- Overshoot (`spring: true`, `ease.back`) on at most one element in the whole film.
- Never: fades or white flashes between scenes (`scene()` cuts hard by default), a logo growing from zero,
  a headline typed letter by letter, bounce on every pop, the same 30 px slide on every element.
- **Scene changes:** a hard cut while things move, ideally with one object carried across (the chip that became
  the logo, the row that becomes the next card). Whatever ended the last beat can become the next ground.

## 5. Sound

- At most 1-3 big hits per film (`impact`, `success`), on the frame of a visible event. A sound on every cut is a defect.
- Use 3-5 sound kinds and reuse them. `whoosh` starts 0.1-0.15 s before the cut, not on it.
- Typing and ticks are a quiet texture under a moment, never one sound per letter.
- Leave 0.2-0.3 s of quieter sound just before the biggest hit, so it lands.

## 6. The end

- Logo, one line (the closing voice line), and the address as plain text. No fake button, no "by company" line,
  no footer of links.
- The voice ends, then the frame holds 1-1.5 s with something still moving slowly (`drift`). Need more time?
  Add a proof beat, not logo time.
- The end card is at most 25% of the film.

## 7. Review questions for the contact sheet

Ask these of every frame on `build/contact.png`, and give the reviewer in step 10 the same list:

1. Would this frame pass as a slide in a deck? Then it is a slide, not a film. Make the proof move or fill the frame.
2. What is the one hero here? If you cannot say, two things are fighting.
3. Cover the logo and the product name: could this frame belong to another product? Then it is too generic.
4. Is any text a viewer needs under 4% of the short side?
5. Is any frame mostly empty ground, or is anything frozen for more than a second?
6. Does the ground change at the turn and about 2/3 in?
7. Does the first frame already move, and does the last frame work as a thumbnail?
