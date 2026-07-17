# Known Limitations

## Distribution

- The project is source-playable with Godot 4.7.1 standard and targets the Compatibility renderer.
- No `export_presets.cfg`, exported executable, package, or bundled Godot binary is committed.
- F5 follows the configured boot-to-gameplay flow. F6 runs the editor's current scene and can bypass the boot menu.
- Binary export, platform packaging, and redistribution notice checks are not currently automated.

## Persistence

- Gameplay checkpoints exist only in the `GameState` autoload for the current process.
- The boot Continue button appears only when that in-memory checkpoint dictionary is populated.
- Restarting the application removes checkpoint progress and starts a fresh shift.
- Settings changes apply immediately. A successful **SAVE & CLOSE** writes `user://room407.cfg`; `save_settings()` returns an error and emits a failure signal when the write fails, so the modal stays open with **RETRY SAVE** or **CLOSE WITHOUT SAVING**. Isolated writer/reader processes verify file creation and all 11 values across relaunch; physical panel interaction and the real player profile remain manual boundaries.

## Automated Test Boundaries

- The runner has twelve headless checks: editor import plus canonical `project.godot` serialization, boot load, gameplay load, game state, progression, checkpoint/layout, targeted physical-route movement, player-input integration, visual-effects contracts, settings/audio, persistence write, and persistence read.
- Every runner invocation uses a unique Godot user-data profile under `.tmp/`; the writer and reader share it, then guaranteed teardown removes it. Automated settings changes do not touch the normal game profile.
- Progression automation calls gameplay and radio widget methods directly. It covers radio Escape/unlock, non-digit filtering, cooldown persistence, the three-failure hint, final-note gating, and an entity-proximity capture recovery after injected positioning. It does not type, click, close the final note through physical input, or run a player-driven chase.
- Production pacing telemetry observes progression stages and visible credits. Progression automation verifies pause exclusion, actual ordered milestones, complete chapter reporting, finalization/deep-copy behavior, and that its compressed run is outside the 15–20 minute target. Checkpoint/layout automation verifies resumed sessions are incomplete and ineligible with a `null` verdict, remain immutable after reset, and reject out-of-order data. These checks validate instrumentation semantics only; they do not validate real input, blind-player behavior, or human pacing.
- The physical-route smoke synthesizes mapped forward movement through `Input.action_press()`, then reaches the production player's `Input.get_vector()` and physics path. Its optional-interaction helper forces the production ray and passes constructed mapped interaction actions directly to the handler. It proves structural drawer/false-door visibility alignment, ray acquisition, feedback/cooldowns, drawer sweep/animation locking, unchanged story state, spatial-tone/lock teardown, three locked/open door passages, and selected thresholds. It still teleports, sets flags, and calls guarded route doors directly; it does not prove operating-system W/E delivery, rendered optional-prop quality, audible tone balance, the complete route, puzzles, chase feel, or pacing.
- The player-input integration check confirms a physical E binding exists, then passes constructed `InputEventAction` objects directly to production handlers. It covers the phone interaction ray, objective review, pause/flashlight locks, note Escape/unlock, door spam, open/close rejection within the 1.5 m sweep without state mutation, safe close/reopen, reason-scoped movement-only lock/release, and authored head-position restoration. It does not inject operating-system keyboard/mouse events or prove input latency, camera feel, or whether the sweep clearance feels natural during a full traversal.
- Layout tests use node, polygon, numeric, collision-ray, and audio-player ownership assertions. They prove that chase start and checkpoint recovery each own one bounded entity-parented SFX cue and that failure/ending teardown removes stale playback/cache ownership; they do not drive the player capsule through the complete route, prove live pathfinding quality, or establish that the cue is audible and balanced.
- The visual-effects check verifies the overlay shader/material, dither/VHS/fear uniforms, chase/ending fear targets, and the film-grain visibility toggle. It does not inspect rendered pixels, readability, comfort, monitor gamma, or GPU performance.
- The settings/audio test verifies buses, selected clamps, controls, pause/boot modal focus and launcher return, visible save-failure retry/discard behavior, parameter-complete loop-aware audio cache variants, LRU/live-stream protection, exact byte accounting, spatial player lifetime/teardown, in-memory Continue, all 76 English voice resources, exact cue/subtitle fallback, voice-duration holds including the six-line epilogue, queue ordering/duplicates, pause/resume, and teardown. Separate persistence checks save and restore all 11 values across two processes and check the returned save error. Nested voice and menu helpers do not add runner checks. No headless check verifies audible performance, intelligibility, mix quality, physical panel interaction, or target-device fullscreen behavior.
- The player-input check verifies bounded flashlight energy, reset when disabled/hidden, and `PROCESS_MODE_PAUSABLE` pause freeze. It does not prove rendered flicker comfort, monitor gamma, or physical pause timing.
- Headless rendering cannot establish darkness readability, flicker/grain comfort, color balance, ending presentation quality, monitor gamma, audible mix, or frame pacing on target hardware.

## Manual Evidence Still Required

Runtime pacing telemetry is implemented, but no dated physical F5 run currently proves the pacing target. Required evidence is a fresh blind keyboard-and-mouse boot-to-credits recording plus its same-run eligible, complete, order-valid `PLAYTHROUGH_PACING: ` payload; compressed automation and checkpoint-start reports are not substitutes.

`tests/run-physical-playthrough.ps1` can preserve same-session logs, bind them to one unchanged clean branch/commit, reject mixed, faulty, or out-of-target payloads, and record a tester-supplied capture reference. It cannot inspect that recording, distinguish a real key press from an inaccurate declaration, or judge presentation quality. Its generated checklist and summary are an evidence package for human review, not automatic proof of the physical gate.

The following are targets or implemented features, not manually verified release claims:

- 15-20 minute blind-run pacing and per-chapter pacing;
- complete F5 boot-to-credits traversal using real input;
- collision plus door and drawer-sweep clearance feel across the entire corridor;
- live `NavigationAgent3D` behavior and chase fairness under player control;
- corridor-light failure and red-guide-light readability during the chase;
- visual balance for flashlight, fog, blackout, flicker, grain, optional props, and ending reveal;
- audible narration/character voice, phone, ambience, radio, footsteps, optional interaction tones, chase, fail, and ending balance;
- mouse capture, pause/settings behavior, fullscreen, and comfort toggles;
- physical Settings-panel save/close behavior and target-device fullscreen transition.

Use the manual matrix in `testing.md` and attach dated evidence before describing any of these as verified.

## Content and Presentation Scope

- Geometry, materials, labels, shader effects, and sound effects are intentionally procedural and asset-light. The exception is the committed generated English story voice set. Shader effects currently include grain, scanlines, ordered dithering, VHS tracking/jitter, and a chase-responsive fear vignette/tint.
- The repository commits four reviewed 960×540 staged in-engine stills and one 640×360 derived visual-reference GIF under `docs/screenshots/`. The reproducible capture harness uses production gameplay/ending scenes but freezes gameplay and player simulation, disables voice, teleports the player, directly selects presentation states, and creates credits manually. These files demonstrate selected rendered views only; they are not a gameplay recording or evidence of physical F5 traversal, pacing, progression, chase fairness, audio, Settings/fullscreen behavior, pixel determinism, or cross-hardware consistency.
- Seven source PNGs, the 1280×720 12 fps source AVI, and capture logs stay machine-local under ignored `.artifacts/`; only reviewed, optimized documentation media belongs under `docs/screenshots/`.
- Generated English narration/character delivery is implemented for every sequenced story line; human-performed acting, external hero props, crouch, and a secondary ending remain out of scope. Voice quality and mix still require a physical listening pass.
- The radio, subtitles, and credits use runtime UI/default theme behavior rather than committed font assets.
- The current story and credits are English-only.

## Licensing

- The repository MIT license covers project code and project-authored assets.
- It does not relicense Godot Engine or the engine's third-party components.
- A future exported binary must retain the notices required by the Godot Engine distribution it includes.

## References

- [Testing matrix](testing.md)
- [Architecture](architecture.md)
- [Asset credits and provenance](asset-credits.md)
- [`run-headless-tests.ps1`](../tests/run-headless-tests.ps1)
- [`run-physical-playthrough.ps1`](../tests/run-physical-playthrough.ps1)
- [`settings-manager.gd`](../scripts/autoload/settings-manager.gd)
- [`game-state.gd`](../scripts/autoload/game-state.gd)
- [`playthrough-pacing-telemetry.gd`](../scripts/world/playthrough-pacing-telemetry.gd)
- [`visual-capture-tour.gd`](../tests/visual-capture-tour.gd)
- [Staged capture testing boundary](testing.md#reproducible-visual-capture-tour)
- [Godot Engine license](https://godotengine.org/license/)
