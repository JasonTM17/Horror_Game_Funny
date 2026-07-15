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

`tests/run-headless-tests.ps1` launches ten native Godot checks, isolates temp and user-data paths below the repository, scans logs for assertion/engine/leak failures, and exits nonzero on failure. Scene smoke checks load boot/gameplay; focused GDScript scenes exercise state, semantic progression, layout/checkpoint/chase, targeted production-player movement/door collision, settings/audio contracts, and two-process config persistence. Guaranteed teardown removes the isolated profile. No production script recognizes a test bypass.

## File Inventory

| Action | Paths | Rough size | Test impact |
|---|---|---:|---|
| Create | `tests/{run-tests,test-game-state,test-interactions,test-puzzles,test-checkpoint,test-settings}.gd` | <900 lines total | core regression |
| Create | `tests/smoke-runner.gd` | <220 lines | runtime flow without production bypass |
| Create | `plans/260715-0936-room-407-the-last-shift/reports/{test,red-team,code-review}-report.md` | reports | audit evidence |
| Modify | only implementation files with evidence-backed defects | scoped | regression fixes |
| Modify | `docs/testing.md`, `docs/known-limitations.md` | <250 lines | truthful QA contract |

## Function and Interface Checklist

- [x] Test runner returns nonzero, names the failing check/assertion, and rejects leak warnings.
- [x] All harness code lives under `tests/`; production scripts recognize no debug bypass argument.
- [ ] Every required progression gate has positive and negative tests.
- [x] Red-team fixes preserve the accepted continuous flow and checkpoint semantics across the covered regressions.
- [x] Independent final review checked the committed gameplay/UI/test range and rejected stale findings against final code.

## Dependency Map

`polished complete flow -> import tests -> behavior tests -> smoke -> manual timing -> red-team/review -> fixes -> rerun -> Phase 8`

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

- [x] Headless import, boot/gameplay smoke, and all focused automated checks pass with ten logs.
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

- Phase 8 reconciles docs with verified reality and performs the final release/push audit.
