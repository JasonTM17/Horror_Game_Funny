---
phase: 4
title: "Prepare physical F5 operator handoff"
status: completed
effort: "small"
---

# Phase 4: Prepare physical F5 operator handoff

## Overview

Update the existing parent Phase 5 handoff so a human can close the remaining gate in one
clean, auditable run without confusing wrapper integrity with perceptual review.

## Prerequisites and inventory

- Phase 3 automated evidence and review are green.
- Primary artifacts: parent Phase 5 file, its existing
  `reports/phase-05-operator-handoff-2026-07-18.md`, `docs/testing.md`, and the runner's
  generated `summary.json`/`summary.md` contract.

## Steps

1. Pin the handoff to the eventual clean branch/commit and exact Godot 4.7.1 executable;
   do not run it from this dirty planning/implementation tree.
2. Give one copy-paste `ProjectRun` command and one optional `EditorF5` command with a
   real capture reference and `-ConfirmPhysicalInput`; explain the side-channel difference.
3. Require a fresh `START SHIFT` route to visible credits, real keyboard/mouse, one chase
   failure/recovery, Settings save, fullscreen, comfort toggles, focus/relaunch behavior,
   and no manual method calls or `Continue` checkpoint start.
4. Require one eligible, complete, exact-order same-run payload with 900-1200 seconds
   active time and all chapter verdicts in range; reject mixed or analyze-only packages.
5. Require a human to watch the capture and complete chase fairness, clue/guide-light
   readability, voice/SFX balance, scare comfort, display, focus, and input judgments.
6. Record the remaining owner/action plainly. Do not mark parent Phase 5, PDR-07, or the
   overall release complete until the evidence package and human matrix are reviewed.
7. At the delivery boundary, ask for Git commit/push authorization. Docker Hub may follow
   the Phase 3 conditional rule; never publish an image as a substitute for the game gate.

## Success criteria

- [x] Handoff commands, prerequisites, expected files, and rejection cases are exact.
- [x] Operator matrix covers the full main route, chase recovery, settings, and perception.
- [x] Parent plan/PDR/README still state physical review is open before valid evidence.
- [x] No automation, staged media, export smoke, or Docker result is called human proof.
- [x] Commit/Git push and any Docker Hub result have explicit, recorded authorization/evidence.

## Result so far

Delivery commit `c14d7bb8ec7313abf0c4954c496ede1df4e7800e` is on `main` and matches
`origin/main` after an authorized push of the evidence-closure + Docker Hub / media polish
slice. Live Docker daemon build/run remained unavailable on the authoring host; Hub
publication is delegated to CI (`docker-suite.yml`) when `DOCKERHUB_USERNAME` /
`DOCKERHUB_TOKEN` are configured. Parent Phase 5 / PDR-07 remains human-only and open.

## Non-goals and risks

- Agent-driven desktop input is not a human blind playtest and cannot close PDR-07.
- The largest risk is administrative closure without viewing the capture; fail closed.
