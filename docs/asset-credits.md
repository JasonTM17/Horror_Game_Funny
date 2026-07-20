# Asset Credits and Provenance

## Overview

The project has no source dependency on a third-party art pack, recorded-sound library, imported mesh, external font, or Blender source. Runtime geometry and effects are primarily generated from project source plus Godot Engine built-ins. The committed `assets/` directory contains the generated English story voice set (manifest + import sidecars) and four project-authored still textures for the boot menu and selected story props; the documentation-only repository cover lives under `docs/media/`, while reviewed in-engine media lives under `docs/screenshots/`. Machine-local `.artifacts/` captures remain ignored source material, not committed assets.

## Provenance Table

| Asset or runtime output | Creator | Source/provenance | Repository paths | License | Attribution/redistribution |
|---|---|---|---|---|---|
| Repository cover artwork | JasonTM17 and contributors; generated with OpenAI image generation from the project-authored menu corridor still | Created specifically for this repository on 2026-07-18. The accepted edit preserves the empty decaying corridor and adds the exact two-line title `ROOM 407` / `THE LAST SHIFT` inside the existing left-side negative space. The output was center-cropped/resized to 1280x640 and stripped of metadata with ImageMagick 7.1.2; final size is 999,431 bytes and SHA-256 is `58d5893ef611bfa8b5657c40483073c0ba67c086c0fd2577d4538502d2283980`. It is documentation artwork, is excluded from the game export with the rest of `docs/`, and is not gameplay or physical-playthrough evidence. | `docs/media/room-407-cover.png`<br>`README.md` | Project-authorized generated asset, distributed with this repository under the project MIT notice. The image-generation service's current terms govern the generation process; no separate third-party stock license is being asserted. | Retain the project MIT notice and this provenance record when redistributing the repository. Do not present the cover as an in-engine capture, physical-playthrough evidence, or third-party stock. |
| Corridor, partitions, doors, elevator display/arrival apparition, Room 407 dressing, chase wall scars, props, entity body, interactive ending reveal, primitive materials, and labels | JasonTM17 and contributors | Created specifically for this project. Procedural geometry assembled at runtime from Godot primitive meshes, materials, labels, and nodes; no imported mesh files. The fourth-floor, Room 407 manifestation, chase entity details, and two ending evidence props are runtime nodes, not external assets. | `scripts/world/level-geometry.gd`<br>`scripts/world/continuous-world-builder.gd`<br>`scripts/world/continuous-story-layout.gd`<br>`scripts/world/story-prop-visual-builder.gd`<br>`scripts/world/dynamic-hallway-controller.gd`<br>`scripts/world/horror-event-director.gd`<br>`scripts/world/turn-away-apparition.gd`<br>`scripts/world/chase-sequence-controller.gd`<br>`scripts/world/chase-entity-visual-builder.gd`<br>`scripts/world/ending-epilogue-controller.gd` | MIT; see `LICENSE` | Redistribution permitted under MIT. Retain the root copyright and permission notice in copies or substantial portions. |
| Tones, footsteps, ambience, radio static, chase, fail, and ending cues | JasonTM17 and contributors | Created specifically for this project. Procedural 16-bit mono PCM generated at runtime; no recorded audio files are source dependencies. Audible balance remains manually unverified. | `scripts/autoload/audio-manager.gd` | MIT; see `LICENSE` | Redistribution permitted under MIT. Retain the root copyright and permission notice in copies or substantial portions. |
| 76 English story voice cues | JasonTM17 and contributors; generated with Piper TTS 1.4.2 and `en_US-kristin-medium` | Cue text and role treatments are project-authored. The reviewed Piper voice model card says the model was trained from scratch from public-domain LibriVox recordings. Outputs are normalized mono 22.05 kHz OGG Vorbis. The six ending cues add 30.596 seconds of decoded narration. The generator validates the complete staged set before publication and checks the reviewed tool/model hashes; the pre-existing 70 committed OGG files were restored byte-identically after generating the six additions. The local Piper runtime, Python environment, model weights, WAV intermediates, and caches are not committed. | `assets/audio/voice-over/*.ogg`<br>`assets/audio/voice-over/*.ogg.import`<br>`assets/audio/voice-over/voice-over-manifest.json`<br>`tools/generate-voice-over.ps1` | Project files: MIT; Piper voices repository: MIT; local Piper build tool: GPL-3.0 | Retain the project MIT notice. Re-run generation only with the reviewed Piper version and model/config hashes recorded in the script. Audible performance and mix remain manually unverified. |
| Retro screen effects: grain, scanlines, ordered dithering, VHS tracking/jitter, fear-vignette pulse, and chase-edge tint | JasonTM17 and contributors | Created specifically for this project. Compatibility canvas shader driven by a project-authored runtime layer and the film-grain comfort setting. | `shaders/retro-screen-overlay.gdshader`<br>`scripts/ui/visual-effects-layer.gd` | MIT; see `LICENSE` | Redistribution permitted under MIT. Retain the root copyright and permission notice in copies or substantial portions. |
| Project icon: door/407 SVG graphic | JasonTM17 and contributors | Created specifically for this project. Project-authored vector graphic configured as the application icon. | `icon.svg`<br>`project.godot` | MIT; see `LICENSE` | Redistribution permitted under MIT. Retain the root copyright and permission notice in copies or substantial portions. |
| Boot menu corridor still and three story-prop stills (memory photo, Room 407 drawing, family table) | JasonTM17 and contributors; generated with OpenAI image generation | Generated specifically for this project on 2026-07-18 and reviewed before wiring. The menu composition is an empty decaying hotel corridor with a dark left UI-safe area, burgundy wallpaper, cold ceiling light, and red emergency glow. The memory photo is a faded corridor snapshot with a red stuffed rabbit and aged/burned paper edge; the child's drawing is an aged crayon rabbit drawing on cream paper; the family-table memory is a faded abandoned dinner-table still life with an empty chair and red rabbit. Prompts explicitly excluded text, logos, watermarks, people/faces, and graphic gore. No third-party stock image, recognizable brand, or external logo is included. Boot menu loads the corridor still as a full-screen `TextureRect` under a translucent shade. Story prop builder overlays the three prop stills on paper/table quads via `LevelGeometry.textured_material`. Godot texture import sidecars are committed with the PNGs. | `assets/images/menu-hotel-corridor.png`<br>`assets/images/memory-photo-rabbit.png`<br>`assets/images/room-drawing-rabbit.png`<br>`assets/images/family-table-memory.png`<br>`assets/images/*.png.import`<br>`scripts/ui/boot-menu.gd`<br>`scripts/world/story-prop-visual-builder.gd`<br>`scripts/world/level-geometry.gd` | Project-authorized generated assets, distributed with this repository under the project MIT notice. The image-generation service's current terms govern the generation process; no separate third-party stock license is being asserted. | Retain the project MIT notice and this provenance record when redistributing the repository. Do not present these files as physical-playthrough evidence or third-party stock. |
| Four staged in-engine PNG display derivatives and one finite visual-reference GIF | JasonTM17 and contributors | Captured from production Godot scenes through `tests/visual-capture-tour.tscn` on Godot 4.7.1 Compatibility/OpenGL 3.3, NVIDIA driver 581.08, and an NVIDIA GeForce RTX 3060 Laptop GPU. The immersive-copy refresh used the exact ignored source root `.artifacts/visual-capture-ui-polish-v2/`; that historical run contains seven artifact PNGs. The stable `.artifacts/visual-capture-current/` reproduction recipe saves eight artifact PNGs and a 1280×720, 12 fps AVI. Gameplay/player simulation and voice are disabled, and presentation states are selected directly. See [Documentation media curation](#documentation-media-curation) for exact deterministic processing, timing, and byte records. Source AVI, extra PNGs, palettes, and logs remain ignored under `.artifacts/`. | `docs/screenshots/room-407-lobby.png`<br>`docs/screenshots/room-407-bedroom.png`<br>`docs/screenshots/room-407-chase-entity.png`<br>`docs/screenshots/room-407-ending-reveal.png`<br>`docs/screenshots/room-407-gameplay-tour.gif`<br>`tests/visual-capture-tour.gd`<br>`tests/visual-capture-tour.tscn` | MIT; see `LICENSE` | Redistribution permitted under MIT. Retain the root copyright and permission notice. These are staged visual references, not a gameplay recording or physical/perceptual evidence; no pixel determinism or cross-hardware equivalence is claimed. |
| Primitive mesh classes, rendering/audio/navigation APIs, default UI theme/font behavior, and exported runtime | Godot Engine contributors and the authors of its third-party components | Godot 4.7.1 runtime defaults and built-in classes. No Godot editor, export template, exported executable, or external font file is committed. The tracked Windows x86_64 preset produces an ignored executable that embeds the project PCK; the verifier copies the project license, notice entry point, and full tag-pinned engine component inventory beside that local output. | `project.godot`<br>`export_presets.cfg`<br>`tests/verify-windows-export.ps1`<br>`THIRD_PARTY_NOTICES.md`<br>`GODOT_COPYRIGHT.txt` | Godot Engine MIT; bundled third-party components retain their own terms | Every redistributed binary must include the Godot copyright and MIT license text plus applicable third-party notices. The project MIT license does not relicense engine components. |

## Documentation media curation

The four reviewed 960×540 RGBA stills are deterministic documentation display derivatives of staged capture frames. ImageMagick 7.1.2-23 Q16-HDRI x64 (20260517) processed each with `-channel RGB -evaluate Pow 0.55 +channel -strip`, lifting RGB midtones/shadows without adding or removing scene content.

| Deliverable | Record |
|---|---|
| Stills | `room-407-lobby.png`, `room-407-bedroom.png`, `room-407-chase-entity.png`, and `room-407-ending-reveal.png`; combined 2,618,043 bytes |
| Tour GIF | 640×360; 59 frames with 29×12 cs and 30×13 cs delays (7.38 seconds); repackaged using `-coalesce -loop 1 -layers Optimize`; no `NETSCAPE2.0` loop extension, so it plays once |
| GIF source provenance | FFmpeg 8.1.1 visual montage using `palettegen=max_colors=96` and `paletteuse=dither=sierra2_4a`; FFmpeg did not rederive the current finite packaging |
| Committed docs media | Tour deliverables: 5,469,084 bytes; plus 999,431-byte repository cover: 6,468,515 bytes (6.17 MiB) |

## Generated image prompt record

The four `assets/images/` files were generated directly from these project briefs and then copied into the repository; the generated source files remain outside the repository's build tree:

- `menu-hotel-corridor.png` — “stylized cinematic horror-game main-menu background; empty decaying 2007 hotel corridor; burgundy wallpaper; door on the right; deep dark negative space on the left for UI; cold blue ceiling light and red emergency glow; no text, logos, watermark, people, faces, or gore.”
- `memory-photo-rabbit.png` — “aged found photograph of an empty hotel corridor with a small red stuffed rabbit; faded paper and singed edge; no people, faces, text, logo, watermark, or graphic gore.”
- `room-drawing-rabbit.png` — “aged cream paper with a naive crayon drawing of a red rabbit, dark corridor, doorway, and warm window; no words, numbers, logos, watermark, people, or gore.”
- `family-table-memory.png` — “faded found-photo still life of an abandoned family dinner table with four settings, one empty chair, and a red rabbit; no people, faces, text, logos, watermark, or graphic gore.”

These prompts describe the final accepted outputs; an earlier family-portrait prompt was rejected by the image safety filter and produced no project asset.

The documentation cover was generated from `assets/images/menu-hotel-corridor.png` as an edit target with this accepted prompt:

> Add a restrained cinematic title treatment in the existing dark negative space on the left. Render `ROOM 407` on the first line and `THE LAST SHIFT` on the second line exactly once in an original, condensed, weathered off-white horror-thriller treatment with a subtle muted-red accent. Preserve the 16:9 corridor framing, door placement, lighting, perspective, wallpaper, floor, and empty atmosphere. Keep the title inside the left half with generous safe margins. Add no other words, numbers, characters, people, faces, creatures, logos, trademarks, gore, border, mockup frame, or watermark.

## License Scope

The root `LICENSE` applies to this project's code and project-authored assets, including the distributed generated cue files. It does not replace, absorb, or relicense Godot Engine's copyright, MIT notice, or third-party notices. Piper and the voice model are local build inputs, not redistributed dependencies; their own licenses still govern those local copies.

This repository tracks source, a credential-free Windows x86_64 export preset, and redistribution notices; it does not commit the generated executable or Godot export templates. The local verifier copies `LICENSE`, `THIRD_PARTY_NOTICES.md`, and the exact tag-pinned `GODOT_COPYRIGHT.txt` inventory beside its ignored build output. Any redistributed binary must retain the notices required for the bundled Godot Engine copy and applicable engine third-party components. The official Godot license guidance states that a distributed engine binary remains a copy of Godot Engine even when the game content uses a different license.

For the public `v0.9.0` portable Windows ZIP, retain those notice files beside
`ROOM_407_THE_LAST_SHIFT.exe` and publish the ZIP's SHA-256 in the named release checksum
record. The package is unsigned and becomes available only when its two assets appear on
the [GitHub Release page](https://github.com/JasonTM17/Horror_Game_Funny/releases/tag/v0.9.0).
The GHCR image is a headless test package, not a redistribution of the playable Windows
archive. See [Release v0.9.0](release-v0.9.0.md).

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
- [Third-party notices](../THIRD_PARTY_NOTICES.md)
- [Godot 4.7.1 copyright and component licenses](../GODOT_COPYRIGHT.txt)
- [`export_presets.cfg`](../export_presets.cfg)
- [`verify-windows-export.ps1`](../tests/verify-windows-export.ps1)
- [`icon.svg`](../icon.svg)
- [`retro-screen-overlay.gdshader`](../shaders/retro-screen-overlay.gdshader)
- [`visual-effects-layer.gd`](../scripts/ui/visual-effects-layer.gd)
- [`audio-manager.gd`](../scripts/autoload/audio-manager.gd)
- [`voice-over-player.gd`](../scripts/audio/voice-over-player.gd)
- [`voice-over-manifest.json`](../assets/audio/voice-over/voice-over-manifest.json)
- [`generate-voice-over.ps1`](../tools/generate-voice-over.ps1)
- [`visual-capture-tour.gd`](../tests/visual-capture-tour.gd)
- [`visual-capture-tour.tscn`](../tests/visual-capture-tour.tscn)
- [Visual-reference montage](./screenshots/room-407-gameplay-tour.gif)
- [Repository cover](./media/room-407-cover.png)
- [`level-geometry.gd`](../scripts/world/level-geometry.gd)
- [Piper voice repository](https://github.com/rhasspy/piper-voices)
- [`en_US-kristin-medium` model card](https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_US/kristin/medium/MODEL_CARD)
- [Piper build tool](https://github.com/OHF-Voice/piper1-gpl)
- [Godot Engine license](https://godotengine.org/license/)
- [Known limitations](limitations.md)
- [Release v0.9.0](release-v0.9.0.md)
- [Vietnamese guide](vi/README.md)
