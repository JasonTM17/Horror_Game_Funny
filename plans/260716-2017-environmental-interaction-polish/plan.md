---
title: Environmental interaction polish
status: completed
priority: P1
branch: main
created: '2026-07-16T20:17:00+07:00'
source: ck:cook
mode: auto
---

# Environmental interaction polish

## Outcome

Close two explicit interaction gaps from the attached game specification without changing the continuous route: add a reusable animated drawer to the lobby desk, and make the authored fourth-floor false door return clear physical-ray feedback.

## Phase

- [Phase 1: drawer and atmospheric door interactions](./phase-01-drawer-and-atmospheric-door-interactions.md) — completed

## Acceptance criteria

- The production player ray can acquire the authored lobby drawer from a valid nearby look angle.
- One mapped interact action opens or closes the drawer through a bounded tween; input spam cannot reverse an active tween.
- Drawer feedback and SFX are clear, while inventory, flags, objective, stage, and checkpoint remain unchanged.
- The fourth-floor false door is reachable through the production ray and returns a clear non-opening response with spatial SFX.
- Environmental interaction colliders stay off the World collision layer so they cannot snag the player capsule.
- Scene teardown leaves no owned spatial player or generated-audio cache entry for either interaction.
- Focused red/green verification and the complete canonical 12-check runner pass without engine, script, parse, assertion, leak, or temporary-profile failures.
- Documentation and the active completion plan describe the new optional interactions without claiming the physical 15–20 minute gate is closed.
- Changes land in focused Conventional Commits and push non-force to the configured repository after disk, secret, diff, and parity checks.

## Scope boundary

- No new progression gate, inventory item, checkpoint, narrative sequence, or voice cue.
- No pacing-target change, Blender work, export package, or Godot GUI control.
- Existing door, puzzle, chase, settings, and 70-cue voice contracts remain stable.

## Dependencies

- Godot 4.7.1 portable console executable under `D:\Tools`.
- Existing production player ray, `Interactable` base contract, HUD feedback channel, and generated spatial-tone API.

## Evidence

- [QA and project-management report](./reports/pm-260716-2048-environmental-interaction-polish.md)
- Delivery boundary `3b25956` matched `origin/main` with `0/0` divergence before this metadata-only completion record.
