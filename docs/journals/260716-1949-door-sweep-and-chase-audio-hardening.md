---
date: 2026-07-16
session: door-sweep-and-chase-audio-hardening
---

# Journal: 2026-07-16 — Door Sweep and Chase Audio Hardening

## Context

Post-voice release audit found two concrete gaps: a rotating door could sweep through the player, and the chase entity had no positional arrival cue. Scope stayed narrow: preserve the continuous route, progression state, captured mouse, and existing audio cache.

## What Happened

- Root cause: each door is a center-pivot `StaticBody3D` with a 2.2 m by 0.2 m footprint, while the player capsule radius is 0.34 m. The minimum horizontal sweep is therefore 1.44 m; the shipped 1.5 m guard adds a small margin.
- A start-only proximity guard was incomplete. It blocked a player already inside the sweep, but still allowed the player to walk into the panel during its 0.55-second tween. Guarding both open and close plus a movement-only tween lock closed both paths.
- Fixture work failed twice before proving the contract: first `PHYSICAL_ROUTE_ASSERT: floor_door did not consume its one-shot key` because the old smoke position was now correctly unsafe; then `PLAYER_INPUT_ASSERT: production door has no collision shape` because the fixture trusted a fragile name for the dynamically added `CollisionShape3D`. The fixes moved the smoke actor clear and found the collider by type. Neither failure justified weakening production behavior.
- Chase start and checkpoint recovery now play one 92 Hz, 1.4-second SFX cue parented to the entity. The same cue ID is stopped before replay, failure, or ending teardown, preventing overlap and releasing cache ownership.

## Reflection

The fixture false negatives were frustrating because they looked like progression and missing-runtime-node regressions. Relief came only after replacing those assumptions with geometry- and type-based checks, then seeing the complete suite pass. Automated evidence is strong for contracts, not for feel: no physical run yet proves door clearance comfort, cue audibility, chase fairness, visual balance, Settings interaction, or 15–20 minute pacing.

## Decisions Made

| Decision | Rationale | Impact |
|---|---|---|
| Use a designer-tunable 1.5 m horizontal guard | Covers the 1.1 m panel half-width plus 0.34 m capsule radius and margin | Unsafe attempts mutate no cooldown, key, unlock, signal, rotation, or tween |
| Apply the guard symmetrically to open and close | Both rotation directions share the same center-pivot sweep | No close-through-player or reopen-through-player path |
| Lock only movement with a per-door reason | Full input lock would expose the cursor and cause a camera flash | Velocity stops during valid motion; camera, mouse capture, and unrelated input remain active; completion/teardown releases only that reason |
| Parent one 92 Hz cue to the entity and stop before replay | Spatial origin must follow the threat; recovery must not stack stale players | One bounded SFX player at start/recovery with deterministic failure/ending cleanup |
| Reject a stationary-only test | It cannot detect entry into the sweep after the initial check | Regression presses mapped movement during the tween |
| Reject a hard-coded dynamic node name | Runtime-created children do not owe the fixture a stable name | Collider discovery follows the `CollisionShape3D` contract by type |

## Verification

- Focused door and chase fixtures passed after the two fixture corrections.
- Final Godot 4.7.1 run: 12/12 canonical checks passed in 60.3 seconds; 12 logs, 10 required markers, zero scanned engine/script/parse/assert/leak failures, and zero leftover temporary profiles.
- Runtime commits: `2e2abf2` (`fix(interaction): prevent door sweep collisions`) and `d5e6dfb` (`feat(audio): add positional chase entity cue`).

## Next Steps

- Run a fresh physical F5 boot-to-credits playthrough with keyboard/mouse, same-run video, and `PLAYTHROUGH_PACING` payload.
- During that run, close/reopen every player-operated door near the guard boundary; fail and recover once in the chase; listen for one balanced entity cue at each start; exercise Settings/fullscreen; then review the capture against the 900–1200 second and chapter pacing targets.

## Unresolved Questions

- Does 1.5 m feel natural at every door on a real approach?
- Is the 92 Hz cue audible and useful without masking narration, ambience, or the chase drone?
- Does a physical run satisfy traversal, chase fairness, presentation, Settings, and 15–20 minute pacing gates?
