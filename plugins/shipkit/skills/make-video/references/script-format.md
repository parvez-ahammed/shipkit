# script.json format

`script.json` fields:

```jsonc
{
  "name": "acme-launch", "size": [1920, 1080], "fps": 30, "target": 60,
  "voice": { "name": "af_heart", "speed": 1.05, "pronounce": { "Acme": "Ack-me" } },
  "music": { "bpm": 112, "chords": ["C", "Am", "F", "G"], "intro": "tension", "dropAt": "scene:reveal+0.3",
             "endAt": "scene:cta+0.3", "layers": { "kick": "scene:features" }, "mix": 0.5 },
  "scenes": [
    { "id": "hook", "lines": [{ "id": "hook", "say": "Still copying data by hand?" }] },
    { "id": "reveal", "min": 2.8, "lead": 0.8, "lines": [{ "id": "meet", "say": "Meet Acme." }] },
    { "id": "features", "weight": 2, "hold": 1.2, "lines": [{ "id": "f1", "say": "...", "caption": "optional different caption text" }] }
  ],
  "sfx": [{ "type": "pop", "at": "word:f1:prices" }, { "type": "typing", "at": "scene:setup+1", "until": "scene:setup+2.4" }]
}
```

- Scene timing: `lead` (before first line, default 0.5), `gap` (between lines, 0.35), `hold` (after last line, 0.8),
  `min` (scenes with no voice, default 3), `weight` (share of spare time up to `target`; give busy visual scenes more).
- Anchors (used by `sfx`, `music`): a number, `scene:id`, `sceneEnd:id`, `line:id`, `lineEnd:id`, `word:lineId:word`, `word:lineId:and#2`, each with an optional `+0.3` / `-0.2`.
- Sound types: `whoosh`, `pop` (`pitch`), `click`, `typing` (`until`), `tick`, `ticks` (`until`, `every`), `chime` (`note`), `success`, `error`, `impact`, `riser` (`len`, peaks at `at`). All take `gain`.
- Music: `intro` is `tension` (drone), `calm` (soft pad) or `none` until `dropAt`; then pads, bass, arpeggio, kick and hats enter (each can start later via `layers`); `endAt` plays a final chord that rings to the end. `"bed": false` means sound effects only. Voices: `af_heart` (warm female, best), `af_bella`, `am_michael`, `am_fenrir`, `bf_emma`, `bm_george`.
