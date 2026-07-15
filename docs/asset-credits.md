# Asset Credits and Provenance

## Overview

The repository contains no third-party art pack, recorded audio, imported mesh, external font, Blender source, or committed `assets/` directory. Runtime visuals and sound are generated from project source plus Godot Engine built-ins.

## Provenance Table

| Asset or runtime output | Provenance | Repository source | License and distribution note |
|---|---|---|---|
| Corridor, partitions, doors, props, entity body, ending reveal, primitive materials, and labels | Project-authored procedural geometry assembled from Godot primitive meshes and nodes | `scripts/world/level-geometry.gd`, `continuous-world-builder.gd`, `continuous-story-layout.gd`, `dynamic-hallway-controller.gd`, `chase-sequence-controller.gd` | Project source and authored output are covered by the repository MIT license |
| Tones, footsteps, ambience, radio static, chase/fail/ending cues | Project-authored procedural 16-bit mono PCM generated at runtime; no audio files are committed | `scripts/autoload/audio-manager.gd` and call sites under `scripts/` | Project source and authored output are covered by the repository MIT license; audible balance remains manually unverified |
| Grain/scanline overlay | Project-authored Compatibility canvas shader | `shaders/retro-screen-overlay.gdshader` | Covered by the repository MIT license |
| Project icon | Project-authored SVG door/407 graphic | `icon.svg` | Covered by the repository MIT license |
| UI controls, primitive mesh classes, rendering/audio/navigation APIs, and default UI theme/font behavior | Godot Engine runtime defaults and built-in classes; no engine binary or font file is committed here | `project.godot` and Godot 4.7.1 runtime | Godot Engine is separately MIT-licensed and includes third-party components under their own notices; the project license does not relicense them |

## License Scope

The root `LICENSE` applies to this project's code and project-authored assets. It does not replace, absorb, or relicense Godot Engine's copyright, MIT notice, or third-party notices.

This repository is source-only and does not distribute a Godot executable or exported game binary. Any future binary distribution must include the notices required for the bundled Godot Engine copy and applicable engine third-party components. The official Godot license guidance states that a distributed engine binary remains a copy of Godot Engine even when the game content uses a different license.

## Future Asset Intake

Before committing any external or commissioned asset, add a row recording:

- asset name and repository path;
- creator and source URL or delivery record;
- license name and exact version;
- required attribution text;
- whether modification and redistribution are allowed;
- proof that the file used matches the recorded source.

Do not commit an asset with unknown provenance or terms.

## References

- [Project MIT license](../LICENSE)
- [`icon.svg`](../icon.svg)
- [`retro-screen-overlay.gdshader`](../shaders/retro-screen-overlay.gdshader)
- [`audio-manager.gd`](../scripts/autoload/audio-manager.gd)
- [`level-geometry.gd`](../scripts/world/level-geometry.gd)
- [Godot Engine license](https://godotengine.org/license/)
- [Known limitations](limitations.md)
