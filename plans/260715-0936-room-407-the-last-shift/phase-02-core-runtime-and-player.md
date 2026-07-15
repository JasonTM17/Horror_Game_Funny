---
phase: 2
title: Core Runtime and Player
status: completed
priority: P1
dependencies:
  - 1
effort: large
---

# Phase 2: Core Runtime and Player

## Overview

Implement the boot/menu path, typed global services, first-person controller, reusable interaction contract, doors, inventory/objectives, HUD, pause, and a deterministic continuous gameplay test room.

## Context Links

- [Plan](./plan.md)
- [Architecture research](./research/researcher-01-godot-architecture.md)

## Requirements

- Normalized WASD, mouse look, sprint, gravity, collision, head bob toggle, footsteps, flashlight, ray interaction, and input locking.
- Prompt/cooldown/enabled/feedback contract for all interactables.
- Idempotent flags/inventory/objectives and bounded settings.
- Start, settings, quit, pause/resume, and input/mouse capture recovery.

## Architecture

Four typed autoloads own global data/routing/audio/settings. Player behavior is split into movement, view, flashlight, and interaction components. `Interactable` defines a typed result; doors and pickups extend it. HUD subscribes to signals rather than polling global nodes every frame.

## File Inventory

| Action | Paths | Rough size | Test impact |
|---|---|---:|---|
| Create | `scripts/autoload/{game-state,scene-router,audio-manager,settings-manager}.gd` | <700 lines total | global logic tests |
| Create | `scripts/player/{player-controller,player-look,player-interaction,player-flashlight}.gd` | <650 lines total | movement/input tests |
| Create | `scripts/interaction/{interactable,door-interactable,pickup-interactable}.gd` | <450 lines total | state/idempotency tests |
| Create | `scripts/ui/{main-menu,hud,pause-menu,settings-panel}.gd` | <600 lines total | menu/settings tests |
| Create | `scenes/{boot,menus,player,interactables,ui}/**/*.tscn` | text scenes | load tests |
| Create | `scripts/world/level-geometry.gd`, `scenes/tests/developer-room.tscn` | <250 lines | integration seam |
| Modify | `project.godot` | small | autoload/input/main scene |

## Function and Interface Checklist

- [x] `GameState.reset_run/add_item/consume_item/set_flag/set_objective/create_checkpoint/restore_checkpoint` are typed and idempotent.
- [x] `SceneRouter.change_scene(path, spawn_id)` serializes scene replacement and spawn selection.
- [x] `Interactable.get_prompt(actor)` and `interact(actor)` never mutate on prompt lookup.
- [x] `PlayerController.set_input_locked(reason, locked)` composes pause/settings/note/hallway/fail/ending locks.
- [x] Settings clamp sensitivity/FOV/volume/flicker before applying.

## Dependency Map

`Phase 1 -> autoloads -> menu/boot -> player components -> interactables -> HUD/continuous test room -> Phase 3`

## Implementation Steps

1. Add typed state/settings/audio/routing services and register autoloads.
2. Create boot, main menu, shared fade layer, HUD, pause, and settings panel.
3. Implement composed first-person player and input lock/mouse capture rules.
4. Implement base interactable, pickup, and tween-safe door states.
5. Connect inventory/objective/prompt signals to HUD.
6. Build a small developer room to exercise movement, door, pickup, pause, and scene reload.
7. Run import, scene-load, state tests, and manual controller checks.
8. Commit runtime/player and interaction/UI as two atomic groups.

## Atomic Commit Checkpoints

- `feat: add runtime services menu and player foundation`
- `feat: add reusable interaction doors and objective HUD`

## Test Scenario Matrix

| Priority | Scenario | Expected |
|---|---|---|
| Critical | Start game/menu transition | correct scene; input captured once |
| Critical | Diagonal+sprint movement | bounded normalized speed |
| High | Spam door/pickup interaction | one tween/item/event |
| High | Pause/note lock then resume | player and mouse input restored |
| Medium | Extreme settings values | clamped and applied to buses/player |

## Success Criteria

- [x] Menu launches the continuous gameplay scene and pause/settings load successfully.
- [x] Player controller implements normalized movement, look, sprint, flashlight, and interaction without per-frame discovery lookups.
- [x] Doors/pickups are reusable and idempotent.
- [x] HUD reflects objective, inventory, prompt, and subtitle state.
- [x] Headless import and focused automated tests pass.

## Risks and Mitigation

| Risk | Mitigation |
|---|---|
| Autoload becomes god object | keep scene nodes/animations out; typed narrow API |
| Mouse remains captured in menus | centralize capture state in player/menu transitions |
| Door collision traps player | fixed hinge direction, interaction guard, collision manual test |

## Security and Licensing

Settings file contains no sensitive data. UI uses Godot default font/theme and authored vector shapes.

## Next Steps

- Phase 3 replaces the developer room as the start of the authored game flow.
