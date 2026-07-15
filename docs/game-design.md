# ROOM 407: THE LAST SHIFT — Game Design

## Overview

ROOM 407 is a short first-person psychological horror game about returning to a condemned apartment block that remembers the protagonist's childhood. The player explores, interprets clues, solves two guarded puzzles, and escapes; there is no combat.

This document separates implemented design from validation. Runtime telemetry now measures fresh Lobby-to-credits timing, but no recorded physical F5 blind run currently proves the intended 15–20 minute target.

## Core Fantasy

You are the only night worker inside a condemned apartment block. A routine call asks you to inspect Room 407, but the fourth floor remembers you better than you remember it.

The player is vulnerable, observant, and capable of escaping—not fighting. Fear comes from anticipation, spatial contradiction, sound outside the field of view, and familiar objects appearing where they should not.

## Player Experience Targets

- Complete a blind first playthrough in 15–20 minutes.
- Understand the main story without reading optional material.
- Feel tension rise in distinct waves rather than through constant pursuit.
- Solve the fuse and radio interactions without brute-force frustration.
- Trust capture recovery to return to a fair checkpoint.
- Reach an ending that clearly reframes the night shift.

These are design targets. Duration, clarity, comfort, and subjective tension still need manual observation.

## Story

At 23:47, a student covering a night shift at an old apartment block receives a call from the building manager. The manager asks for a check on Room 407, despite the fourth floor having been sealed after a child disappeared years ago.

Clocks point to 00:07, room numbers repeat, a radio carries the protagonist's voice, and an apparition watches from the corridor. A burned photograph, cassette, and red toy rabbit reveal that the protagonist lived in Room 407 as a child.

The final clue starts the escape. At the exit, the current gameplay scene constructs an abandoned-lobby reveal: a condemned desk, a 2007 condemnation notice, and a notice that no night staff were assigned. A credits overlay identifies the game, design/development attribution, Godot version, procedural art/audio/shader provenance, and project source license.

## Gameplay Loop

1. Explore a bounded corridor section.
2. Read a clue or observe an authored change.
3. Find a task item.
4. Use it at a guarded interaction point.
5. Trigger a one-shot horror or narrative beat.
6. Observe a changed hallway.
7. Unlock the next gate.
8. Survive the final chase.
9. Reach the abandoned-lobby reveal and credits.

All beats occupy one `gameplay.tscn` runtime. Memory-loop changes happen while a full-screen blackout curtain is opaque; the controller reconfigures the hallway and, on the first two loops, returns the player to the memory start during that hidden midpoint. These are not loading-screen scene transitions.

## Pacing Targets

| Chapter | Target | Main beats |
|---|---:|---|
| Lobby at 23:47 | 2–3 min | phone, logbook, fourth-floor key |
| Fourth-floor blackout | 3–4 min | fuse search, power restoration, first anomaly |
| Distorted memory loop | 4–5 min | three memories, two loop returns, radio code |
| Room 407 | 3–4 min | recording, drawing, final clue |
| Chase and ending | 2–3 min | guided escape, capture recovery, reveal, credits |

Runtime pacing instrumentation records actual first-occurrence milestone timestamps for fresh Lobby-to-credits sessions, separates active gameplay from wall-clock and paused time, derives the five chapter durations, and emits one `PLAYTHROUGH_PACING: ` JSON payload when visible credits appear. Checkpoint-start, incomplete, and out-of-order sessions receive no total pacing verdict.

These values remain authored goals, not release proof. Only a dated physical F5 blind keyboard-and-mouse boot-to-credits capture paired with the payload from that same run can establish the 15–20 minute target.

## Progression

### Lobby

The phone and logbook teach interaction. The player must read the stopped desk clock and then the night register before the logbook becomes valid; its 00:07 clue seeds the later radio puzzle. The fourth-floor door remains gated until the phone briefing completes and the log is signed.

### Fourth Floor

After crossing the first barrier, a maintenance notice establishes why the floor is closed and points toward the fuse locker. The player must read it, inspect an empty fuse box if desired, collect the spare fuse, and install it once. Installation advances the story only after the item guard passes; the power sequence then stabilizes before the next door opens.

### Memory Hallway

Three memory objects are ordered and idempotent. After each object returns its memory, the player follows a new environmental message before the loop gate will accept the next turn; the third echo opens the radio route after the final blackout.

| Item | Meaning | Progress effect |
|---|---|---|
| Burned photograph | The protagonist lived near Room 407 | reveals the stopped 00:07 clock clue |
| Cassette | The radio voice belongs to the protagonist | triggers the turn-away apparition |
| Red toy rabbit | The missing-child identity is personal | completes the loop prerequisite |

The hallway controller exposes four visual roots: the initial corridor and three progressively distorted variants. Blackouts hide their visibility swap and loop repositioning.

### Radio Code

- The input accepts at most four numeric digits.
- Submission requires exactly four digits.
- The correct code is `0007`.
- A wrong code displays static feedback and temporarily disables entry and submission.
- Stepping away and reopening during the cooldown keeps input disabled until the same cooldown expires.
- Three failures reveal the stopped-clock hint.
- Solving the UI begins a narrative sequence; Room 407 unlocks only when that sequence finishes and sets `radio_solved`.

### Room 407

The family recording must finish before the drawing can be inspected. The player then searches the child's bed, wardrobe, and family table for three physical clues; all five Room 407 clue interactions are required before the final note opens. Closing the note begins the chase setup and creates a `chase_start` checkpoint after the narrative beat completes.

### Chase and Ending

Chase start dims every named corridor light to eight percent of its previous energy while leaving red guide lights in the route. The entity uses `DORMANT`, `APPEAR`, `STALK`, `SEARCH`, `CHASE`, `LOST_TARGET`, and `DESPAWN` states with a runtime `NavigationAgent3D` over the continuous corridor navigation region.

Configured speed values are:

| Actor mode | Speed |
|---|---:|
| Player walk | 2.0 |
| Entity | 3.0 |
| Player sprint | 3.1 |

The automated layout test proves the scalar relationship `walk < entity < sprint` and verifies that the entity reaches `STALK`. It does not prove route readability, full physical traversal, collision feel, or human chase fairness; those remain manual checks.

The ending gate requires all three memories, radio completion, Room 407 recording and drawing, final clue, and chase start. Success advances the ending stage, builds the abandoned-lobby reveal, locks player input, stops the chase, holds the in-world view for three seconds, and opens the credits overlay in the same gameplay scene.

## Failure and Recovery

Checkpoints are created at the Room 407 entrance and chase start. On capture, the controller:

1. locks player input;
2. stops and hides the entity and chase drone;
3. shows the fail overlay;
4. restores the process-local `GameState` snapshot;
5. repositions the existing player and entity at the chase marker;
6. restarts the chase and unlocks input.

Retreating beyond the authored chase boundary requests this same recovery instead of disabling pursuit for the remainder of the run.

The boot menu exposes Continue when a checkpoint exists in the current process. Checkpoints are not written to disk and cannot survive an application restart.

## Settings and Accessibility

- Mouse sensitivity: 0.01–0.25, default 0.08.
- Field of view: 60–95 degrees, default 74.
- Master, music/chase, SFX, and ambience: −40 to +6 dB.
- Fullscreen toggle.
- Toggles for light flicker, comfort head bob, camera shake, and film grain/scanlines.
- Text prompts, objectives, notes, radio feedback, and narrative subtitles.
- Pause-menu access to the same settings panel as the boot menu.

Settings save to `user://room407.cfg` when the panel closes. Automated tests inspect controls and selected clamps, then use separate writer and reader processes to verify all 11 values persist across relaunch. Physical panel interaction, fullscreen display behavior, and audible results still require manual evidence.

## Completion Evidence Required

Automated checks cover progression guards, hallway transition completion, radio wrong/correct UI behavior, checkpoint restoration, layout/navigation invariants, chase speed ordering, ending success, and the reveal node. They also verify fresh-run pacing eligibility, checkpoint ineligibility, pause exclusion, actual milestone order, complete/null chapter semantics, visible-credits finalization, reset immutability, report-copy isolation, and deliberate rejection of compressed or out-of-order evidence.

Release validation still needs a recorded manual run covering:

- complete F5 boot-to-credits traversal with physical inputs and a same-run capture;
- the same run's eligible, complete, order-valid telemetry payload with chapter and 900–1200 second active-total evidence;
- collision and door passage feel;
- navigation behavior during a real chase;
- darkness, flicker, grain, and red-guide-light readability;
- master/music/SFX/ambience balance and audible output;
- mouse capture, pause/settings behavior, and comfort toggles;
- physical Settings-panel save/close behavior and fullscreen transition on target hardware.

## References

- [`gameplay-director.gd`](../scripts/world/gameplay-director.gd)
- [`story-progression-controller.gd`](../scripts/world/story-progression-controller.gd)
- [`chase-sequence-controller.gd`](../scripts/world/chase-sequence-controller.gd)
- [`playthrough-pacing-telemetry.gd`](../scripts/world/playthrough-pacing-telemetry.gd)
- [`hallway-transition-layer.gd`](../scripts/ui/hallway-transition-layer.gd)
- [`progression-test.gd`](../tests/progression-test.gd)
- [`checkpoint-layout-test.gd`](../tests/checkpoint-layout-test.gd)
- [Testing matrix](testing.md)
- [Known limitations](limitations.md)
