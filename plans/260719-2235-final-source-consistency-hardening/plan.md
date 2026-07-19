---
title: Final source consistency hardening
description: >-
  Close two evidence-backed runtime defects and reconcile final repository
  metadata without overstating the human release gate.
status: completed
priority: P1
branch: main
tags:
  - bugfix
  - audio
  - settings
  - docs
  - release
blockedBy: []
blocks:
  - 260718-1319-final-horror-release-candidate
created: '2026-07-19T15:42:23.542Z'
createdBy: 'ck:plan'
source: skill
---

# Final source consistency hardening

## Overview

Add regression protection, fix the settings-signal and looping-PCM defects found by the
final CK scout, then reconcile small documentation/repository-policy drift. This child
plan restores the automated source-complete boundary; it does not close the parent
human physical playthrough/PDR-07 gate.

## Requirements Contract

- **Output:** focused regressions; compatible `Variant` settings callback; seamless
  cycle-aligned procedural drone PCM with unchanged one-shot fade; consistent LF,
  security, and historical-plan wording; current verification/report evidence.
- **Acceptance:** focused test proves boolean settings delivery to a live production
  player and inspects loop PCM energy/continuity; canonical Godot suite passes 12/12;
  repository docs/media, packaging, secrets, and diff gates pass; mandatory review has
  zero unresolved Critical/High/Medium findings; public contracts remain stable.
- **Out of scope:** persistent checkpoints, gamepad, new gameplay/story/art/music/SFX,
  installer/signing/store CI, Docker Hub publication, generated-artifact deletion, and
  any automated claim that PDR-07 is complete.
- **Constraints:** Godot 4.7.1 Compatibility; no Computer Use; preserve `main`, current
  test markers, autoload/settings/audio/cache contracts, and all user work.
- **Touchpoints:** `tests/settings-audio-test.gd`, `scripts/autoload/audio-manager.gd`,
  `scripts/player/player-controller.gd`, `.editorconfig`, `SECURITY.md`, the superseded
  2026-07-15 plan/Phase 8, plus plan-scoped verification and journal reports.

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Add regression contracts](./phase-01-add-regression-contracts.md) | Completed |
| 2 | [Fix runtime and repository consistency](./phase-02-fix-runtime-and-repository-consistency.md) | Completed |
| 3 | [Verify and finalize](./phase-03-verify-and-finalize.md) | Completed |

## Dependencies

- Blocks source-finalization claims in
  [`260718-1319-final-horror-release-candidate`](../260718-1319-final-horror-release-candidate/plan.md).
- At this child plan's completion snapshot, parent Phase 5 remained independently
  blocked on human physical/perceptual evidence. The later 2026-07-19 owner waiver in
  the parent plan supersedes that release-policy status without creating human evidence.

## Completion

All 3/3 phases and 13/13 success criteria are evidence-backed. The
[QA addendum](./reports/260719-2321-qa-verification-addendum.md) records the final 12/12
host suite, evidence/export gates, and `117920376`-byte Windows artifact. Final mandatory
review scored 10/10 with zero unresolved Critical/High/Medium. Repository docs, active
operator handoff, packaging, secrets, Compose config, links/media, and diff checks are
current. This completed source hardening only. At that snapshot parent Phase 5/PDR-07
remained open; the later parent-plan owner waiver closes it as accepted risk, not as a
human-verified pass.
