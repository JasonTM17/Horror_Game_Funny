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
- Settings save to `user://room407.cfg` when Settings is closed. Isolated writer/reader processes verify file creation and all 11 values across relaunch; physical panel interaction and the real player profile remain manual boundaries.

## Automated Test Boundaries

- The runner has ten headless checks: editor import, boot load, gameplay load, game state, progression, checkpoint/layout, targeted physical-route movement, settings/audio, persistence write, and persistence read.
- Every runner invocation uses a unique Godot user-data profile under `.tmp/`; the writer and reader share it, then guaranteed teardown removes it. Automated settings changes do not touch the normal game profile.
- Progression automation calls gameplay methods and UI submission methods directly; it does not generate a full physical keyboard/mouse traversal.
- The physical-route smoke sends the mapped forward action through the production player and physics, proving three locked/open door passages plus selected threshold gates. It teleports between gates, sets flags, and calls doors directly, so it does not prove E/raycast interaction, the complete route, puzzle input, chase feel, or pacing.
- Layout tests use node, polygon, numeric, and collision-ray assertions; they do not drive the player capsule through the complete route or prove live pathfinding quality.
- The settings/audio test verifies buses, selected clamps, controls, pause Settings/Escape lock preservation, audio cache/player teardown, and in-memory Continue. Separate persistence checks save and restore all 11 values across two processes. No headless check verifies audible output or physical panel interaction.
- Headless rendering cannot establish darkness readability, flicker/grain comfort, color balance, ending presentation quality, monitor gamma, or frame pacing on target hardware.

## Manual Evidence Still Required

The following are targets or implemented features, not manually verified release claims:

- 15–20 minute blind-run pacing and per-chapter pacing;
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

- Geometry, materials, labels, shader effects, and audio are intentionally procedural and asset-light.
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
- [`settings-manager.gd`](../scripts/autoload/settings-manager.gd)
- [`game-state.gd`](../scripts/autoload/game-state.gd)
- [Godot Engine license](https://godotengine.org/license/)
