# Phase 3 - Voiced Interactive Epilogue

## Files

- `scripts/world/ending-epilogue-controller.gd` (new)
- `scripts/world/ending-epilogue-controller.gd.uid` (generated import identity)
- `scripts/world/chase-sequence-controller.gd`
- `scripts/world/gameplay-director.gd`
- `scripts/autoload/game-state.gd`
- `assets/audio/voice-over/voice-over-manifest.json`
- `assets/audio/voice-over/ending_notice_complete-*.ogg` (new)
- `assets/audio/voice-over/ending_roster_complete-*.ogg` (new)
- `assets/audio/voice-over/ending_notice_complete-*.ogg.import` (generated)
- `assets/audio/voice-over/ending_roster_complete-*.ogg.import` (generated)
- `tests/progression-test.gd`
- `tests/checkpoint-layout-test.gd`
- `tests/game-state-test.gd`
- `tests/run-headless-tests.ps1`
- `tests/voice-over-regression.gd`

## Steps

- [x] Enter `ENDING` at the exit, stop danger, and create two spatially separated reveal interactables in the same scene.
- [x] Route prompts/actions to the epilogue controller first while Ending is active, fall back to story routing otherwise, and forward exactly one `credits_shown` signal through the chase controller so pacing keeps its existing contract.
- [x] Gate roster behind notice narration; gate credits behind roster narration; reject duplicates/out-of-order actions.
- [x] Keep movement and look available during investigation, then lock input when credits become visible.
- [x] Author three concise lines per reveal and generate six reviewed Piper/FFmpeg OGG cues through the existing reproducible pipeline.
- [x] Prove the original 70 OGG files remain byte-identical after generation; update every exact cue/group/count contract from 70 to 76.
- [x] Extend manifest/resource/sequence/hold, physical ray/collider, same-scene ownership, lock-state, terminal-race-preservation, and pacing assertions.
- [x] Deep-copy restored checkpoint collections so epilogue completion flags cannot mutate the saved chase snapshot by aliasing.

## Acceptance

- Exit does not show credits or use passive padding.
- Notice must finish before roster can start; roster must finish before credits.
- Both props are distinct gameplay-root descendants with collision and production-ray reachability; no scene transition occurs.
- Gameplay action routing reaches the epilogue only during Ending and preserves normal story behavior before it.
- Six exact-manifest cues add at least 21 seconds of meaningful epilogue hold.
- Player movement remains unlocked before credits and becomes locked after; credits emit once, no checkpoint changes occur, and telemetry still finalizes at visible credits through the existing chase signal.
