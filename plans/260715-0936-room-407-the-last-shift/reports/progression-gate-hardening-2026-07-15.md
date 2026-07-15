---
type: progression-gate-hardening
date: 2026-07-15
implementation_commit: c9450d76dba1fde735b1301c8d02a86de29b1194
runner_commit: 9a6b93860b39d5d158decbbb79a9ad0a45b8adc7
status: implementation-complete-manual-trigger-qa-open
---

# Progression Gate Hardening

## Finding

Story prompts correctly hid several interactions before their prerequisites, but the production action handlers did not repeat every guard. A player aiming at a visible prop and pressing interact could therefore start the night register before the phone/clock sequence or start Room 407 observations outside their authored order.

## Fix

- `StoryObservationController` now enforces phone, stopped-clock, floor-entry, room-entry, and family-recording prerequisites at the action boundary.
- `StoryProgressionController` now requires `room_entered` for the family recording and drawing in both prompt and action paths.
- The progression test now covers premature calls, authored order, one-shot behavior, inventory grants/consumption, completed-loop closure, solved-radio closure, and final-clue observation gates.
- The checkpoint-layout runner cap is 1200 frames so its deliberate animation/recovery timers can reach the required marker deterministically.

## Automated Evidence

- Focused progression: `PROGRESSION_TEST_OK` and `PROGRESSION_GATE_MATRIX_OK`.
- Focused layout after cap correction: `CHECKPOINT_LAYOUT_TEST_OK` and `CHECKPOINT_LAYOUT_TIMEOUT_STABLE_OK`.
- Full seven-check runner: all checks passed.
- Canonical seven logs: zero parse, engine, assertion, or ObjectDB leak matches.
- `git diff --check`: clean.

## Remaining Evidence Gap

The suite calls the production story facade and validates physics/layout invariants, but it does not replace a physical keyboard/mouse F5 run. Threshold triggers, every ray-target interaction, full capsule traversal, chase feel, audible balance, settings relaunch, and measured 15–20 minute pacing remain manual Phase 7 evidence.

## Environment

- Godot: `4.7.1.stable.official.a13da4feb`
- C: approximately 12.15 GiB free after the full runner
- D: approximately 21.48 GiB free after the full runner
- Remote after implementation/test push: `9a6b93860b39d5d158decbbb79a9ad0a45b8adc7`

## Unresolved Questions

- None beyond the explicitly open manual validation set.
