---
phase: 7
title: Automated QA Red Team and Polish
status: in-progress
priority: P1
dependencies:
  - 6
effort: large
---

# Phase 7: Automated QA Red Team and Polish

## Overview

Add native headless tests and an external test-only runtime smoke runner, then execute architecture review, full playthrough timing, and the complete adversarial progression checklist. Fix proven defects without weakening gates.

## Context Links

- [Plan](./plan.md)
- [Pacing/QA research](./research/researcher-02-game-design-and-qa.md)

## Requirements

- Parse/import all scripts and main scenes.
- Test state, doors, fuse, memories, radio, one-shot events, checkpoint, chase reset, ending, pause/settings.
- Run manual main-path and red-team tests including wrong order, spam, trigger escape, pause/death races, and restart.
- Review architecture, naming, coupling, performance, UX, case sensitivity, secrets, and Git state.

## Architecture

`tests/run-headless-tests.ps1` launches 12 native Godot checks, isolates temp and user-data paths below the repository, scans logs for assertion/engine/leak failures, and exits nonzero on failure. Scene smoke checks load boot/gameplay; focused GDScript scenes exercise state, semantic progression, layout/checkpoint/chase, targeted production-player movement/door collision, player input, visual effects, settings/audio contracts, and two-process config persistence. Guaranteed teardown removes the isolated profile. No production script recognizes a test bypass.

## File Inventory

| Action | Paths | Rough size | Test impact |
|---|---|---:|---|
| Maintain | `tests/run-headless-tests.ps1`, `tests/game-state-test.gd`, and scene-backed `tests/{progression,checkpoint-layout,physical-route-smoke,player-input-integration,visual-effects,settings-audio,settings-persistence-write,settings-persistence-read}-test.{gd,tscn}` | focused harnesses | exact twelve-check regression |
| Maintain | `tests/menu-settings-regression.gd` | nested helper | Settings/modal focus contract inside check 10 |
| Maintain | `plans/260715-0936-room-407-the-last-shift/reports/*.md` | reports | audit evidence |
| Modify | only implementation files with evidence-backed defects | scoped | regression fixes |
| Modify | `docs/testing.md`, `docs/limitations.md` | <250 lines | truthful QA contract |

## Function and Interface Checklist

- [x] Test runner returns nonzero, names the failing check/assertion, and rejects leak warnings.
- [x] All harness code lives under `tests/`; production scripts recognize no debug bypass argument.
- [x] Every required semantic progression gate has positive and negative automated coverage; physical E/raycast and full-route cases remain manual.
- [x] Red-team fixes preserve the accepted continuous flow and checkpoint semantics across the covered regressions.
- [x] Independent final review checked the committed gameplay/UI/test range and rejected stale findings against final code.

## Current Evidence — 2026-07-16

- The completion-audit polish commits are pushed in order: `4287337` (plan audit), `1321971` (progression/checkpoint invariants), `4099a52` (fourth-floor and Room 407 scare dressing), `e4b8386` (bounded chase/body alignment), `4be615a` (audio cache/spatial lifetime), `f1bc63c` (pause-safe flashlight), and `c38fde9` (modal focus/save-failure UX). Local `HEAD` and `origin/main` matched at `c38fde9` before this documentation edit.
- The exact 12-check runner exits `0`; the current canonical run produced 12 logs, all 9 required markers, zero scanned bad lines, and zero temporary Godot profiles. The fresh compressed pacing payload measured 6.58 s active, 6.82 s wall, and 0.22 s paused, with complete/order-valid telemetry and `within_target: false` by design. Checkpoint/layout remains correctly incomplete/ineligible with a null total verdict.
- `menu-settings-regression.gd` exercises save failure/retry/discard, modal focus trapping, launcher focus return, and hidden-control release inside `settings-audio`; it is not a thirteenth runner check.
- Generated/credential/tracked-binary scans are clean; a clean clone at SHA `c38fde9` independently reproduced `SuiteExit 0`, 12 logs, 9 markers, 0 bad lines, 0 temporary profiles, and 0 dirty lines before removal from the verified repository-local temp root.
- Disk after the clean-clone rehearsal: C: 11.97 GiB free; D: 33.05 GiB free. The isolated runner left zero `godot-user-*` profiles behind.
- No authorized physical F5 keyboard/mouse run has recorded the complete route with a same-run eligible, complete, actual-order-valid 900–1200 second payload or the chase/presentation/audio/settings matrix. Phase 7 remains in progress.

## Dependency Map

`polished complete flow -> import tests -> behavior tests -> smoke -> manual timing -> red-team/review -> fixes -> rerun -> Phase 8`

## Completion-Audit Polish Slice — 2026-07-15

### Expected Output

The existing continuous scene keeps its route and public controls, while consumed quest items, pre-Room checkpoint placement, door guards, rendered scare beats, chase entity physics/state behavior, synthesized audio variation, flicker comfort, and menu/settings focus/error handling match the brief. Every correction receives a focused regression and the unchanged twelve-check runner remains the broad gate.

### Acceptance Criteria

- The installed fuse cannot reappear in inventory or regain a prompt after backtracking.
- The floor door requires the granted key once; key consumption and the session-level permanent unlock are atomic and idempotent, and the door reopens without restoring the key.
- Completing the radio sequence creates `room_entrance` before the Room 407 door; crossing the room threshold cannot overwrite it, while later explicit checkpoints such as `chase_start` can supersede it for capture recovery.
- Door prompt and interaction overrides honor `interaction_enabled`, base cooldown, movement lock, flag guards, and required-item guards before starting any tween. A rejected interaction produces no tween, motion audio, cooldown, item consumption, or door-state mutation.
- Crossing the fourth-floor threshold once changes a rendered elevator display, closes the real floor door behind the player, and creates a distant non-damaging apparition; repeating the threshold cannot duplicate the event.
- Room 407 receives bounded procedural dressing and a visible pre-chase manifestation. Chase dressing cannot block the central navigation lane or add expensive lights/shadows; scare actors clean up deterministically and guarded events reset safely with a new run.
- Audio cache identity includes ID and every sample-rendering parameter; identical parameters reuse one sample, distinct pitch/duration parameters do not, and stop/eviction paths reclaim exact cached-byte accounting.
- Flashlight flicker uses a minimum interval and maximum pulse duration, restores base energy when disabled, and cannot advance timers, RNG, or energy while the tree is paused.
- The production chase entity capsule starts above the floor without test-only Y correction. Deterministic regressions prove that APPEAR pauses, STALK advances slowly, CHASE uses full pursuit, LOST_TARGET/SEARCH use the last seen position, and DESPAWN stops movement.
- Boot and pause menus establish keyboard focus; closing Settings returns focus to its caller. A failed config save is surfaced and never documented as successful persistence.
- Focused checks pass repeatedly, the exact twelve-check runner exits `0`, diff/secret/generated-file audits pass, and each coherent group is committed and pushed without force.

### Scope Boundary

No Blender/MCP assets, binary export, persistent gameplay save, crouch, secondary ending, new level split, extra autoload, paid/unclear asset, or automated claim of physical 15–20 minute completion. Manual F5, audible mix, rendered comfort/readability, fullscreen behavior, and chase feel remain open evidence.

### Touchpoints

- Progression: `scripts/world/{gameplay-director,story-progression-controller,continuous-story-layout}.gd`, `scripts/interaction/door-interactable.gd`, `scripts/ui/hud.gd`.
- Presentation: `scripts/world/{continuous-world-builder,horror-event-director,chase-sequence-controller,chase-entity}.gd`.
- Audio/accessibility/UI: `scripts/autoload/{audio-manager,settings-manager}.gd`, `scripts/player/player-flashlight.gd`, `scripts/ui/{boot-menu,pause-menu,settings-panel}.gd`.
- Regression: existing `progression`, `checkpoint-layout`, `physical-route`, `player-input`, and `settings-audio` checks; `tests/menu-settings-regression.gd` is nested in `settings-audio`, so there is no thirteenth runner entry.

### Atomic Commit Checkpoints

1. `docs: plan completion audit polish`
2. `fix(progression): enforce quest item and checkpoint invariants`
3. `feat(horror): render fourth-floor and Room 407 scare beats`
4. `fix(chase): bound entity search and align floor body`
5. `fix(audio): harden tone cache and spatial lifetime`
6. `fix(visuals): make flashlight flicker pause-safe`
7. `fix(ui): restore menu focus and report save failures`
8. `docs: record completion audit polish evidence`

## Implementation Steps

1. Build deterministic test harness and focused state/interaction/puzzle/checkpoint/settings suites.
2. Add CLI smoke runner for scene load and guarded main progression.
3. Run headless editor import, automated suite, and runtime smoke; archive logs on D: only.
4. Run two manual paths: default full playthrough and checkpoint/restart path; record timing.
5. Execute every red-team item from the brief and record evidence.
6. Review architecture/coupling/naming/performance/UX/Git and classify findings by severity.
7. Fix confirmed defects in small scopes; rerun all affected and broad checks.
8. Commit tests, red-team fixes, and performance changes separately.

## Atomic Commit Checkpoints

- `test: add progression scene and regression checks`
- `fix: harden progression against red-team edge cases`
- Additional `fix(scope): ...` only for proven independent defects.

## Test Scenario Matrix

| Priority | Scenario | Expected |
|---|---|---|
| Critical | Full fresh progression | ending/credits in 15–20 minutes; no soft-lock |
| Critical | All wrong-order/spam/duplicate cases | invariant preserved and feedback shown |
| Critical | Pause/death/scene-change race | one checkpoint restore, valid input/audio/entity |
| High | Case/path/import from clean cache | no missing resource or parse errors |
| High | Reduced effects and settings persistence | stable and bounded |
| Medium | Runtime smoke repeated three times | deterministic success/no leaked singleton |

## Success Criteria

- [x] Headless import, boot/gameplay smoke, and all focused automated checks pass with 12 logs and runner exit `0`.
- [ ] Manual full flow completes in target duration with no known main-path soft-lock.
- [ ] Every red-team checklist item has pass/fix/known-limitation evidence.
- [ ] All release blockers are closed; automated review defects are fixed, but manual pacing/chase evidence remains.
- [x] Git diff/check and tracked-secret/generated-file scans pass for the final QA/fix commits.

## Risks and Mitigation

| Risk | Mitigation |
|---|---|
| Headless tests overclaim 3D behavior | separate manual navigation/collision/audio evidence |
| Smoke runner masks production behavior | keep it outside production autoloads/scripts and exercise public interactions/state gates only |
| Fixes regress earlier chapters | rerun focused then entire suite/full flow |

## Security and Licensing

Test logs stay ignored and are reviewed for local paths or credentials before any excerpts enter reports.

## Next Steps

- Complete and record an authorized physical F5 keyboard/mouse boot-to-credits run before changing Phase 7 to completed.
- Preserve that run's complete capture and `PLAYTHROUGH_PACING: ` payload together; automation or a Continue session cannot substitute for it.
- Phase 8 documentation reconciliation and release auditing can continue, but final release closure remains dependent on the open Phase 7 evidence.
