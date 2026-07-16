---
title: 'Room 407: The Last Shift'
description: >-
  Build and ship a complete 15–20 minute uninterrupted Godot 4.7.1 psychological
  horror game in one continuous gameplay scene with atomic commits and verified
  progression.
status: in-progress
priority: P1
branch: main
tags:
  - feature
  - godot
  - game
  - critical
blockedBy: []
blocks: []
created: '2026-07-15T02:47:18.920Z'
createdBy: 'ck:plan'
source: skill
---

# Room 407: The Last Shift

## Overview

Create **ROOM 407: THE LAST SHIFT** from an empty public repository. Deliver a complete first-person main path: lobby tutorial, fourth-floor fuse puzzle, three-memory hallway loop, `0007` radio puzzle, Room 407 reveal, checkpointed chase, ending, credits, settings, accessibility, tests, and documentation.

Implementation is sequential. Each coherent slice ends with disk check, headless validation, secret scan, atomic Conventional Commit, and push after local verification. User-visible gameplay remains one continuous run; beat names are pacing markers, not levels. Godot runs portable/self-contained from D: to preserve the more constrained C: volume.

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Repository and Toolchain](./phase-01-repository-and-toolchain.md) | Completed |
| 2 | [Core Runtime and Player](./phase-02-core-runtime-and-player.md) | Completed |
| 3 | [Lobby and Fuse Vertical Slice](./phase-03-lobby-and-fuse-vertical-slice.md) | Completed |
| 4 | [Memory Hallway and Radio Puzzle](./phase-04-memory-hallway-and-radio-puzzle.md) | Completed |
| 5 | [Room 407 Chase and Ending](./phase-05-room-407-chase-and-ending.md) | Completed |
| 6 | [Audio Visual UI and Accessibility](./phase-06-audio-visual-ui-and-accessibility.md) | Completed |
| 7 | [Automated QA Red Team and Polish](./phase-07-automated-qa-red-team-and-polish.md) | In Progress |
| 8 | [Documentation Release and Push](./phase-08-documentation-release-and-push.md) | In Progress |

## Current Evidence Reconciliation — 2026-07-16

- The voice delivery is pushed through `e1e8093`: `5b745b1` fixes initial flashlight timing, `db736f4` adds the 70-cue English voice runtime/assets, `3c17663` adds sequencing/fallback regressions, and `e1e8093` records provenance and QA. The focused post-voice hardening sequence is also pushed: `15b871c` plans the slice, `2e2abf2` prevents door-sweep collisions, and `d5e6dfb` adds the positional chase cue. Local `HEAD`, `origin/main`, and a direct `refs/heads/main` query all matched `d5e6dfb` before this documentation sync.
- Documentation, journal, and QA evidence are pushed in `bf4cd9a`; the working tree was clean and local `HEAD`, `origin/main`, and the direct remote branch ref matched with `0/0` divergence before this metadata-only parity record.
- All 20 production narrative groups resolve to 70 manifest-backed English OGG cues. Playback is exact-subtitle matched, SFX-routed, pause-aware, single-voice, and scene-local; malformed, missing, stale, or unloadable cues fall back without blocking progression.
- The scene-local telemetry snapshots fresh-Lobby eligibility once, records all stage boundaries in observed order, separates active/wall/paused time, finalizes at visible credits, freezes after reset, and emits one JSON payload. Checkpoint, incomplete, and invalid-order evidence receives no total verdict.
- The fresh post-voice hardening suite exits `0` in 60.3 seconds with 12 logs, 10 required markers, zero scanned bad lines, and zero temporary profiles. The compressed fresh payload is complete/order-valid at 6.59 s active, 6.83 s wall, and 0.23 s paused, with `within_target: false` as intended.
- A historical fresh clone of `origin/main` at `c38fde9` independently reproduced `SuiteExit 0`, 12 logs, 9 markers, zero bad lines, zero temporary profiles, and zero dirty lines, then was removed from the verified repository-local temp root. That rehearsal predates the project-settings marker and voice delivery; it is not presented as the current hardening revision.
- Current source and regressions cover the 1.5 m door sweep guard, reason-scoped movement-only lock/release, and one entity-parented SFX cue at chase start and checkpoint recovery with failure/ending teardown. The standard review's one medium finding was fixed; the adversarial review then reported zero findings. Separate writer/reader processes still verify all 11 settings survive relaunch in one isolated profile.
- A real local Compatibility-renderer capture remains developer evidence, not a physical F5 traversal, and cannot prove route completion, presentation quality, audible output, or pacing.
- Phase 1–6 status denotes completed implementation slices. Phase 7 and Phase 8 remain in progress because no authorized physical F5 keyboard/mouse playthrough has paired a same-run capture with an eligible, complete, actual-order-valid 900–1200 second payload or the chase/presentation/audio/settings matrix.
- Post-rehearsal disk snapshot: C: 11.97 GiB free; D: 33.05 GiB free. The isolated runner and rehearsal cleanup left zero `godot-user-*` profiles behind.
- Manual-evidence tooling commits `46a58e8`, `ba59df0`, and `05ade4b` are pushed. They package a new editor F5 or direct project run, bind it to an unchanged clean revision, validate one unique same-session payload, reject engine/script/parse/leak failures, record capture/input/disk metadata, generate a human-review checklist, and always leave final manual-gate closure to review.

## Dependencies

- No cross-plan dependencies. The pushed runtime boundary recorded for this reconciliation is `d5e6dfb`, including the voice delivery and post-voice door/chase hardening. Physical playthrough evidence and any evidence-backed final tuning remain the next release steps.
- Godot 4.7.1 Windows x86_64 portable under `D:\Tools`, with `_sc_` and D:-resident `TEMP`/`TMP`.
- Compatibility renderer; procedural/created assets only.

## Architecture Summary

- Thin autoloads: `GameState`, `SceneRouter`, `AudioManager`, `SettingsManager`.
- Scene-local controllers for levels, events, hallway variants, puzzles, and chase.
- Typed signal-driven progression with idempotent flags and serializable checkpoint snapshots.
- Reusable interaction base with a 1.5 m door sweep guard and reason-scoped movement-only locks; composed player components; deterministic procedural geometry/audio.
- Manifest-backed 70-cue English story voice playback plus a bounded entity-parented SFX presence cue at chase start/recovery.
- Native `SceneTree` test runner plus Godot headless import/runtime smoke checks.

## Scope Boundary

- Required: all acceptance items in the project brief, 15–20 minute main ending.
- Deferred: optional secondary ending, crouch, persistent save across application restarts, external art/prop packs, human-performed acting, non-English localization, and export templates/binary release. Generated English voiced dialogue is implemented for all 70 sequenced story lines.
- Never defer: ending, checkpoint/fail recovery, both puzzles, three memories, chase, settings, documentation, or main-path QA.

## Atomic Commit Sequence

1. `chore: initialize Godot project and repository metadata`
2. `docs: define Room 407 design and architecture`
3. `docs: add verified implementation plan`
4. `feat: add runtime services menu and player foundation`
5. `feat: add reusable interaction doors and objective HUD`
6. `feat: build lobby tutorial and fourth-floor transition`
7. `feat: add fuse puzzle and first horror events`
8. `feat: build dynamic memory hallway progression`
9. `feat: add memory pickups notes and radio puzzle`
10. `feat: build Room 407 finale and checkpoint flow`
11. `feat: add enemy chase fail recovery and ending`
12. `feat: add procedural audio visual effects and accessibility`
13. `test: add progression scene and regression checks`
14. `fix: harden progression against red-team edge cases`
15. `perf: reduce active lights and procedural update cost`
16. `docs: finalize run testing architecture and asset guides`
17. `build: prepare verified playable release candidate`

### Completion-Audit Commit Mapping — 2026-07-16

1. `4287337` — `docs: plan completion audit polish`
2. `1321971` — `fix(progression): enforce quest item and checkpoint invariants`
3. `4099a52` — `feat(horror): render fourth-floor and Room 407 scare beats`
4. `e4b8386` — `fix(chase): bound entity search and align floor body`
5. `4be615a` — `fix(audio): harden tone cache and spatial lifetime`
6. `f1bc63c` — `fix(visuals): make flashlight flicker pause-safe`
7. `c38fde9` — `fix(ui): restore menu focus and report save failures`
8. `fa8cc1f` — `docs: record completion audit polish evidence`
9. `46a58e8` — `test: add physical playthrough evidence runner`
10. `ba59df0` — `fix(test): reject faulty physical evidence logs`
11. `05ade4b` — `fix(test): bind physical evidence to clean revision`

### Voice and Post-Voice Hardening Mapping — 2026-07-16

1. `5b745b1` — `fix(player): delay initial flashlight flicker` (pushed)
2. `db736f4` — `feat(audio): add licensed story voice-over playback` (pushed)
3. `3c17663` — `test(audio): cover narration sequencing and fallback` (pushed)
4. `e1e8093` — `docs: document voice provenance and QA evidence` (pushed voice boundary)
5. `15b871c` — `docs: plan post-voice release hardening` (pushed)
6. `2e2abf2` — `fix(interaction): prevent door sweep collisions` (pushed)
7. `d5e6dfb` — `feat(audio): add positional chase entity cue` (pushed runtime boundary)

## Acceptance Criteria

- Godot recognizes the project; every referenced script parses and every main scene loads.
- Menu starts a completable 15–20 minute first-person flow with two puzzles, three memories, dynamic hallway, Room 407, chase, fail/checkpoint recovery, ending, and credits.
- Interaction spam/out-of-order actions cannot duplicate items/events/enemies or bypass required gates.
- All 20 sequenced narrative groups have 70 exact-manifest English voice cues with deterministic fallback, interruption, pause, queue, and teardown behavior.
- Settings cover sensitivity, FOV, volumes, display mode, head bob, shake, grain, and reduced flicker.
- Headless import, automated tests, runtime smoke, manual full playthrough, and red-team checklist have truthful recorded results.
- README, design, architecture, testing, asset credits, limitations, license, and changelog match actual code.
- Git history is atomic, working tree clean, no secrets/generated cache committed, and `main` pushed to the configured origin without force.

## Red Team Review

### Session — 2026-07-15

**Findings:** 5 (4 accepted, 1 rejected)
**Severity:** 1 Critical, 3 High, 1 Medium

| # | Finding | Severity | Disposition | Evidence / Applied To |
|---|---|---|---|---|
| RT-1 | Local CK/tooling tree can be staged into empty repo | Critical | Accept | `phase-01-repository-and-toolchain.md:48`; local exclude added to Phase 1 |
| RT-2 | Production smoke hook becomes a progression bypass | High | Accept | `phase-07-automated-qa-red-team-and-polish.md:37`; smoke kept test-only |
| RT-3 | Chase navigation has no readiness/fallback contract | High | Accept | `phase-05-room-407-chase-and-ending.md:62`; readiness and safe fallback added |
| RT-4 | Generated PCM cache has no memory/sample budget | High | Accept | `phase-06-audio-visual-ui-and-accessibility.md:45`; 16 MiB bounded budget added |
| RT-5 | Add persistent checkpoint save across process restart | Medium | Reject | Scope explicitly defers persistent save; brief permits in-memory checkpoint |

### Whole-Plan Consistency Sweep

- Files reread: `plan.md` and all eight phase files.
- Decision deltas checked: 4.
- Reconciled stale references: 4.
- Unresolved contradictions: 0.

## Validation Log

### Session 1 — 2026-07-15

**Trigger:** Deep-plan validation after red-team.
**New questions asked:** 0 — the user brief explicitly answers every material decision and instructs implementation to continue without reconfirmation unless unsafe.

### Verification Results

- Tier: Full.
- Claims checked: 144 structural, dependency, section, and scout-state claims across eight phases.
- Verified: 144 | Failed: 0 | Unverified: 0.
- Future `Create` paths were verified as planned artifacts, not falsely treated as existing code.
- Placeholder scan: 0; stale `[UNVERIFIED]` tags: 0.

### Confirmed Decisions from Explicit Brief

1. Scope: hold required 15–20 minute main path; defer only optional secondary ending, crouch, persistent checkpoint save, external asset packs, and binary export.
2. Toolchain: Godot 4.7.1 stable, GDScript, Compatibility renderer, portable/self-contained runtime on D:.
3. Content: project-created primitives, procedural materials/shaders/audio; no unclear copyrighted asset.
4. Delivery: sequential dependency order, small Conventional Commits, disk checks, no force push, exact GitHub origin.
5. Evidence: automation proves parse/state contracts; manual playthrough proves navigation, presentation, audio, and 15–20 minute pacing.

### Impact on Phases

- Phase 1 owns disk/tool/Git safety and local tooling exclusion.
- Phases 2–6 retain the full required gameplay scope.
- Phase 7 separates test-only smoke automation from production and requires manual timing/red-team evidence.
- Phase 8 defers binary export honestly while requiring source-playable verification and remote parity.

### Whole-Plan Consistency Sweep

- Files reread: `plan.md`, all eight `phase-*.md`, and both research reports.
- Decision deltas checked: 5.
- Reconciled stale references: 1 placeholder report path replaced with the exact plan-scoped path.
- Unresolved contradictions: 0.
- Recommendation: proceed with `ck:cook` sequential implementation.
