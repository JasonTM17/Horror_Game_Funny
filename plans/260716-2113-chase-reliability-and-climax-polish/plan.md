---
title: Chase reliability and climax polish
description: >-
  Make ending transition terminal, turn the straight chase into a navigation-safe
  obstacle route, and replace passive ending delay with a voiced interactive epilogue.
status: in-progress
priority: P1
branch: main
created: '2026-07-16T21:13:18+07:00'
source: ck:cook --auto --tdd
---

# Chase Reliability and Climax Polish

## Outcome

Deliver three sequential, headless-verifiable improvements without splitting the continuous run:

1. Ending wins deterministically over any in-flight capture recovery.
2. Chase uses three alternating physical obstructions, readable red bypass cues, and matching navigation topology.
3. Reaching the exit starts a two-step voiced epilogue; credits appear only after the player inspects both reveal props.

## Requirements Contract

- **Expected output:** production GDScript, scene-generated geometry, six manifest-backed English OGG cues, regressions, and synchronized project documentation.
- **Acceptance:** no recovery can overwrite `ENDING`; every barrier blocks one lane while leaving a capsule-safe navigable bypass; enemy navigation reaches the exit; two ray-reachable epilogue props gate credits exactly once in the same gameplay scene; telemetry order remains `chase -> ending -> credits`.
- **Out of scope for this slice:** physical F5 sign-off, opening/Floor 4/Room 407 pacing retuning, persistent checkpoints, binary export, and a second ending. The parent game goal still requires real gameplay screenshots and an optimized GIF embedded in the final documentation before completion.
- **Constraints:** Godot 4.7.1 Compatibility renderer, one `gameplay.tscn` run, existing stage/flag/checkpoint contracts, no GUI automation without renewed consent, atomic Conventional Commits, C:/D: monitoring, non-force push.
- **Touchpoints:** chase controller/fail overlay, continuous world/navigation builder, epilogue-first gameplay action routing with story fallback, forwarded credits signal/pacing finalization, narrative manifest/assets, progression/layout/audio tests, README/design/architecture/testing/limitations/credits.

## Phases

| Phase | Name | Status |
|---|---|---|
| 1 | [Terminal ending transition](./phase-01-terminal-ending-transition.md) | Completed |
| 2 | [Navigation-safe chase route](./phase-02-navigation-safe-chase-route.md) | Completed |
| 3 | [Voiced interactive epilogue](./phase-03-voiced-interactive-epilogue.md) | Completed |
| 4 | [Full QA, review, documentation, and delivery](./phase-04-qa-review-and-delivery.md) | Pending |

## Evidence Baseline

- `HEAD` and `origin/main`: `1ee869075a0083f161cef3003bcb1c1d44d91af3`; divergence `0/0`; clean worktree before planning.
- Fresh baseline: all 12 canonical checks passed; scout measured 70 voice cues at 233.994 seconds raw and 299.015 seconds effective authored hold.
- Knowledgeable critical path estimate: 596.5 seconds sprint / 741 seconds mostly walking. Chase plus ending is about 99.8 seconds versus the 120–180 second target.
- Proven defects/gaps: capture recovery can overwrite Ending after its await; chase blockers are visual-only; current ending is a passive three-second timer.

## Commit Boundaries

1. `docs: plan chase reliability and climax polish`
2. `fix(chase): make ending terminal during recovery`
3. `feat(chase): add navigable corridor obstructions`
4. `feat(ending): add voiced interactive epilogue`
5. `test: harden climax progression contracts`
6. `docs: record climax polish evidence`

## Completion Boundary

This plan can close after fresh focused and full headless checks, adversarial review, documentation sync, clean secret scan, atomic commits, non-force push, and exact remote parity. The parent game goal remains open until the physical F5/pacing/presentation/audio/chase/settings release gates are evidenced and final docs render real gameplay screenshots plus an optimized GIF.
