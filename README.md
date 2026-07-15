# ROOM 407: THE LAST SHIFT

A short first-person psychological horror game built with Godot 4.7.1 and GDScript. A student covering a night shift enters a condemned apartment block after a call points to a floor that should have been sealed for years.

The implemented path keeps the lobby, fourth-floor corridor, memory loop, Room 407, chase, reveal, and credits inside one continuous gameplay scene. The intended first-run duration is 15–20 minutes; that pacing target still requires a recorded manual playthrough.

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
- Three hallway variants swapped during full-screen blackout transitions.
- A real `NavigationRegion3D` and an enemy state machine that reaches `STALK` before `CHASE`.
- Chase speed of 3.0 units/second versus player walk 2.0 and sprint 3.1 units/second.
- Corridor-light failure at chase start, checkpoint recovery, an abandoned-lobby reveal, and a credits overlay.
- A three-second in-world ending reveal before the credits overlay appears.
- Boot-menu Continue when an in-memory checkpoint exists.

Checkpoints are process-local. Restarting the application clears gameplay progress; settings are the only persisted user data.

## Test

Run all nine headless checks from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1
```

Override the portable Godot executable when it is not at the runner's default path:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1 `
  -Godot "C:\path\to\Godot_v4.7.1-stable_win64_console.exe"
```

The runner writes one log per check to `.artifacts/test-<name>.log`, isolates Godot user data under `.tmp/`, and removes its unique profile in guaranteed teardown, so it does not overwrite the normal `user://room407.cfg`. It covers import, boot and gameplay loading, state/checkpoint behavior, guarded progression, layout/navigation/chase invariants, settings/audio structure, and settings save/load across two separate Godot processes. It does not prove a 15–20 minute run, visual or audio balance, audible device output, the physical Settings UI workflow, or full keyboard-and-mouse traversal. See [Testing](docs/testing.md) for the exact matrix.

## Export

No export preset is committed or release-tested. To prepare a local binary, install the matching Godot 4.7.1 export templates and create a platform preset through **Project > Export**. Keep generated packages outside the repository; treat binary export, platform packaging, and runtime notices as unverified until tested on the target platform.

## Screenshots

No gameplay captures are committed yet. Add only verified in-engine captures under `docs/screenshots/` after the manual visual pass; do not present concept art as gameplay.

## Contributing

Keep changes focused, use Conventional Commit messages, and do not commit `.godot/`, `.artifacts/`, local tools, exports, or credentials. Before submitting a change, run the nine-check suite and `git diff --check`, then update documentation only for behavior the current source or recorded manual evidence proves.

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
