# Asset Credits and Provenance

## Overview

The project has no source dependency on a third-party art pack, recorded-audio library, imported mesh, external font, or Blender source, and it has no committed `assets/` directory. Runtime visuals and sound are generated from project source plus Godot Engine built-ins. Machine-local `.artifacts/` captures are test outputs, not source assets.

## Provenance Table

| Asset or runtime output | Creator | Source/provenance | Repository paths | License | Attribution/redistribution |
|---|---|---|---|---|---|
| Corridor, partitions, doors, elevator display/arrival apparition, Room 407 dressing, chase wall scars, props, entity body, ending reveal, primitive materials, and labels | JasonTM17 and contributors | Created specifically for this project. Procedural geometry assembled at runtime from Godot primitive meshes, materials, labels, and nodes; no imported mesh files. The fourth-floor and Room 407 manifestation beats are runtime nodes, not external assets. | `scripts/world/level-geometry.gd`<br>`scripts/world/continuous-world-builder.gd`<br>`scripts/world/continuous-story-layout.gd`<br>`scripts/world/story-prop-visual-builder.gd`<br>`scripts/world/dynamic-hallway-controller.gd`<br>`scripts/world/horror-event-director.gd`<br>`scripts/world/turn-away-apparition.gd`<br>`scripts/world/chase-sequence-controller.gd` | MIT; see `LICENSE` | Redistribution permitted under MIT. Retain the root copyright and permission notice in copies or substantial portions. |
| Tones, footsteps, ambience, radio static, chase, fail, and ending cues | JasonTM17 and contributors | Created specifically for this project. Procedural 16-bit mono PCM generated at runtime; no recorded audio files are source dependencies. Audible balance remains manually unverified. | `scripts/autoload/audio-manager.gd` | MIT; see `LICENSE` | Redistribution permitted under MIT. Retain the root copyright and permission notice in copies or substantial portions. |
| Retro screen effects: grain, scanlines, ordered dithering, VHS tracking/jitter, fear-vignette pulse, and chase-edge tint | JasonTM17 and contributors | Created specifically for this project. Compatibility canvas shader driven by a project-authored runtime layer and the film-grain comfort setting. | `shaders/retro-screen-overlay.gdshader`<br>`scripts/ui/visual-effects-layer.gd` | MIT; see `LICENSE` | Redistribution permitted under MIT. Retain the root copyright and permission notice in copies or substantial portions. |
| Project icon: door/407 SVG graphic | JasonTM17 and contributors | Created specifically for this project. Project-authored vector graphic configured as the application icon. | `icon.svg`<br>`project.godot` | MIT; see `LICENSE` | Redistribution permitted under MIT. Retain the root copyright and permission notice in copies or substantial portions. |
| Primitive mesh classes, rendering/audio/navigation APIs, and default UI theme/font behavior | Godot Engine contributors and the authors of its third-party components | Godot 4.7.1 runtime defaults and built-in classes. No Godot executable or external font file is committed with this source project. | `project.godot` | Godot Engine MIT; bundled third-party components retain their own terms | A future binary distribution must include the Godot copyright and MIT license text plus applicable third-party notices. The project MIT license does not relicense engine components. |

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
- [`visual-effects-layer.gd`](../scripts/ui/visual-effects-layer.gd)
- [`audio-manager.gd`](../scripts/autoload/audio-manager.gd)
- [`level-geometry.gd`](../scripts/world/level-geometry.gd)
- [Godot Engine license](https://godotengine.org/license/)
- [Known limitations](limitations.md)
