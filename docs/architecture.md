# Architecture

## Overview

ROOM 407 uses scene composition, typed GDScript, thin global services, and local level controllers. This document defines the implementation contract; it is updated as each phase lands so it never presents planned code as already verified.

Current verified baseline: Godot 4.7.1 recognizes the project, imports the icon, and loads `scenes/boot/boot.tscn` through the Compatibility renderer.

## Scene Flow

```text
Boot
└── Main Menu
    └── Lobby
        └── Floor 4
            └── Memory Hallway
                └── Room 407
                    └── Chase Hallway
                        └── Ending / Credits
```

Reusable scenes provide the player, HUD, doors, pickups, notes, puzzle controls, event triggers, apparition, checkpoint trigger, and entity.

## Global Services

Four planned autoloads have narrow ownership:

| Service | Owns | Excludes |
|---|---|---|
| `GameState` | story stage, flags, inventory, objective, completed events, checkpoint snapshot | scene nodes and animations |
| `SceneRouter` | serialized fade-safe scene replacement and spawn marker | story decisions |
| `AudioManager` | buses, cached procedural streams, named loops and one-shots | progression |
| `SettingsManager` | bounded settings and persistence | player/HUD references |

An autoload must not search arbitrary scene descendants or become a general-purpose service locator.

## Data Flow

```text
Player ray
  -> Interactable.interact(actor)
  -> guarded local action
  -> GameState flag/item/stage update
  -> typed signal
  -> HUD / level controller / event director response
```

Prompt lookup is read-only. Story mutations are idempotent. Level controllers subscribe on entry and disappear with their scene.

## Progression State

The story stage is monotonic:

```text
LOBBY
  -> FLOOR4_DARK
  -> FLOOR4_POWERED
  -> MEMORY_LOOP
  -> ROOM_407
  -> CHASE
  -> ENDING
```

Flags record facts such as `phone_answered`, `fuse_installed`, memory IDs, `radio_solved`, and `final_clue_seen`. A gate checks prerequisites before it mutates state. Display strings never serve as identifiers.

## Player Composition

`CharacterBody3D` owns physics movement and delegates:

- look and bounded pitch;
- head bob and comfort toggle;
- flashlight state;
- interaction ray and prompt;
- input-lock reasons for notes, cinematics, failure, and menus.

Movement uses `_physics_process(delta)`, normalized input, cached nodes, and a bounded sprint multiplier.

## Interaction Contract

The base interactable exposes typed prompt and interaction methods, an enabled state, maximum distance, and cooldown. Specialized implementations include doors, pickups, phone, notes, fuse box, radio input, exits, and ending gates.

Door state is explicit: closed, opening, open, closing, or locked. A door owns one active tween and cannot start another transition until it reaches a stable state.

## Horror Events

`HorrorEventDirector` is local to a level. Trigger nodes submit stable event IDs. The director checks required flags and completed-event history before invoking an authored event node. Events control lights, sound, props, doors, silhouettes, hallway variants, and chase activation without coupling to the player controller.

## Dynamic Hallway

One scene contains three disabled-by-default variant roots. The controller:

1. waits until a vestibule blocks sight;
2. moves the player to a named safe marker;
3. activates the next variant and disables the previous one;
4. prevents a second transition until the player exits the trigger;
5. falls back to the latest safe marker if the player leaves the map.

Inactive variants disable processing, lights, and audio.

## Checkpoint Flow

The snapshot contains only serializable data:

- scene path and spawn ID;
- story stage and objective;
- flags, inventory, and completed events;
- hallway variant and chase prerequisites.

On capture, input locks once, chase audio stops, the fade completes, `SceneRouter` replaces the scene, and `GameState` restores before input is enabled. Scene nodes and enemy instances are never stored in the snapshot.

## Enemy State Machine

The entity uses explicit allowed transitions. Navigation activates only in the chase scene and waits for the navigation map to become ready. A bounded waypoint fallback prevents progression from freezing if navigation initialization times out; it is not an unrestricted teleport.

## Audio and Visual Budget

- Compatibility renderer only.
- Flashlight plus a small number of active shadowed lights.
- One optional single-pass grain/dither shader.
- Procedural mono PCM cache under 16 MiB.
- No per-frame global node search.
- No active navigation agent outside the climax.

## Testing Strategy

- Headless editor import catches resource and parse failures.
- Native `SceneTree` tests cover state, guards, puzzles, checkpoint serialization, and settings.
- A test-only smoke runner loads production scenes and uses public gates.
- Manual playthroughs verify collision, navigation, lighting, audio, comfort, and pacing.

## Extension Rules

### Add an Item

Create a stable lowercase ID, add an interactable scene, and update only the gate that consumes it. Add duplicate-pickup and checkpoint tests.

### Add a Horror Event

Create a local event node with a unique event ID and explicit prerequisites. Do not add event logic to the player.

### Add a Hallway Variant

Compose it under the hallway scene, define entry/exit safe markers, disable inactive processing, and add transition-spam coverage.

### Add a Puzzle

Keep its input model local, publish one solved flag, provide wrong-state feedback and an environmental hint, and test both early and repeated submission.
