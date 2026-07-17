---
title: "Horror scare and spatial audio polish"
description: >-
  Replace flat one-note scare triggers with authored anticipation, reveal, and
  aftermath beats using bounded spatial audio, light responses, and safe cleanup.
status: in-progress
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

- **Expected output:** four distinct authored scare sequences across floor arrival,
  photo, cassette, and Room 407, with layered procedural/spatial SFX and light or
  environmental response.
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
| 1 | [Scare direction contracts](./phase-01-scare-direction-contracts.md) | Pending |
| 2 | [Layered scare implementation](./phase-02-layered-scare-implementation.md) | Pending |
| 3 | [Regression QA review and delivery](./phase-03-regression-qa-review-and-delivery.md) | Pending |

## Dependencies

- Builds on completed runtime slices in the parent Room 407 plan.
- Does not close the separate physical 15–20 minute playthrough gate.

## Commit Boundaries

1. `plan: define authored scare and audio contracts`
2. `feat(horror): layer spatial scare sequences`
3. `test(horror): harden scare lifecycle contracts`
4. `docs(horror): record scare direction and evidence`
