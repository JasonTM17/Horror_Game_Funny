---
type: completion-gap-scout
date: 2026-07-15
source_commit: f0b4897d91c66331f04f5291c2e3e9ae61d304be
status: planned
---

# Completion-Gap Scout Report

## Summary

Three read-only scouts and the lead audit compared the 1,152-line project brief with current source, tests, documentation, Git, and release evidence. The continuous game, two puzzles, three memories, dynamic hallway, chase, fail/recovery, ending, settings, documentation, and clean-clone automation are real. The audit also found correctness and presentation gaps that remain fixable without Computer Use; physical pacing and sensory judgment remain separate manual evidence.

## Accepted Findings

| Priority | Finding | Evidence | Planned correction |
|---|---|---|---|
| Critical | Installed fuse can be collected again after consumption | pickup guard checks inventory but not `fuse_installed` | permanently gate pickup and add a post-install backtrack regression |
| High | Room 407 checkpoint is created after crossing the room threshold | `GameplayDirector` snapshots at `room_entered`; spawn is already beyond the door | snapshot when radio sequence completes; spawn before the room door; do not overwrite after entry |
| High | Fourth-floor key is granted but never required or consumed | floor door gates only on `log_signed` | require the item once, consume it, persist an unlock flag, and use player-facing inventory labels |
| High | Door override bypasses base enabled/cooldown guards | door begins its tween before `super.interact()` validates | validate before mutation; preserve lock feedback and clean reopen behavior |
| High | Chase capsule is centered at floor level and tests compensate with a vertical injection | body/shape have no Y offset; capture test adds 1.1 m | center production mesh/shape above the entity origin and remove test compensation |
| High | AI states are labels over mostly identical pursuit | APPEAR/STALK/LOST_TARGET still follow the current target | give appear, stalk, chase, lost-target, search, and despawn distinct movement contracts |
| High | Synthesized sample cache ignores pitch/duration | cache key is only caller ID | key by full parameters; reclaim sample-budget accounting when an ID stops |
| High | Flashlight flicker is frame-rate dependent and continues while paused | random trial occurs every inherited frame | use bounded interval/pulse timers, pause-safe processing, and deterministic comfort assertions |
| Medium | Floor arrival door slam and elevator transition are narration-only | only a global tone/subtitle changes | render elevator dressing/display change, close the real door once, and show a real distant apparition |
| Medium | Room 407 and chase presentation are sparse | same corridor shell continues; chase has only guide lights | add bounded procedural room dressing, a pre-chase manifestation, and safe chase-side obstruction dressing |
| Medium | Initial/return keyboard focus is inconsistent | boot/pause do not grab focus; hidden Settings Close can retain it | assign focus on menu open/resume and after Settings closes |
| Medium | Settings save failure is ignored | `ConfigFile.save()` result is discarded | return/report the error without pretending persistence succeeded |

## Rejected or Deferred Findings

- Separate Drawer and checkpoint-trigger classes: deferred under YAGNI; the shipped route has no drawer puzzle, and checkpoints are guarded stage boundaries rather than interactables.
- Dedicated `scenes/levels`, `scenes/events`, and `scenes/props` directories: rejected as a completion requirement; runtime procedural composition is intentional and documented.
- Physical audio/visual/pacing proof via automation: rejected as a substitution. It still requires an authorized fresh F5 run with same-run telemetry.
- New Blender assets, binary export, persistent save, crouch, secondary ending, and branching chase topology: remain outside this slice.

## Existing Evidence Retained

- Godot 4.7.1 Compatibility project and main scenes load.
- Clean clone at `257e601` passed all 12 checks with 12 logs, 9/9 required markers, zero bad log matches, zero temporary profiles, and zero tracked changes.
- Current `main` and `origin/main` match at `f0b4897`; worktree was clean before this plan update.
- 66 commits exist on `main`; remote is the required GitHub URL; no force push is used.

## Plan Review

The completion-audit slice was independently approved before implementation. The review tightened five contracts: the floor-door unlock must be session-level, atomic, and idempotent; only the room-entry trigger is forbidden from overwriting `room_entrance`; rejected door interactions must produce no side effects; AI/scare regressions must be deterministic and verify cleanup/reset; and paused flashlight processing must not advance timers, RNG, or energy.

## Unresolved Questions

- What chapter and total timings will the fresh physical F5 run produce after these fixes?
- Does target hardware confirm the final chase, flicker comfort, visual readability, and audible mix?
