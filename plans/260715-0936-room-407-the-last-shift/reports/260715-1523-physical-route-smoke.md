---
type: tester
date: 2026-07-15
source_commit: 48ab37ede63ae20b9e94b0bd650e1abccc2ec396
documentation_commit: 9c7980554c7a760285d5719dd3c4d48a9260b990
---

# Tester: Production Physical Route Smoke

## Summary

Added a focused headless smoke check that drives the production player through mapped movement input and physics instead of proving route geometry only with rays and coordinates. The final focused check passed independently, the complete runner passed 10/10, and the remaining manual 15–20 minute acceptance boundary stays explicit.

## Environment

| Item | Evidence |
|---|---|
| Engine | Godot 4.7.1 stable, Compatibility/headless |
| Project | `D:\Horror_Game` |
| Test source | [`physical-route-smoke-test.gd`](../../../tests/physical-route-smoke-test.gd) |
| Runner | [`run-headless-tests.ps1`](../../../tests/run-headless-tests.ps1) |
| Isolated profile | repository-local `.tmp/godot-user-*`, removed after each run |
| Full-suite disk snapshot | C: 11.66 GiB free before/after; D: 18.53 GiB free before/after |

## Findings

### Checkpoint Assertion Diagnosis

The first focused run reached Room 407 but incorrectly expected `pending_spawn_id` to change as soon as the checkpoint was created. [`create_checkpoint()`](../../../scripts/autoload/game-state.gd) stores `scene_path` and `spawn_id` in the checkpoint snapshot; `pending_spawn_id` changes only during restore. The room trigger performs its flag and checkpoint writes synchronously, and a fresh run clears prior state, so race and stale-state hypotheses were eliminated. The final assertion checks the stored snapshot directly; production checkpoint behavior was not changed.

### Targeted Physical Coverage

The test instantiates the production gameplay scene and production `CharacterBody3D`, presses the mapped `move_forward` action over physics frames, and therefore reaches the normal `Input.get_vector()` plus `move_and_slide()` path. It verifies:

- floor, power, and Room 407 doors stay closed without their flags;
- measurable forward movement reaches each locked door before the capsule is blocked;
- each door opens with its valid flag and the same capsule crosses afterward;
- the memory threshold rejects premature entry and activates after `power_stable`;
- Room 407 creates the expected gameplay-scene checkpoint snapshot; and
- the chase threshold rejects premature entry, then starts with `chase_ready` and owns a valid entity.

The displacement assertion was strengthened after adversarial review so a broken/no-movement state cannot satisfy the locked-door check merely by remaining at its start position.

### Independent Verification

- Root focused run after the checkpoint correction: exit `0`, `PHYSICAL_ROUTE_SMOKE_TEST_OK`, zero bad-pattern matches.
- Independent tester: 2/2 isolated runs passed with the marker, zero engine/script/parse/assert/leak matches, and both unique profiles removed.
- Independent debugger: confirmed assertion-contract mismatch; no gameplay defect, race, or stale state.
- Independent reviewer: no Critical, High, or Medium findings; the only Low note was to preserve the documented manual-coverage boundary.

### Complete Runner

The complete runner finished all ten checks with exit `0`: editor import, menu, gameplay, game state, progression, checkpoint/layout, physical route, settings/audio, persistence write, and persistence read. All ten canonical logs existed; all seven expected success markers were present; error/assertion/leak scan failures were `0`; remaining isolated test profiles were `0`.

### Coverage Boundary

This smoke harness teleports between focused gates, sets prerequisite flags, and calls `door.interact()` directly. It does not press E through the player's interaction ray, solve the puzzles through physical UI, traverse the complete corridor, exercise a human-driven chase, judge presentation, or measure 15–20 minute pacing. The manual matrix in [`docs/testing.md`](../../../docs/testing.md) remains authoritative for those claims.

## Recommendations

1. Keep the physical-route check in every full runner invocation and retain its assertion prefix in the log scanner.
2. Treat any future door/layout/player-controller change as requiring both the focused check and the complete ten-check suite.
3. Complete a recorded F5 keyboard/mouse boot-to-credits run before closing Phase 7 or claiming the 15–20 minute target.

## Unresolved Questions

- What are the measured fresh-run chapter and total times with physical keyboard/mouse input?
- Does the full E/raycast interaction path remain readable and snag-free at every gate during a human playthrough?
- Is the chase fair and visually/audibly legible on the target display and audio device?
