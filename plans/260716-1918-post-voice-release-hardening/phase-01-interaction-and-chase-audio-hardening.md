# Phase 1: Interaction and chase audio hardening

## Context

- Main goal: [`../260715-0936-room-407-the-last-shift/plan.md`](../260715-0936-room-407-the-last-shift/plan.md)
- Voice QA: [`../260716-1721-voice-over-and-stability-hardening/reports/260716-1849-voice-over-qa.md`](../260716-1721-voice-over-and-stability-hardening/reports/260716-1849-voice-over-qa.md)
- Runtime paths: `scripts/interaction/door-interactable.gd`, `scripts/world/chase-sequence-controller.gd`
- Regression paths: `tests/player-input-integration-test.gd`, `tests/checkpoint-layout-test.gd`

## Files

- Modify `scripts/interaction/door-interactable.gd`
- Modify `scripts/player/player-controller.gd`
- Modify `scripts/world/chase-sequence-controller.gd`
- Modify `tests/player-input-integration-test.gd`
- Modify `tests/checkpoint-layout-test.gd`
- Modify `tests/physical-route-smoke-test.gd`
- Modify the active main plan and its Phase 7/8 evidence only after runtime verification
- Add one report below this plan's `reports/` directory

## Steps

1. Add a designer-tunable horizontal door sweep clearance derived from the authored 2.2 m panel and player capsule.
2. Reject unsafe open and close attempts with local feedback before key consumption, cooldown, interaction signal, or tween mutation; hold only movement during a valid tween so the actor cannot enter the sweep after the initial check.
3. Emit a short low-frequency spatial entity cue at chase start and after checkpoint recovery; reuse the bounded audio cache and normal teardown.
4. Extend production-input and chase fixtures to prove reject/allow behavior, cue parent/routing/count, recovery replay, and teardown.
5. Run focused checks, then the complete 12-check runner and scan current logs.
6. Run standard and adversarial review, update truthful release evidence, commit focused clusters, and push.

## Risks and rollback

- An oversized clearance could make open doors feel impossible to close. Test both the blocked near position and the existing safe side position.
- Replaying a cue during recovery could overlap a stale cue. Stop the cue ID before replay and assert bounded player count.
- If either change regresses a public interaction contract, revert that focused commit without touching the voice slice.
