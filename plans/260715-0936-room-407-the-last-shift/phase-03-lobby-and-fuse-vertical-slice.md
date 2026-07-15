---
phase: 3
title: Lobby and Fuse Vertical Slice
status: in-progress
priority: P1
dependencies:
  - 2
effort: large
---

# Phase 3: Lobby and Fuse Vertical Slice

## Overview

Build the first 5–7 playable minutes: lobby tutorial, phone mission, duty key, stair/elevator transition, dark fourth floor, fuse pickup/installation, first one-shot horror events, and checkpoint-ready state.

## Context Links

- [Plan](./plan.md)
- [Pacing research](./research/researcher-02-game-design-and-qa.md)

## Requirements

- Environmental onboarding with no modal tutorial wall.
- Phone subtitles, duty note, key gate, fourth-floor transition.
- Fuse puzzle with wrong-order feedback, one-time consume/update/event behavior.
- Door slam and distant silhouette events controlled outside the player.

## Architecture

Lobby and Floor4 are separate scenes composed from procedural apartment geometry and reusable interactions. Local `HorrorEventDirector` consumes trigger IDs and delegates to scene event nodes. Progression uses explicit prerequisites in `GameState`.

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

- [ ] Phone call sets one flag and subtitle sequence on first use.
- [ ] Floor exit requires phone + duty key; locked feedback is explicit.
- [ ] Fuse box requires/consumes `fuse`, sets stage, powers selected nodes, triggers one event.
- [ ] Event director rejects unmet/out-of-order/repeated event IDs.
- [ ] Recovery area returns player to latest safe marker.

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

- [ ] Menu starts a polished lobby and reaches powered Floor4 without debug actions.
- [ ] Fuse puzzle and first horror events cannot repeat or soft-lock.
- [ ] Objectives/subtitles teach controls and story naturally.
- [ ] Collision, lighting, scene loads, and recovery work headlessly/manually.
- [ ] Two focused commits pass checks and disk remains above safety floor.

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
