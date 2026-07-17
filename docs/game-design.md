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

The final clue starts the escape. At the exit, the current gameplay scene constructs an abandoned-lobby reveal: a condemned desk, a 2007 condemnation notice, and a notice that no night staff were assigned. A credits overlay identifies the game, gives concise creator attribution, and closes with an in-world thank-you instead of production metadata.

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

The gameplay HUD presents the current story direction without an `OBJECTIVE` header. Empty inventory chrome stays hidden; when the player carries an item, the HUD shows its player-facing display name rather than its internal state ID.

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

The lobby desk also has an optional, visibly modeled drawer. Opening and closing it animates the prop, returns the scratched 00:07 detail or a clear close response, and never changes story progression. Its sweep guard asks the player to step back before motion rather than allowing the drawer to pass through the actor.

### Fourth Floor

After crossing the first barrier, a maintenance notice establishes why the floor is closed and points toward the fuse locker. The player must read it, inspect an empty fuse box if desired, collect the spare fuse, and install it once. Installation advances the story only after the item guard passes; the power sequence then stabilizes before the next door opens.

Crossing the threshold is a one-shot authored scare: the elevator display changes from `3` to `4`, the real floor door closes behind the player, and a distant, non-colliding arrival apparition appears before the display burns back to `--`. The fourth-floor shell uses alternating procedural wall panels, lights, and notices to make the route feel occupied without adding a second level or scene.

The scare begins with a distant lift-strain cue and a local red light response. The silhouette and two quieter spatial layers reveal after the warning; the display failure, light restoration, and actor/audio removal form its aftermath.

The painted elevator-side false door is optional. Trying it returns a clear explanation that the handle is painted onto the panel; the panel stays fixed and does not gate or advance progression.

### Memory Hallway

Three memory objects are ordered and idempotent. After each object returns its memory, the player follows a new environmental message before the loop gate will accept the next turn; the third echo opens the radio route after the final blackout.

| Item | Meaning | Progress effect |
|---|---|---|
| Burned photograph | The protagonist lived near Room 407 | reveals the stopped 00:07 clock clue |
| Cassette | The radio voice belongs to the protagonist | triggers the turn-away apparition |
| Red toy rabbit | The missing-child identity is personal | completes the loop prerequisite |

The hallway controller exposes four visual roots: the initial corridor and three progressively distorted variants. Blackouts hide their visibility swap and loop repositioning.

The three-memory suite stays authored and story-ordered. The photograph moves a low whisper from left to right around its message and briefly colors the nearest light. The cassette waits for the camera to turn away, places a non-colliding silhouette behind the player, then layers a breath and two reveal cues when the player looks back; an unrevealed silhouette is removed when `memory_cassette_recalled` completes. The rabbit uses a quiet music-box warning, a red light response, and a non-colliding apparition/presence reveal. These beats do not select randomly or change progression beyond their existing memory actions.

### Radio Code

- The input accepts at most four numeric digits.
- Submission requires exactly four digits.
- The correct code is `0007`.
- A wrong code displays static feedback and temporarily disables entry and submission.
- Stepping away and reopening during the cooldown keeps input disabled until the same cooldown expires.
- Three failures reveal the stopped-clock hint.
- Solving the UI begins a narrative sequence; Room 407 unlocks only when that sequence finishes and sets `radio_solved`.

### Room 407

The family recording must finish before the drawing can be inspected. The player then searches the child's bed, wardrobe, and family table for three physical clues; all five Room 407 clue interactions are required before the final note opens. Wallpaper panels, ceiling ribs, height marks, and a warning label sell the impossible childhood room while keeping the central navigation lane clear. Closing the note starts the climax with a low wall-breath warning and local light response, then reveals a visible, eyed, non-colliding manifestation with layered low/sting cues. The sequence clears before chase ownership starts; the `chase_start` checkpoint is created after the narrative beat completes.

Across the four story-aligned buildup beats—floor arrival, photograph, cassette turn-away, and rabbit—and the Room 407 climax, the direction pattern is anticipation → reveal → aftermath. Volumes remain low/moderate in source and spatial range stays bounded through the audio service, but audible balance and rendered timing/quality still require a physical review.

### Chase and Ending

Chase start dims every named corridor light to eight percent of its previous energy while leaving red guide lights in the route. Three physical barriers force a right-left-right slalom instead of a straight sprint. Each obstruction blocks one lane and exposes the safe side with matching red text, floor paint, and a local guide light. The same layout data shapes 13 connected navigation segments so the entity can pursue through the bypasses instead of clipping or stopping at the blockers.

The entity uses `DORMANT`, `APPEAR`, `STALK`, `CHASE`, `LOST_TARGET`, `SEARCH`, and `DESPAWN` states with a runtime `NavigationAgent3D` over the continuous corridor navigation region. Losing line of sight stores the last visible position; bounded search cycles revisit that position, reacquire the player when visible, or end in a hidden/stopped `DESPAWN` state. Restarting the chase resets the state, search budget, and visibility.

Configured speed values are:

| Actor mode | Speed |
|---|---:|
| Player walk | 2.0 |
| Entity | 3.0 |
| Player sprint | 3.1 |

The automated layout test proves `walk < entity < sprint`, verifies `STALK`, checks physical lane blocking and capsule clearance, confirms the path turns through all three bypasses, and drives the live-LOS entity across the first obstruction without failure or despawn. It does not prove rendered readability, player-driven traversal through all three barriers, collision feel, or human chase fairness; those remain manual checks.

The ending gate requires all three memories, radio completion, Room 407 recording and drawing, final clue, and chase start. Success advances the ending stage, stops the chase, and builds the abandoned-lobby reveal in the same gameplay scene. The player remains in control and must inspect two separated physical props in order: the 2007 condemnation notice, then the night roster. Each interaction delivers three voiced revelations; the roster stays gated until the notice narration finishes, and credits stay gated until the roster narration finishes. Visible credits hide the gameplay HUD, lock input, and finalize pacing.

## Failure and Recovery

Checkpoints are created at the Room 407 entrance and chase start. On capture, the controller:

1. locks player input;
2. stops and hides the entity and chase drone;
3. shows the fail overlay;
4. restores the process-local `GameState` snapshot;
5. repositions the existing player and entity at the chase marker;
6. restarts the chase and unlocks input.

Retreating beyond the authored chase boundary requests this same recovery instead of disabling pursuit for the remainder of the run.

The failure overlay keeps recovery in-world and does not expose checkpoint terminology. The boot menu opens with the 23:47 story setup and exposes **CONTINUE SHIFT** when a checkpoint exists in the current process. Checkpoints are not written to disk and cannot survive an application restart.

## Settings and Accessibility

- Mouse sensitivity: 0.01–0.25, default 0.08.
- Field of view: 60–95 degrees, default 74.
- Master volume, Music, Sound effects, and Atmosphere levels: −40 to +6 dB.
- Fullscreen toggle.
- Toggles for light flicker, camera movement, camera shake, and screen texture.
- Text prompts, objectives, notes, radio feedback, and narrative subtitles.
- Pause-menu access to the same settings panel as the boot menu.

Settings changes apply immediately. A successful **SAVE & CLOSE** writes `user://room407.cfg`; a failed write returns an internal `Error`, leaves the modal open, shows a plain-language recovery message without the system error code, and offers **RETRY SAVE** or **CLOSE WITHOUT SAVING**. Discarding closes without writing a new file, so those values remain session-only. Boot and pause menus trap focus inside the modal and return it to the Settings launcher. Automated tests inspect controls/clamps and use separate writer/reader processes to verify all 11 values persist across relaunch. Physical panel interaction, fullscreen display behavior, and audible results still require manual evidence.

## Visual Reference Material

The committed [visual-reference montage](./screenshots/room-407-gameplay-tour.gif) and stills for the [lobby](./screenshots/room-407-lobby.png), [Room 407 bedroom](./screenshots/room-407-bedroom.png), [chase entity](./screenshots/room-407-chase-entity.png), and [ending reveal](./screenshots/room-407-ending-reveal.png) show selected authored presentation states. They were refreshed and visually reviewed after the immersive HUD/menu copy pass: story directions stand alone, empty inventory is suppressed, and credits hide gameplay HUD.

The capture tour is intentionally not player-driven: it freezes gameplay/player simulation, disables voice, teleports the player, chooses hallway/chase/epilogue state directly, and manually creates credits. Therefore the montage is not a gameplay recording and cannot validate encounter pacing, progression clarity, tension waves, chase readability or fairness under motion, audio, Settings/fullscreen, or physical controls. Those design targets remain in the manual evidence matrix.

## Completion Evidence Required

Automated checks cover progression guards, fourth-floor/memory/Room 407 scare staging, unique cue IDs, non-colliding actors, pause-safe waits, one-shot/repeated-trigger behavior, light restoration, actor/audio ownership, cassette narration-bound cleanup, and scene-exit cleanup. They also cover hallway transition completion, radio wrong/correct UI behavior, checkpoint restoration, layout/navigation invariants, chase APPEAR/STALK/CHASE/LOS/search/reacquisition/DESPAWN behavior, pause-safe flashlight bounds, ending success, and the reveal node. The existing physical-route check exercises the optional drawer and painted door through the production ray, including structural visibility/alignment, feedback/cooldowns, drawer sweep and animation safety, unchanged story state, and spatial-audio/lock cleanup. Checks also verify fresh-run pacing eligibility, checkpoint ineligibility, pause exclusion, actual milestone order, complete/null chapter semantics, visible-credits finalization, reset immutability, report-copy isolation, modal focus/save-failure behavior, and deliberate rejection of compressed or out-of-order evidence. The Settings helper is nested inside `settings-audio`; the runner remains exactly twelve checks.

Release validation still needs a recorded manual run covering:

- complete F5 boot-to-credits traversal with physical inputs and a same-run capture;
- the same run's eligible, complete, order-valid telemetry payload with chapter and 900–1200 second active-total evidence;
- collision plus door and drawer-sweep clearance feel;
- navigation behavior during a real chase;
- darkness, flicker, grain, red-guide-light readability, and optional-prop visibility;
- master/music/SFX/ambience balance and audible output, including optional interaction tones;
- mouse capture, pause/settings behavior, and comfort toggles;
- physical Settings-panel save/close behavior and fullscreen transition on target hardware.

## References

- [`gameplay-director.gd`](../scripts/world/gameplay-director.gd)
- [`story-progression-controller.gd`](../scripts/world/story-progression-controller.gd)
- [`horror-event-director.gd`](../scripts/world/horror-event-director.gd)
- [`horror-scare-sequence.gd`](../scripts/world/horror-scare-sequence.gd)
- [`horror-apparition-factory.gd`](../scripts/world/horror-apparition-factory.gd)
- [`turn-away-apparition.gd`](../scripts/world/turn-away-apparition.gd)
- [`chase-sequence-controller.gd`](../scripts/world/chase-sequence-controller.gd)
- [`ending-epilogue-controller.gd`](../scripts/world/ending-epilogue-controller.gd)
- [`playthrough-pacing-telemetry.gd`](../scripts/world/playthrough-pacing-telemetry.gd)
- [`hallway-transition-layer.gd`](../scripts/ui/hallway-transition-layer.gd)
- [`progression-test.gd`](../tests/progression-test.gd)
- [`checkpoint-layout-test.gd`](../tests/checkpoint-layout-test.gd)
- [`visual-capture-tour.gd`](../tests/visual-capture-tour.gd)
- [Testing matrix](testing.md)
- [Known limitations](limitations.md)
