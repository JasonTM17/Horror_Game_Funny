---
title: "Horror scare and spatial audio polish"
description: >-
  Replace flat one-note scare triggers with authored anticipation, reveal, and
  aftermath beats using bounded spatial audio, light responses, and safe cleanup.
status: completed
priority: P1
branch: "main"
tags: []
blockedBy: []
blocks: []
created: "2026-07-17T14:52:21.685Z"
createdBy: "ck:plan"
source: skill
---

# Horror scare and spatial audio polish

## Outcome

Upgrade the four existing story-aligned scares without adding levels or random
jumpscare spam. Each beat must remain one-shot, non-colliding, pause-safe, and
teardown-safe while preserving the continuous 15–20 minute route and voice queue.

## Requirements Contract

- **Expected output:** the four planned targets—floor arrival, photo, cassette, and
  Room 407—use distinct authored staging, while the existing rabbit memory retains
  its own story-aligned sub-beat; all use layered procedural/spatial SFX and light
  or environmental response where applicable.
- **Acceptance:** anticipation precedes each reveal; cue IDs do not overlap; repeat
  triggers cannot duplicate actors/audio; temporary lights, actors, and audio clean
  up on timeout or director exit; scares do not alter progression beyond their
  existing event completion; voice playback is not stopped or replaced.
- **Out of scope:** new levels, combat, new ending, Blender/external asset packs,
  third-party recorded SFX, heavy shaders, or changing the 12-check runner count.
- **Constraints:** Godot 4.7.1 Compatibility renderer; existing flags, checkpoints,
  stage thresholds, and public audio APIs remain compatible; moderate volume and
  18 m spatial range; focused Conventional Commits; monitor C:/D:; non-force push.
- **Touchpoints:** `horror-event-director.gd`, `turn-away-apparition.gd`, a focused
  scare-sequence helper, progression/audio regressions, design/architecture/testing.

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Scare direction contracts](./phase-01-scare-direction-contracts.md) | Complete |
| 2 | [Layered scare implementation](./phase-02-layered-scare-implementation.md) | Complete |
| 3 | [Regression QA review and delivery](./phase-03-regression-qa-review-and-delivery.md) | Complete |

## Dependencies

- Builds on completed runtime slices in the parent Room 407 plan.
- Does not close the separate physical 15–20 minute playthrough gate.

## Completion Evidence

- Fixed story triggers remain `GameState`-guarded and non-random. Four buildup beats—floor arrival, photograph, cassette turn-away, and rabbit—lead into the separate Room 407 manifestation climax.
- `HorrorScareSequence` owns pause-safe waits plus cue/light/actor cleanup; `HorrorApparitionFactory` supplies non-colliding shared actors. The cassette actor also ends at `memory_cassette_recalled` when unrevealed.
- Focused `progression` and `settings-audio` passed. Final canonical run: 12/12 on 2026-07-17 in 63.5 seconds; exactly 12 logs; zero scanned current failure lines including lambda/leak patterns; zero remaining `godot-user-*` runner profiles.
- Two Medium lifecycle defects were fixed. Final review: zero Critical, High, or Medium findings.
- This plan closes the focused source/test/docs slice only. PDR-07 and the parent physical 15–20 minute, physical-input, rendered scare-quality, and audible-mix gates remain open.

## Commit Boundaries

1. `plan: define authored scare and audio contracts`
2. `feat(horror): layer spatial scare sequences`
3. `test(horror): harden scare lifecycle contracts`
4. `docs(horror): record scare direction and evidence`
