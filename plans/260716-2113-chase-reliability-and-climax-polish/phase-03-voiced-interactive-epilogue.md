# Phase 3 - Voiced Interactive Epilogue

## Files

- `scripts/world/ending-epilogue-controller.gd` (new)
- `scripts/world/chase-sequence-controller.gd`
- `scripts/world/gameplay-director.gd`
- `assets/audio/voice-over/voice-over-manifest.json`
- `assets/audio/voice-over/ending_notice_complete-*.ogg` (new)
- `assets/audio/voice-over/ending_roster_complete-*.ogg` (new)
- `tests/progression-test.gd`
- `tests/voice-over-regression.gd`

## Steps

- [ ] Enter `ENDING` at the exit, stop danger, and create two spatially separated reveal interactables in the same scene.
- [ ] Gate roster behind notice narration; gate credits behind roster narration; reject duplicates/out-of-order actions.
- [ ] Keep movement and look available during investigation, then lock input when credits become visible.
- [ ] Author three concise lines per reveal and generate six reviewed Piper/FFmpeg OGG cues through the existing reproducible pipeline.
- [ ] Extend manifest/resource/sequence/hold regressions and pacing assertions.

## Acceptance

- Exit does not show credits or use passive padding.
- Notice must finish before roster can start; roster must finish before credits.
- Six exact-manifest cues add at least 21 seconds of meaningful epilogue hold.
- Credits emit once, no checkpoint changes occur, and telemetry still finalizes at visible credits.

