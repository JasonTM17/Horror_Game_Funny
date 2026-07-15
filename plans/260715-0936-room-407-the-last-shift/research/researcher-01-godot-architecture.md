---
type: researcher
date: 2026-07-15
---

# Research Report: Godot Architecture and Verification

## Summary

Build a scene-based Godot 4.7.1 project with four thin autoloads, local level controllers, signal-driven progression, and text-authored procedural environments. Use the Compatibility renderer and self-contained portable editor on D:. This is the smallest architecture that supports clean checkpoint resets, a dynamic hallway, automated headless checks, and a complete 15–20 minute flow.

## Scope and Evidence

- Primary specification: user-provided Room 407 brief.
- Current repository: empty remote and no local game code.
- Target engine: Godot 4.7.1 stable, Windows x86_64, GDScript.
- Hardware goal: student-class PCs; no advanced renderer feature is required.
- Storage constraint: C: critically low; runtime, editor data, logs, and temporary files must stay on D: where controllable.

## Options Evaluated

| Option | Complexity | Runtime cost | Maintainability | Decision |
|---|---:|---:|---:|---|
| One player script + monolithic level director | Low initially | Low | Poor; checkpoint and event coupling becomes fragile | Reject |
| Scene composition + thin autoloads + local controllers/signals | Medium | Low | Strong boundaries; testable state and reset logic | Select |
| Resource-authored event graph and generic ECS-like components | High | Medium authoring overhead | Flexible but excessive for a 20-minute game | Reject |

The selected option avoids a god object without building a framework larger than the game.

## Recommended Architecture

### Global Services

| Autoload | Owns | Must not own |
|---|---|---|
| `GameState` | progression stage, flags, objective ID, lightweight inventory, memory count, checkpoint snapshot | level nodes, animations, enemy instances |
| `SceneRouter` | fade-safe scene changes and current scene identity | puzzle decisions or story rules |
| `AudioManager` | audio buses, cached procedural streams, ambience and one-shots | level progression |
| `SettingsManager` | bounded settings, persistence, accessibility signals | HUD or player node references |

All services expose typed methods and signals. Level scenes connect on entry and disconnect with the scene tree.

### Progression

Use a typed enum with monotonic story stages:

`LOBBY -> FLOOR4_DARK -> FLOOR4_POWERED -> MEMORY_LOOP -> ROOM_407 -> CHASE -> ENDING`

Flags represent idempotent facts such as `phone_answered`, `fuse_installed`, `memory_photo`, `memory_tape`, and `memory_toy`. Advancing a stage requires explicit prerequisites. Repeated or out-of-order interaction returns a stable result and never replays a one-shot event.

Checkpoint snapshots contain only serializable gameplay state: scene path, spawn marker, stage, flags, inventory, objective, and event IDs. Reloading replaces the gameplay scene, then restores state before enabling player input. This prevents duplicate enemies, stacked audio loops, and stale HUD state.

### Scene Boundaries

- `Boot`: load settings, configure buses, route to menu.
- `MainMenu`: start, continue when an in-memory checkpoint exists, settings, quit.
- `Lobby`: tutorial interactions, phone call, duty key, environmental story.
- `Floor4`: dark hallway, fuse puzzle, first apparition.
- `MemoryHallway`: three controlled variants, three memory items, radio/code puzzle.
- `Room407`: impossible-space reveal and final clue.
- `Chase`: enemy navigation state machine, fail state, checkpoint restore.
- `Ending`: in-engine reveal, credits, replay.

Reusable scenes cover player, door, pickup, note, fuse box, puzzle input, horror trigger, silhouette, checkpoint trigger, and HUD.

### Local Systems

- `PlayerController`: movement only; delegates look, head bob, flashlight, and interaction ray to child components.
- `Interactable`: typed base class with prompt, cooldown, enabled state, and `interact(actor)` result.
- `HorrorEventDirector`: receives event IDs from trigger nodes; checks flags and one-shot history; invokes local event nodes. It never lives in the player.
- `HallwayController`: owns variant visibility, transition markers, room labels, and safe teleport orientation.
- `EnemyController`: explicit `DORMANT/APPEAR/STALK/SEARCH/CHASE/LOST_TARGET/DESPAWN` states. Only chase requires active navigation.
- `LevelGeometry`: creates low-poly primitives, collision, lamps, doors, props, and cold procedural materials from deterministic helpers.

## Rendering and Assets

- Set `rendering_method = "gl_compatibility"` and use modest shadow distances.
- Use WorldEnvironment fog/color adjustment where supported by Compatibility; avoid compute, screen-space reflections, volumetrics, and heavy post-processing.
- Use a low-resolution viewport stretch, one lightweight canvas shader for optional grain/dither, and accessibility toggles.
- Build geometry from BoxMesh, CylinderMesh, PlaneMesh, and simple materials. Generate short audio buffers once and cache them as `AudioStreamWAV` resources in memory.
- Keep dynamic shadowed lights sparse: flashlight plus a small number of active room lights. Hallway variants disable unused nodes.

## Test Seams

| Area | Automated seam | Manual evidence |
|---|---|---|
| Script and scene validity | headless editor import/quit | open project in editor |
| Progression | pure `GameState` prerequisite tests | full playthrough |
| Interaction spam | deterministic cooldown/idempotency tests | rapid key input |
| Door state | instantiate scene and assert lock/open transitions | collision walk-through |
| Puzzles | direct wrong/right input tests | clue readability |
| Events | repeat trigger and assert one execution | turn-away apparition |
| Checkpoint | snapshot, mutate, restore, assert state | die during chase |
| Settings | clamp, save/load, bus application | menu adjustment |
| Ending gate | reject incomplete flags; accept complete state | 15–20 minute timing |

Recommended commands after the portable editor exists:

```powershell
& $Godot --version
& $Godot --headless --path D:\Horror_Game --editor --quit --log-file D:\Horror_Game\.artifacts\editor-import.log
& $Godot --headless --path D:\Horror_Game --script res://tests/run-tests.gd --log-file D:\Horror_Game\.artifacts\tests.log
& $Godot --headless --path D:\Horror_Game --quit-after 600 -- --smoke-test
```

The editor command validates imports and parses referenced scripts/scenes. A custom `SceneTree` test runner provides behavioral assertions without a third-party plugin.

## Portable Toolchain

Download the official Windows x86_64 ZIP into `D:\Tools\Godot-4.7.1`, extract it there, and create `_sc_` beside the editor executable before first launch. Godot then keeps editor config/data/cache under adjacent `editor_data`. Also set `TEMP` and `TMP` to a D:-resident temporary folder for all commands and write logs inside the workspace.

Do not commit the editor binary, `_sc_`, editor data, generated import cache, test logs, or exports.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| C: reaches zero during extraction/import | system and editor instability | self-contained editor, D:-resident TEMP/TMP, disk check before every heavy operation |
| Text-authored `.tscn` path/case mistakes | Linux clone fails or scenes do not load | lower-case paths, preload checks, headless import on every milestone |
| Checkpoint reload duplicates state | chase soft-lock | snapshot plain data, replace scene, idempotent event IDs |
| Procedural content looks empty | weak atmosphere | deterministic prop clusters, lighting landmarks, readable story staging |
| Compatibility renderer feature mismatch | visual regressions | restrict shaders/materials to supported basics; verify in target renderer |

## Sources

- Godot 4.7.1 Windows download: https://godotengine.org/download/windows/
- Official release archive: https://godotengine.org/download/archive/
- Command-line reference: https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
- Renderer comparison: https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html
- Self-contained editor behavior: https://docs.godotengine.org/en/4.4/classes/class_editorpaths.html

## Unresolved Questions

- None. The brief fixes scope, platform, engine family, pacing, and required features.
