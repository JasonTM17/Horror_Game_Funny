---
phase: 5
title: Room 407 Chase and Ending
status: completed
priority: P1
dependencies:
  - 4
effort: large
---

# Phase 5: Room 407 Chase and Ending

## Overview

Complete the main path with the impossible Room 407 reveal, final clue, an in-memory checkpoint, explicit enemy state machine, bounded chase, capture/recovery, ending reveal, credits, and replay inside the same continuous gameplay scene.

## Context Links

- [Plan](./plan.md)
- [Architecture research](./research/researcher-01-godot-architecture.md)
- [Pacing and QA research](./research/researcher-02-game-design-and-qa.md)

## Requirements

- Room 407 is larger inside, readable, and quiet before the entity reveal.
- Enemy states: dormant, appear, stalk, search, chase, lost target, despawn.
- Checkpoints before Room407/final clue and chase; capture restores exact run state with one enemy/audio loop.
- Ending rejects incomplete progression, reveals the abandoned building, shows credits and replay.

## Architecture

Room407 and Chase are continuous zones in `gameplay.tscn`. Checkpoint snapshot is
plain data owned by `GameState`; recovery resets the player to a safe marker without
breaking the night-shift flow. Enemy state changes are explicit and navigation is
active only in chase. Ending is an authored in-world sequence, not a video file.

## File Inventory

| Action | Paths | Rough size | Test impact |
|---|---|---:|---|
| Create | `scenes/levels/{room-407,chase-hallway,ending}.tscn` | text scenes | complete-flow load |
| Create | `scripts/levels/{room-407-controller,chase-controller,ending-controller}.gd` | <520 lines total | gate/smoke tests |
| Create | `scripts/enemy/{enemy-controller,enemy-vision,enemy-navigation}.gd` | <550 lines total | FSM tests |
| Create | `scenes/enemy/entity.tscn` | text scene | spawn/capture tests |
| Create | `scripts/save/checkpoint-trigger.gd`, `scripts/ui/fail-overlay.gd` + scenes | <350 lines | reset tests |
| Create | `scripts/interaction/ending-exit.gd`, `scenes/ui/credits.tscn` | <220 lines | ending gate tests |
| Modify | `GameState`, `SceneRouter`, HUD/audio hooks | <200 lines | checkpoint contract |

## Function and Interface Checklist

- [x] Snapshot/restore deep-copies flags, inventory, objective, stage, scene, spawn, completed events.
- [x] Continue restores state before rebuilding the gameplay scene; capture recovery restores in place and reuses the existing entity.
- [x] Enemy transition table rejects illegal transitions and remains bounded to the authored chase route.
- [x] Chase checks navigation-map iteration before requesting path points and falls back to bounded direct/last-seen steering.
- [ ] Manual trace proves the entity can traverse every chase corner and cannot enter closed-door collision.
- [x] Capture locks input once, stops chase audio/entity, shows fail fade, restores the checkpoint in place, and restarts one entity.
- [x] Ending gate requires all memories, radio solved, room recording/drawing, final clue, and chase started.

## Dependency Map

`Room407 gate -> room checkpoint -> final clue -> chase checkpoint -> enemy FSM -> capture/reload OR exit -> ending/credits`

## Implementation Steps

1. Build impossible-space Room 407 with final clue, child-room reveal, and checkpoint marker.
2. Add final event sequence, light failure, entity reveal, and chase handoff.
3. Implement snapshot/restore and checkpoint trigger with deterministic spawn IDs.
4. Build chase route, navigation region, blockages, guidance lighting, and recovery floor; gate chase activation on navigation-map readiness.
5. Implement enemy FSM, sight/range rules, capture, fail overlay, and reload.
6. Build ending reveal, credits, replay/reset, and main-menu return.
7. Test repeated death, pause, transition timing, early ending entry, and one-enemy invariant.
8. Commit finale/checkpoint then chase/ending separately.

## Atomic Commit Checkpoints

- `feat: build Room 407 finale and checkpoint flow`
- `feat: add enemy chase fail recovery and ending`

## Test Scenario Matrix

| Priority | Scenario | Expected |
|---|---|---|
| Critical | Die at/after checkpoint repeatedly | same valid state; one entity/loop; input restored |
| Critical | Enter ending early | rejected without state mutation |
| Critical | Pause during chase | simulation stops/resumes coherently |
| High | Entity loses target/outside bounds | returns/despawns; no infinite pursuit |
| High | Restart/replay after credits | fresh run, no singleton duplication |
| Medium | Room+chase timing | 5–7 minutes combined |

## Success Criteria

- [x] Director-level guarded progression reaches Room 407, chase, ending reveal, and credits without a production bypass.
- [x] Enemy implements all named states and only sustains threat during the climax.
- [x] Automated capture recovery restores objective/marker and preserves the one-entity invariant; retreat recovery is covered.
- [x] Ending rejects an incomplete run, and replay handlers reset `GameState` before scene replacement.
- [x] Headless tests pass.
- [ ] Full manual flow verifies physical chase, mouse/audio recovery, reveal readability, and replay.

## Risks and Mitigation

| Risk | Mitigation |
|---|---|
| Navigation unavailable in headless test | separate FSM logic tests from manual nav path verification |
| Death races scene change | one capture latch, await fade, generation ID on reload |
| Chase unfair on low FPS | distance-based bounded speed, generous route, no instant spawn |

## Security and Licensing

Entity uses project-created silhouette geometry and synthetic audio. No external character asset.

## Next Steps

- Phase 6 integrates final audio/visual/accessibility polish across the complete flow.
