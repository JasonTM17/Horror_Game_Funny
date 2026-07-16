# Phase 04 Pacing Audit — 2026-07-16

## Scope

This is a source-level lower-bound audit for the single continuous `gameplay.tscn` route. It is not a substitute for a physical blind F5 run. The release gate remains a same-run keyboard/mouse capture paired with `PLAYTHROUGH_PACING`.

## Authored route evidence

The route uses one continuous corridor and deliberately revisits the memory start during the first two blackouts:

- Lobby start (`z=28`) → lobby gate (`z=0`) → maintenance notice (`z=-8`).
- Fuse box (`z=-20`) → spare fuse (`z=-80`) → return to fuse box → powered door (`z=-105`).
- Three memory passes with two hidden loop returns: photo (`z=-170`), cassette (`z=-220`), rabbit (`z=-270`), each followed by the changed-hallway echo/gate (`z≈-295`).
- Radio (`z=-325`) → Room 407 recording/drawing/three physical observations (`z=-385` to `-462`) → final clue (`z=-475`).
- Chase exit (`z=-800`) and the two-step ending epilogue.

The minimum forward/backtrack distance for this authored order is approximately **1,390 metres** (about 1.4 km). This estimate includes the two memory resets and the fuse-box return; it excludes optional drawer/false-door inspection, wrong radio attempts, camera/look-around time, collision correction, pauses, and chase recovery.

## Voice timing evidence

The 19 mandatory narrative/observation groups on the critical path contain 76 manifest-backed cues. Using the imported OGG durations and `VoiceOverPlayer.line_wait_seconds(base, 1.0, duration)`, the summed mandatory wait is **293.53 seconds** (4m 53.5s). This includes the new six-cue epilogue and its ~30.6 seconds of spoken material.

At the authored player walk speed (`2.6 m/s`), the route lower bound is approximately:

```text
1,390 m / 2.6 m/s + 293.53 s = 828.15 s ≈ 13m 48s
```

That is intentionally below the 15-minute release floor because the calculation removes all human interaction overhead. A blind player must stop to read/aim/interact, solve the radio, watch blackout transitions, orient after loop returns, and react to the chase. Those behaviors are expected to supply the remaining time without adding empty waits. Continuous sprinting is not a target play style and produces a shorter theoretical result.

## Validation decision

- **Accepted:** authored pacing has enough meaningful spatial traversal and voiced beats to plausibly land in the 15–20 minute target during a blind first run.
- **Not accepted as release proof:** source arithmetic alone does not prove player-facing duration, readability, collision feel, or chapter distribution.
- **Open gate:** capture a real F5 boot-to-credits run, collect its same-run telemetry, and embed representative PNG screenshots plus an optimized GIF in the release documentation.
