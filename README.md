# ROOM 407: THE LAST SHIFT

A short first-person psychological horror game built with Godot 4.7.1 and GDScript. A student covering a night shift enters a condemned apartment block after a call points to a floor that should have been sealed for years.

The implemented path keeps the lobby, fourth-floor corridor, memory loop, Room 407, chase, reveal, and credits inside one continuous gameplay scene. The intended first-run duration is 15–20 minutes. Scene-local telemetry now measures that route, but the pacing target still requires a recorded physical playthrough and its same-run payload.

## Requirements

- Godot Engine 4.7.1 standard build, not .NET.
- A renderer compatible with Godot's Compatibility/OpenGL path.
- PowerShell to run the bundled Windows headless test runner.

This is a source-only project. The repository has no `export_presets.cfg`, exported executable, or bundled Godot binary.

## Run

1. Import `project.godot` in Godot 4.7.1.
2. Press **F5** to run the project from the configured boot scene.

Use F5 for the intended flow. **F6 runs the currently open scene and may bypass the boot menu.**

Command-line import check:

```powershell
godot --headless --path . --editor --quit
```

## Controls

| Action | Input |
|---|---|
| Move | W, A, S, D |
| Look | Mouse |
| Sprint | Shift |
| Interact | E |
| Flashlight | F |
| Review objective | Tab |
| Pause | Escape |

The pause menu includes Settings. Mouse sensitivity, field of view, four audio levels, fullscreen, light flicker, head bob, camera shake, and film grain controls are available. Closing the settings panel writes `user://room407.cfg`.

## Implemented Gameplay

- One continuous `gameplay.tscn` runtime assembled from procedural geometry and authored controllers.
- Guarded phone, logbook, fuse, memory, radio, Room 407, chase, and ending progression.
- Four visibility-switched hallway states: one baseline plus three blackout-driven changes.
- A real `NavigationRegion3D` and an enemy state machine that reaches `STALK` before `CHASE`.
- Chase speed of 3.0 units/second versus player walk 2.0 and sprint 3.1 units/second.
- Corridor-light failure at chase start, checkpoint recovery, an abandoned-lobby reveal, and a credits overlay.
- A three-second in-world ending reveal before the credits overlay appears.
- Pause-aware playthrough pacing telemetry for fresh Lobby runs, finalized when the visible credits appear.
- Boot-menu Continue when an in-memory checkpoint exists.

Checkpoints are process-local. Restarting the application clears gameplay progress; settings are the only persisted user data.

## Architecture

F5 loads `boot.tscn`, then enters the single continuous `gameplay.tscn`. `GameplayDirector` builds the procedural world and composes the player, UI, story, hallway, horror-event, chase, ending, and scene-local pacing components at runtime. Four autoloads own process state, scene routing, generated audio, and persisted settings; story controllers reach them through the director facade and stable flag/item IDs. The pacing facade returns a deep copy so callers cannot mutate the live report.

`AudioManager` creates the Music, SFX, Ambience, and Chase buses before `SettingsManager` applies either saved values or the first-run defaults. This keeps a fresh profile at the configured bus levels instead of Godot's implicit 0 dB for every created bus. See [Architecture](docs/architecture.md) for controller boundaries, data flow, and extension points.

## Test

Run all twelve headless checks from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1
```

Override the portable Godot executable when it is not at the runner's default path:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1 `
  -Godot "C:\path\to\Godot_v4.7.1-stable_win64_console.exe"
```

The exact checks are `editor-import`, `menu`, `gameplay`, `game-state`, `progression`, `checkpoint-layout`, `physical-route`, `player-input`, `visual-effects`, `settings-audio`, `settings-persistence-write`, and `settings-persistence-read`.

The runner writes one log per check to `.artifacts/test-<name>.log`, isolates Godot user data under `.tmp/`, and removes its unique profile in guaranteed teardown, so it does not overwrite the normal `user://room407.cfg`. Coverage includes import and scene construction; state/checkpoint and guarded progression; pacing eligibility, pause accounting, milestone order, finalization, and invalid-run rejection inside the existing progression and checkpoint checks; layout, navigation, chase, and capsule/door invariants; the physical E binding plus the mapped interact action through the production 2.5-unit ray; locked-door spam and close/reopen; objective review; flashlight and pause locks; note and radio modal close/unlock behavior; visual-effect uniforms and chase fear transitions; first-run audio-bus defaults; settings controls/teardown; and settings persistence across two Godot processes.

These checks do not prove a full physical F5 boot-to-credits traversal, 15–20 minute pacing, rendered visual balance, audible output or mix balance, live chase fairness, or the physical Settings UI workflow. See [Testing](docs/testing.md) for the assertion-level matrix.

## Capture a Pacing Payload

Start a fresh shift with **F5**, not Continue, and complete it with physical keyboard and mouse input while recording the run. When the credits become visible, preserve the single console line beginning with:

```text
PLAYTHROUGH_PACING: {JSON payload}
```

Keep that exact payload with the same-run boot-to-credits capture. The game does not save the report to a file or show it in the UI. A headless runner artifact can contain two identical lines because it concatenates the engine log and captured console output; the runtime still emitted once. Even an eligible, complete, in-target payload is instrumentation, not proof of physical traversal, capture behavior, chase feel, presentation, audio, or Settings behavior.

## Assets

There is no committed `assets/` directory or third-party art/audio pack. Corridor geometry, props, materials, labels, and 16-bit mono PCM cues are generated at runtime; `icon.svg` is project-authored. The project-authored Compatibility shader adds 2x2 dithering, VHS tracking/jitter, grain, scanlines, a cold grade, and an edge vignette that intensifies and warms during the chase. The **Film Grain** setting controls the entire overlay, including the chase fear vignette.

No gameplay captures are committed. Add only verified in-engine captures under `docs/screenshots/` after a manual visual pass; do not present concept art as gameplay. See [Asset credits and provenance](docs/asset-credits.md).

## Known Limitations

- No recorded manual F5 boot-to-credits pass with its same-run telemetry payload currently verifies the complete physical route.
- The 15–20 minute duration is an instrumented authored target, not a recorded physical-playthrough result.
- Audible audio/mix balance, live chase navigation and fairness, and target-display visual balance remain manually unverified.
- Checkpoints last only for the current application process; only settings persist to disk.
- No export preset, release binary, or platform package is committed or release-tested.

See [Known limitations](docs/limitations.md) for the complete release boundary and required evidence.

## Export

No export preset is committed or release-tested. To prepare a local binary, install the matching Godot 4.7.1 export templates and create a platform preset through **Project > Export**. Keep generated packages outside the repository; treat binary export, platform packaging, and runtime notices as unverified until tested on the target platform.

## Contributing

Keep changes focused, use Conventional Commit messages, and do not commit `.godot/`, `.artifacts/`, local tools, exports, or credentials. Before submitting a change, run the twelve-check suite and `git diff --check`, then update documentation only for behavior the current source or recorded manual evidence proves.

## Project Layout

| Path | Contents |
|---|---|
| `project.godot` | Main scene, autoloads, input map, display, and Compatibility renderer configuration |
| `scenes/boot/` | Boot scene |
| `scenes/gameplay/` | Continuous gameplay scene root |
| `scenes/player/` | Player scene and configured movement values |
| `scenes/ui/` | HUD, pause/settings, fail, and ending overlays |
| `scripts/autoload/` | Game state, scene routing, audio, and settings services |
| `scripts/interaction/` | Door, pickup, and story interaction contracts |
| `scripts/player/` | Movement, flashlight, and interaction ray logic |
| `scripts/puzzles/` | Radio puzzle UI and validation |
| `scripts/ui/` | Runtime UI, transitions, and visual effects |
| `scripts/world/` | World construction, progression, horror events, navigation, chase, and ending logic |
| `shaders/` | Project-authored Compatibility canvas shader |
| `tests/` | Native GDScript checks and PowerShell runner |
| `docs/` | Design, architecture, standards, testing, provenance, and limitations |
| `plans/` | Project planning and historical verification artifacts |

There is no committed `assets/` directory. Geometry and audio are generated at runtime; the project-authored icon is `icon.svg` at the repository root.

## References

- [Game design](docs/game-design.md)
- [Architecture](docs/architecture.md)
- [Code standards](docs/code-standards.md)
- [Testing](docs/testing.md)
- [Asset credits and provenance](docs/asset-credits.md)
- [Known limitations](docs/limitations.md)
- [Project configuration](project.godot)

## License

Project code and project-authored assets are released under the [MIT License](LICENSE). This license does not relicense Godot Engine or its third-party components; see [Asset credits and provenance](docs/asset-credits.md).
