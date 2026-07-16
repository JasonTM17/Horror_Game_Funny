# Phase 3 - Voiced Interactive Epilogue Evidence

## Result

Phase 3 completed in commit `a4a3173e928a6f414eef226f20d25f2472daec68`.

The exit now begins a two-step in-world investigation instead of a passive timer. The player reads the 2007 condemnation notice, waits for its three-line narration, then reads the night roster and hears three final revelations. Credits become visible only after the roster narration completes.

## Runtime Contracts

- `ENDING` becomes terminal before any in-flight failure recovery can resume.
- Both reveal props are direct descendants of the active gameplay scene, use production interaction collision, and are spatially separated.
- Gameplay routes ending prompts/actions to `EndingEpilogueController` first only while its Ending flow is active; normal story routing remains the fallback.
- Notice completion gates the roster; roster completion gates credits; duplicate and out-of-order actions are rejected.
- Movement, camera look, and interaction remain available during investigation.
- `ChaseSequenceController.show_credits()` applies the terminal input lock, creates one visible overlay, and emits one `credits_shown` signal.
- Pacing still finalizes only from the chase controller's visible-credits signal.
- Restored inventory, flags, and completed-event collections are copied before becoming live state, so later epilogue flags cannot mutate the saved chase checkpoint.

## Voice Evidence

| Contract | Result |
|---|---:|
| Manifest cues | 76 |
| Expected narrative groups | 22 |
| Committed OGG files | 76 |
| Committed import sidecars | 76 |
| New ending cues | 6 |
| New ending hold | 30.597 seconds |
| Codec | Vorbis |
| Channels | 1 |
| Sample rate | 22,050 Hz |
| Original tracked OGG files changed | 0 / 70 |

The existing reproducible Piper/FFmpeg pipeline generated the six additions. Because a full regeneration produced different encoder bytes for the existing set, those 70 tracked files were restored from `HEAD`; Git hash comparison then confirmed zero changed originals while the six new files remained.

## Automated QA

- Focused `game-state`: exit 0; `GAME_STATE_TEST_OK`.
- Focused `progression`: exit 0; `PROGRESSION_TEST_OK`.
- Focused `checkpoint-layout` with the updated `--quit-after 2000` safety cap: exit 0; `CHECKPOINT_LAYOUT_TEST_OK`.
- Focused `settings-audio`: exit 0; `SETTINGS_AUDIO_TEST_OK`.
- Isolated headless editor import: exit 0.
- Canonical twelve-check suite: all checks passed in one run.
- Canonical logs present: 12 / 12.
- Canonical scanned failure lines: 0.
- Repository-local temporary Godot profiles after teardown: 0.
- `git diff --check`: pass.
- Secret scan: 0 findings.

The compressed fresh-run telemetry still reports the expected ordered boundaries and an out-of-target verdict. The restored checkpoint run remains ineligible, incomplete, and without a pacing verdict.

## Independent Review

- Runtime reviewer: no blocker, high, or medium findings after inspecting recovery ordering, exactly-once credits, prompt/action gates, input locks, checkpoint isolation, production ray acquisition, pacing, and replay behavior.
- Voice reviewer: no blocker, high, or medium findings; verified 76 cues, 22 groups, exact subtitles, all imports, six valid OGG streams, 30.597 seconds total ending narration, original-file identity, and focused runtime tests.

## Resource Snapshot

- Before voice generation: C: 7.33 GiB free; D: 23.95 GiB free.
- After implementation and QA: C: approximately 7.25 GiB free; D: 23.95 GiB free.
- No local Piper runtime, model, build cache, Godot profile, or generated evidence log is committed.

## Remaining Release Gates

- Physical F5 boot-to-credits traversal with keyboard and mouse.
- Same-run eligible, complete, ordered 900-1200 second telemetry payload.
- Human review of audible performance and mix balance, including all six ending lines.
- Player-driven chase fairness and rendered epilogue readability.
- Target-hardware Settings workflow and comfort checks.
- Real gameplay screenshots and an optimized GIF embedded and render-checked in the final game documentation.

## Unresolved Questions

None for Phase 3. Parent release evidence remains intentionally open.
