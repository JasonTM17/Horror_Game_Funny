# Phase 2 - Navigation-Safe Chase Route

## Files

- `scripts/world/continuous-world-builder.gd`
- `tests/checkpoint-layout-test.gd`

## Steps

- [ ] Define one authoritative three-barrier layout with alternating open lanes.
- [ ] Build visible collision geometry and red bypass cues from that layout.
- [ ] Replace the single navigation rectangle with connected convex corridor segments that taper around every obstruction.
- [ ] Add collision-ray, clearance, reachable-path, alternating-turn, and entity traversal regressions.
- [ ] Run focused checkpoint/layout green.

## Acceptance

- Each barrier blocks its authored lane and leaves at least a player/enemy-capsule-safe route.
- Navigation path from chase start to exit bends through all three bypasses and reaches the destination.
- The entity advances across an obstruction instead of sticking, immediately failing, or despawning.
- Red guide cues agree with the safe lane.

