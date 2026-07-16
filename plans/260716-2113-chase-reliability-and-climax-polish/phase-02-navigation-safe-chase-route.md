# Phase 2 - Navigation-Safe Chase Route

## Files

- `scripts/world/continuous-world-builder.gd`
- `tests/checkpoint-layout-test.gd`
- `tests/run-headless-tests.ps1`

## Steps

- [x] Define one authoritative three-barrier layout with alternating open lanes.
- [x] Build visible collision geometry and red bypass cues from that layout.
- [x] Replace the single navigation rectangle with connected convex corridor segments that taper around every obstruction.
- [x] Add collision-ray, clearance, reachable-path, alternating-turn, and entity traversal regressions.
- [x] Raise only the checkpoint-layout watchdog enough for the longer real-LOS traversal contract; marker/error gates remain mandatory.
- [x] Run focused checkpoint/layout green.

## Acceptance

- Each barrier blocks its authored lane and leaves at least a player/enemy-capsule-safe route.
- Navigation path from chase start to exit bends through all three bypasses and reaches the destination.
- The entity advances across an obstruction instead of sticking, immediately failing, or despawning.
- Red guide cues agree with the safe lane.
