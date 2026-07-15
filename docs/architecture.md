# Architecture

## Overview

ROOM 407 uses one boot scene, one continuous gameplay scene, typed GDScript controllers, four autoload services, procedural world construction, and composed UI scenes. The configured runtime is Godot 4.7.1 using the Compatibility renderer.

The gameplay scene file contains only a `Node3D` with `GameplayDirector`. At runtime, the facade builds the corridor, navigation region, story interactables, player, UI, events, hallway variants, progression controller, and chase controller.

## Runtime Flow

```text
F5 / project start
  -> boot.tscn
  -> START SHIFT or process-local CONTINUE CHECKPOINT
  -> gameplay.tscn
       -> continuous lobby / floor 4 / memory loop / Room 407 / chase
       -> abandoned-lobby reveal and ending overlay in the same scene
       -> replay gameplay or return to boot
```

F6 is editor current-scene execution and can skip the boot scene. The memory loop never changes gameplay scenes: `HallwayTransitionLayer` fades to black, invokes a midpoint hallway swap/reposition, waits, and fades back in.

## Gameplay Controller Split

| Component | Current responsibility |
|---|---|
| `GameplayDirector` | Runtime facade; assembles the scene, spawns player/UI, watches zone boundaries, and delegates public story/chase calls |
| `StoryProgressionController` | Interaction prompts, story guards, inventory/flags, narrative completion, memory-loop transitions, radio/note UI, checkpoints, and ending prerequisites |
| `ChaseSequenceController` | Entity creation, chase start, corridor-light failure, capture recovery, abandoned-lobby reveal, and ending overlay |
| `DynamicHallwayController` | Four visibility-switched corridor variants and memory-driven dressing changes |
| `HorrorEventDirector` | Idempotent, local visual/audio events and apparitions |
| `NarrativeSequencer` | Timed subtitle lines and completion flags |

`GameplayDirector` exposes a small facade (`get_story_prompt`, `handle_story_action`, `on_radio_solved`, `on_note_closed`, `fail_chase`, and `finish_ending`) so interactables and UI do not need direct references to the specialized controllers.

## World Construction

`ContinuousWorldBuilder` creates the shared environment, 870-unit corridor shell, partitions, Room 407 dressing, lights, guide lights, and navigation region. `ContinuousStoryLayout` creates the story objects and guarded doors. `LevelGeometry` is the low-level box, label, material, and light factory.

The navigation surface is a real `NavigationRegion3D` named `ContinuousCorridorNavigation`. Its `NavigationMesh` contains a four-vertex polygon spanning the playable corridor. This is created directly in code rather than baked from imported meshes.

## Global Services

| Service | Owns | Persistence |
|---|---|---|
| `GameState` | stage, objective, subtitle, inventory, flags, completed events, checkpoint dictionary, pending spawn ID | memory only |
| `SceneRouter` | serialized scene replacement and checkpoint scene reload | none |
| `AudioManager` | runtime buses, procedural PCM cache, named tones and drones | none |
| `SettingsManager` | bounded controls/display/audio/comfort values and config I/O | `user://room407.cfg` |

Autoloads do not own scene nodes or story choreography. `AudioManager` creates missing Music, SFX, Ambience, and Chase buses during startup; Master is Godot's existing bus.

## Interaction and Progression Data Flow

```text
Player interaction ray
  -> StoryInteractable / DoorInteractable
  -> GameplayDirector facade
  -> StoryProgressionController guard
  -> GameState item, flag, stage, objective, or subtitle mutation
  -> signals consumed by HUD and narrative/event controllers
```

Prompt lookup is read-only. Mutating actions guard prerequisites first. Story stages are monotonic:

```text
LOBBY
  -> FLOOR4_DARK
  -> FLOOR4_POWERED
  -> MEMORY_LOOP
  -> ROOM_407
  -> CHASE
  -> ENDING
```

Stable lowercase IDs, not display text, identify flags, inventory items, and completed events.

## Hidden Hallway Transitions

`HallwayTransitionLayer` owns a full-screen black curtain and one transition lock. During a transition it:

1. locks the player with the `hallway` reason;
2. fades the curtain to opaque;
3. calls the supplied midpoint action;
4. swaps the hallway variant and optionally moves the actor to `MEMORY_START_Z`;
5. plays the blackout tone and holds the blackout;
6. fades out the curtain and unlocks the player.

The first two memories loop the actor to the memory start. The third memory swaps to the final variant, disables the loop gate, and opens radio progression without teleporting the actor.

## Player Composition

The `CharacterBody3D` player owns movement, bounded look pitch, pause input, input-lock reasons, head bob, camera shake, flashlight visibility, and settings application. A child interaction node owns the 2.5-unit ray and calls interactable contracts.

The scene overrides movement defaults to walk speed 2.0 and sprint multiplier 1.55, producing sprint speed 3.1. Movement uses `_physics_process`, normalized input, acceleration toward target velocity, gravity, and `move_and_slide()`.

## Enemy and Navigation

`ChaseSequenceController` creates one entity at chase start and attaches a capsule mesh/collider. The entity creates a `NavigationAgent3D` during setup and uses these states:

```text
DORMANT -> APPEAR -> STALK -> CHASE -> LOST_TARGET -> SEARCH -> CHASE
any active state -------------------------------------------------> DESPAWN
```

When the navigation map is ready, the agent supplies the next path point. Before that, motion falls back to the current target or last visible target vector; it is not a separate waypoint system. Line of sight is sampled every 0.2 seconds. The entity is confined by corridor Z bounds and requests failure within 1.25 units of the player.

Entity speed is 3.0. The configured player walks at 2.0 and sprints at 3.1. Automated checks assert this ordering and the `STALK` transition, but manual traversal is required to validate navigation quality and human fairness.

## Chase, Checkpoint, and Ending Flow

At chase readiness, `GameState` captures serializable values and spawn ID `chase_start`. Chase start dims named corridor lights, creates one entity, starts chase audio, and advances the stage.

Capture recovery happens inside the existing gameplay scene. It restores the checkpoint dictionary, resets the existing player and entity positions, restarts the entity and chase drone, and releases the fail lock. It does not serialize nodes, reload the gameplay scene, or create a replacement enemy.

The boot menu's Continue path is different: when a checkpoint exists in the current process, it calls `SceneRouter.reload_checkpoint()`, which restores state and reloads the snapshot's scene path. During story-controller setup, completed memory flags derive the active hallway variant before control returns to the player. Because `GameState` is not written to disk, Continue disappears after application restart.

Ending success remains in the gameplay scene. The chase controller stops the entity/audio, builds abandoned-lobby geometry and labels near the player, locks input, holds a three-second observation window, and then instantiates `ending-overlay.tscn`. Replay and Main Menu perform explicit scene changes.

## Settings and Audio

`SettingsManager` clamps values at the service boundary and applies audio levels to named buses. `settings-panel.gd` reads current values on construction, updates them immediately, and saves the full config when the panel closes.

`AudioManager` creates 16-bit, 22,050 Hz mono PCM tones and caps cached sample data at 16 MiB. `stop_all()` stops streams, clears cache/accounting, and queues player nodes for safe end-of-frame release. Drones are skipped under the headless display server, so a successful headless call does not prove audible output.

`VisualEffectsLayer` applies the project-authored canvas shader and toggles the overlay from `film_grain_enabled`. Flashlight flicker, head bob, and camera shake read their settings at runtime.

## Verification Boundaries

The ten-check headless runner verifies import, scene loading, state snapshots, guarded progression, radio cooldown across close/reopen, layout/door/navigation invariants, targeted production-player movement and door collision, restored hallway variants, chase state/speed ordering and retreat recovery, failure recovery, staged ending success, settings controls/clamps, buses, pause Settings/Escape, audio teardown, in-memory Continue visibility, and settings persistence across two Godot processes.

It synthesizes `move_forward` for focused capsule/collision checks, but it does not generate a complete physical keyboard/mouse playthrough or verify monitor output, audible output, lighting/audio balance, the physical Settings UI workflow, or 15–20 minute pacing. These require the manual matrix in `testing.md`.

## References

- [`gameplay.tscn`](../scenes/gameplay/gameplay.tscn)
- [`gameplay-director.gd`](../scripts/world/gameplay-director.gd)
- [`story-progression-controller.gd`](../scripts/world/story-progression-controller.gd)
- [`chase-sequence-controller.gd`](../scripts/world/chase-sequence-controller.gd)
- [`continuous-world-builder.gd`](../scripts/world/continuous-world-builder.gd)
- [`hallway-transition-layer.gd`](../scripts/ui/hallway-transition-layer.gd)
- [`game-state.gd`](../scripts/autoload/game-state.gd)
- [`settings-manager.gd`](../scripts/autoload/settings-manager.gd)
- [Testing matrix](testing.md)
