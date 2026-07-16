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

- The runner has twelve headless checks: editor import, boot load, gameplay load, game state, progression, checkpoint/layout, targeted physical-route movement, player-input integration, visual-effects contracts, settings/audio, persistence write, and persistence read.
- Every runner invocation uses a unique Godot user-data profile under `.tmp/`; the writer and reader share it, then guaranteed teardown removes it. Automated settings changes do not touch the normal game profile.
- Progression automation calls gameplay and radio widget methods directly. It covers radio Escape/unlock, non-digit filtering, cooldown persistence, the three-failure hint, final-note gating, and an entity-proximity capture recovery after injected positioning. It does not type, click, close the final note through physical input, or run a player-driven chase.
- Production pacing telemetry observes progression stages and visible credits. Progression automation verifies pause exclusion, actual ordered milestones, complete chapter reporting, finalization/deep-copy behavior, and that its compressed run is outside the 15–20 minute target. Checkpoint/layout automation verifies resumed sessions are incomplete and ineligible with a `null` verdict, remain immutable after reset, and reject out-of-order data. These checks validate instrumentation semantics only; they do not validate real input, blind-player behavior, or human pacing.
- The physical-route smoke synthesizes the mapped forward action through `Input.action_press()`, then reaches the production player's `Input.get_vector()` and physics path. It proves three locked/open door passages plus selected threshold gates, but it teleports between gates, sets flags, and calls doors directly. It does not prove physical W/E delivery, E/raycast interaction, the complete route, puzzle input, chase feel, or pacing.
- The player-input integration check confirms a physical E binding exists, then passes constructed `InputEventAction` objects directly to production handlers. It covers the phone interaction ray, objective review, pause/flashlight locks, note Escape/unlock, door spam and close/reopen cycles, and authored head-position restoration. It does not inject operating-system keyboard/mouse events or prove input latency and feel.
- Layout tests use node, polygon, numeric, and collision-ray assertions; they do not drive the player capsule through the complete route or prove live pathfinding quality.
- The visual-effects check verifies the overlay shader/material, dither/VHS/fear uniforms, chase/ending fear targets, and the film-grain visibility toggle. It does not inspect rendered pixels, readability, comfort, monitor gamma, or GPU performance.
- The settings/audio test verifies buses, selected clamps, controls, pause/boot modal focus and launcher return, visible save-failure retry/discard behavior, parameter-complete loop-aware audio cache variants, LRU/live-stream protection, exact byte accounting, spatial player lifetime/teardown, and in-memory Continue. Separate persistence checks save and restore all 11 values across two processes and check the returned save error. The nested `menu-settings-regression.gd` helper does not add a thirteenth runner check. No headless check verifies audible output, physical panel interaction, or target-device fullscreen behavior.
- The player-input check verifies bounded flashlight energy, reset when disabled/hidden, and `PROCESS_MODE_PAUSABLE` pause freeze. It does not prove rendered flicker comfort, monitor gamma, or physical pause timing.
- Headless rendering cannot establish darkness readability, flicker/grain comfort, color balance, ending presentation quality, monitor gamma, audible mix, or frame pacing on target hardware.

## Manual Evidence Still Required

Runtime pacing telemetry is implemented, but no dated physical F5 run currently proves the pacing target. Required evidence is a fresh blind keyboard-and-mouse boot-to-credits recording plus its same-run eligible, complete, order-valid `PLAYTHROUGH_PACING: ` payload; compressed automation and checkpoint-start reports are not substitutes.

`tests/run-physical-playthrough.ps1` can preserve same-session logs, bind them to one unchanged clean branch/commit, reject mixed, faulty, or out-of-target payloads, and record a tester-supplied capture reference. It cannot inspect that recording, distinguish a real key press from an inaccurate declaration, or judge presentation quality. Its generated checklist and summary are an evidence package for human review, not automatic proof of the physical gate.

The following are targets or implemented features, not manually verified release claims:

- 15-20 minute blind-run pacing and per-chapter pacing;
- complete F5 boot-to-credits traversal using real input;
- collision and door passage feel across the entire corridor;
- live `NavigationAgent3D` behavior and chase fairness under player control;
- corridor-light failure and red-guide-light readability during the chase;
- visual balance for flashlight, fog, blackout, flicker, grain, and ending reveal;
- audible phone, ambience, radio, footsteps, chase, fail, and ending balance;
- mouse capture, pause/settings behavior, fullscreen, and comfort toggles;
- physical Settings-panel save/close behavior and target-device fullscreen transition.

Use the manual matrix in `testing.md` and attach dated evidence before describing any of these as verified.

## Content and Presentation Scope

- Geometry, materials, labels, shader effects, and audio are intentionally procedural and asset-light. Shader effects currently include grain, scanlines, ordered dithering, VHS tracking/jitter, and a chase-responsive fear vignette/tint.
- The project contains no committed screenshots or gameplay-capture directory.
- Voice acting, external hero props, crouch, and a secondary ending are deferred.
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
- [Godot Engine license](https://godotengine.org/license/)
