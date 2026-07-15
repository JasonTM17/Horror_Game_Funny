---
phase: 3
title: Lobby and Fuse Vertical Slice
status: completed
priority: P1
dependencies:
  - 2
effort: large
---

# Phase 3: Lobby and Fuse Vertical Slice

## Overview

Build the opening lobby-to-powered-floor slice inside the same continuous gameplay scene: phone mission, duty key, fourth-floor gate, fuse pickup/installation, and first one-shot horror events.

## Context Links

- [Plan](./plan.md)
- [Pacing research](./research/researcher-02-game-design-and-qa.md)

## Requirements

- Environmental onboarding with no modal tutorial wall.
- Phone subtitles, duty note, key gate, fourth-floor transition.
- Fuse puzzle with wrong-order feedback, one-time consume/update/event behavior.
- Door slam and distant silhouette events controlled outside the player.

## Architecture

Lobby and Floor4 are continuous zones assembled by the world/story builders. A scene-local `HorrorEventDirector` consumes stable trigger IDs; progression uses explicit prerequisites in `GameState`. No level scene change occurs between these beats.

## File Inventory

| Action | Paths | Rough size | Test impact |
|---|---|---:|---|
| Create | `scenes/levels/{lobby,floor4}.tscn` | text scenes | main-flow load |
| Create | `scripts/levels/{lobby-controller,floor4-controller}.gd` | <400 lines total | stage tests |
| Create | `scripts/world/{apartment-builder,prop-factory}.gd` | <400 lines total | geometry smoke |
| Create | `scripts/interaction/{phone,note,scene-exit}.gd` + scenes | <450 lines total | interaction tests |
| Create | `scripts/puzzles/fuse-box.gd`, `scenes/puzzles/fuse-box.tscn` | <230 lines | puzzle tests |
| Create | `scripts/events/{horror-event-director,event-trigger,apparition}.gd` + scenes | <450 lines total | one-shot tests |
| Modify | menu start path, project main flow | small | end-to-end smoke |

## Function and Interface Checklist

- [x] Phone call sets one flag and subtitle sequence on first use.
- [x] Floor exit requires the duty key earned from the guarded phone/logbook flow; locked feedback is explicit.
- [x] Fuse box requires/consumes `spare_fuse`, sets stage, powers selected nodes, and triggers one event.
- [x] Event director rejects repeated event IDs.
- [x] Authored partitions, walls, floor, and ceiling keep the player inside the continuous route.

## Dependency Map

`Phase 2 interaction/state -> Lobby -> floor transition -> Floor4 -> fuse/event director -> Phase 4`

## Implementation Steps

1. Build deterministic low-poly lobby with desk, phone, log, key, exit, landmarks, and collision.
2. Author phone/subtitle/tutorial flow and gate the floor transition.
3. Build stair/elevator transition and dark fourth-floor base environment.
4. Add fuse pickup/drawer clue and guarded fuse box state machine.
5. Add event director, door slam, light change, and distant silhouette.
6. Add objectives/subtitles and safe recovery markers.
7. Time a manual vertical-slice playthrough; adjust navigation density toward 5–7 minutes.
8. Run headless/focused tests and commit level then puzzle/events separately.

## Atomic Commit Checkpoints

- `feat: build lobby tutorial and fourth-floor transition`
- `feat: add fuse puzzle and first horror events`

## Test Scenario Matrix

| Priority | Scenario | Expected |
|---|---|---|
| Critical | Exit lobby before phone/key | denied with correct feedback |
| Critical | Fuse interact before/after pickup | no consume early; exactly one consume later |
| High | Re-enter event areas | no duplicate slam/silhouette/audio |
| High | Fall/out-of-bounds | recover at safe marker |
| Medium | Full slice timing | 5–7 minutes for first-time route |

## Success Criteria

- [x] Menu starts the lobby and automated guarded progression reaches powered Floor4 without a production bypass.
- [x] Fuse puzzle and first horror events resist the covered duplicate/out-of-order cases.
- [x] Objectives/subtitles provide control and story guidance.
- [x] Collision layout, lighting nodes, and scene load pass headless checks.
- [ ] Manual full traversal confirms collision feel, lighting readability, and opening-slice timing.
- [x] Focused commits pass checks and disk remains above the safety floor.

## Risks and Mitigation

| Risk | Mitigation |
|---|---|
| Procedural room feels empty | repeatable prop clusters, signage, color/lighting landmarks |
| Player misses fuse | layered note, unpowered lamp, objective fallback |
| Event triggers through walls | bounded Area3D and line-of-sight staging |

## Security and Licensing

All meshes/materials/text are project-created. No external phone/radio audio.

## Next Steps

- Phase 4 extends Floor4 into the controlled memory loop and second puzzle.
