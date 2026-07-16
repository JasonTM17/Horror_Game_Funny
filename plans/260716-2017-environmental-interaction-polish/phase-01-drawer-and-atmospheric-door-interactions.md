# Phase 1: Drawer and atmospheric door interactions

## Context

- Authoritative brief: the user-provided local specification attached to this task (not committed into the repository).
- Main goal: [`../260715-0936-room-407-the-last-shift/plan.md`](../260715-0936-room-407-the-last-shift/plan.md)
- Interaction base: [`../../scripts/interaction/interactable.gd`](../../scripts/interaction/interactable.gd)
- Continuous layout: [`../../scripts/world/continuous-story-layout.gd`](../../scripts/world/continuous-story-layout.gd)
- Production route fixture: [`../../tests/physical-route-smoke-test.gd`](../../tests/physical-route-smoke-test.gd)

## Files

- Create `scripts/interaction/drawer-interactable.gd`.
- Create `scripts/interaction/atmospheric-door-interactable.gd`.
- Modify `scripts/world/continuous-story-layout.gd`.
- Modify `tests/physical-route-smoke-test.gd`.
- Update only documentation and plan evidence affected by verified behavior.
- Add one QA report below this plan's `reports/` directory.

## Implementation steps

- [x] Add production-ray regression assertions for missing drawer and false-door contracts; record the expected failing run before implementation.
- [x] Implement a designer-tunable drawer state machine with one active tween, open/close prompts, HUD feedback, spatial SFX, and teardown cleanup.
- [x] Implement a non-opening atmospheric-door response with bounded cooldown, HUD feedback, spatial SFX, and teardown cleanup.
- [x] Author both interactables in the continuous layout using Interactable-only colliders and verify their ray-accessible positions.
- [x] Prove mapped interaction, tween spam rejection, state immutability, collider layers, SFX ownership, and cleanup in the production route fixture.
- [x] Run focused green verification, the full suite, CK debugging and code review, then update truthful docs/evidence.
- [x] Commit plan, runtime, tests/evidence, and parity in focused clusters; push non-force only after repository checks.

## Verification evidence

- Controlled missing-drawer red probe: exit `2` in `3.03 s`; restored focused route printed `PHYSICAL_ROUTE_SMOKE_TEST_OK`.
- Final canonical runner: `12/12`, `10/10` required markers, zero scanned bad lines, zero temporary profiles.
- CK debugger, tester, initial review, and fix-only re-review findings are resolved; final review has no findings.
- Runtime, tests, and documentation were pushed through `3b25956` without force and reached `0/0` parity.

## Risks and rollback

- A low or occluded drawer collider can make the prompt unreachable. Test the exact production camera, ray length, authored stance, and look pitch.
- A World-layer drawer collider could snag the player while sliding. Require Interactable-only collision in source and regression coverage.
- Same-ID spatial tones can overlap or retain cache ownership. Use per-instance IDs, stop before replay, and stop on teardown.
- If either optional interaction alters progression state, remove that mutation rather than broadening the story contract.
