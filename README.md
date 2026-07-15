# ROOM 407: THE LAST SHIFT

A short first-person psychological horror game built with Godot 4.7.1 and GDScript. You are a student covering a night shift in a condemned apartment block when a call sends you to a floor that should have been sealed for years.

> Development is active. The repository is being built as a complete 15–20 minute source-playable game; this README is updated as each verified slice lands.

## Quick Start

1. Download Godot Engine 4.7.1 (standard, not .NET).
2. Clone this repository.
3. Import `project.godot` in Godot.
4. Press **F6/F5** to run the configured main scene/project.

Command-line import check:

```powershell
godot --headless --path . --editor --quit
```

## Controls

| Action | Input |
|---|---|
| Move | W, A, S, D |
| Sprint | Shift |
| Interact | E |
| Flashlight | F |
| Review objective | Tab |
| Pause | Escape |

## Visual Direction

Low-poly PS1-inspired interiors, cold desaturated lighting, restrained fog, subtle optional grain, and readable darkness. No third-party art or audio is required.

## Screenshots

Add verified gameplay captures under `docs/screenshots/` after the full visual pass. Do not use concept art as a gameplay screenshot.

## Project Layout

- `scenes/` — boot, menus, levels, player, enemy, interactables, puzzles, events, and UI.
- `scripts/` — thin autoload services and scene-local gameplay components.
- `assets/` — project-created materials, textures, audio, and vector art.
- `shaders/` — Compatibility-renderer visual effects.
- `tests/` — native GDScript headless checks.
- `docs/` — game design, architecture, testing, licensing, and limitations.

## Documentation

- [Game design](docs/game-design.md)
- [Architecture](docs/architecture.md)
- [Code standards](docs/code-standards.md)

## License

Code and project-authored assets are released under the [MIT License](LICENSE). Detailed asset provenance is maintained in `docs/asset-credits.md` before release.
