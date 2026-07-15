---
title: Room 407 Completion Audit
type: completion-audit
date: '2026-07-15T17:08:35+07:00'
source_commit: 1c225db
status: in-progress
phase_7_status: in-progress
phase_8_status: in-progress
---

# Summary

The source implementation has current automated, clean-clone, and renderer evidence. The pushed gameplay baseline ends at `40354eb`; runner-cleanup commit `d89e2c7` and user/maintainer documentation commit `1c225db` are also on `origin/main`. This audit is not a completion certificate. Phase 7 remains in progress because no authorized physical F5 keyboard/mouse run has established the complete route, chapter timings, or 15–20 minute total. Phase 8 has started documentation reconciliation and release auditing but also remains in progress.

## Requirements and Evidence

| Requirement | Current evidence | Audit state |
|---|---|---|
| Project imports and main scenes load in Godot 4.7.1 | Exact 12-check runner exits `0`, including editor import, boot scene, and gameplay scene | Automated evidence recorded |
| Continuous boot-to-credits flow completes in 15–20 minutes | State, progression, layout, movement, input, and chase-related checks pass; no authorized timed physical F5 run exists | Open |
| Wrong-order, spam, duplicate, and checkpoint cases preserve progression | Progression, checkpoint/layout, physical-route, player-input, and coverage slices are in the passing runner | Automated evidence recorded; full physical route still open |
| Settings and accessibility contract works | Settings/audio, persistence write, and persistence read checks pass; physical panel use, fullscreen transition, device output, and relaunch workflow remain manual | Partially evidenced |
| Visual presentation is readable in Compatibility renderer | A real local renderer frame is clean and readable | Local non-physical evidence only |
| Documentation matches verified behavior | User/maintainer guides are pushed at `1c225db`; plan references point to `docs/limitations.md`; this audit update remains local | In progress |
| Atomic history is pushed and final tree is clean/synced | Local `HEAD` and `origin/main` match at `1c225db` before this evidence-only plan/audit commit | Guide parity recorded; final audit-commit parity still open |
| Final release acceptance evidence is complete | Automated coverage exists, but manual playthrough, pacing, presentation, and final post-documentation Git gates remain | Not complete |

## Findings Fixed and Open

### Fixed or covered in pushed slices

- `160a0e3`: camera slice.
- `43be041`: audio-defaults slice.
- `5ef08d5`: visuals slice.
- `9ff9123`: UX/layers slice.
- `40354eb`: coverage slice, including the added player-input and visual-effects checks in the canonical runner.

### Open

- Authorized physical F5 boot-to-credits traversal with real keyboard/mouse input.
- Chapter timestamps and total duration against the 15–20 minute target.
- Human chase fairness, route readability, collision feel, and E/raycast interaction at every gate.
- Audible device output and full-game visual/audio balance.
- Physical Settings-panel save/close, comfort toggles, fullscreen transition, quit, and relaunch confirmation.
- This evidence-only plan/audit commit, final clean working tree, and post-push `HEAD`/`origin/main` parity.

## Changes

- Plan evidence now records the exact 12-check result, current pushed commit sequence, renderer boundary, disk readings, and open physical gate.
- Phase 7 keeps `status: in-progress`, updates the runner from 10 to 12 checks, and uses the real `docs/limitations.md` path.
- Phase 8 changes from pending to in progress, uses the real limitations path, and defines the evidence still required before closure.
- This report records the current release evidence without changing gameplay code or claiming completion.

## Automated Verification

Recorded command:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1
```

Recorded result: the canonical runner executed after the user/maintainer guide edits and before this evidence report was finalized. All 12 checks exited `0` from 17:04:29 through 17:05:02 ICT.

1. `editor-import`
2. `menu`
3. `gameplay`
4. `game-state`
5. `progression`
6. `checkpoint-layout`
7. `physical-route`
8. `player-input`
9. `visual-effects`
10. `settings-audio`
11. `settings-persistence-write`
12. `settings-persistence-read`

The runner proves its automated contracts only. This audit records the fresh automated run performed immediately before finalizing the evidence-only plan/report files; it does not execute a physical playthrough.

## Clean-Clone Verification

A fresh clone of `origin/main` at `1c225db` ran the README command with the official Godot 4.7.1 executable. It produced all 12 canonical logs, all 9 required success markers, zero temporary `godot-user-*` profiles, and zero tracked changes. The clone was removed only after its resolved absolute path matched the verified `.tmp\release-audit-*` prefix.

This proves reproducibility of import and the automated contracts from the pushed source. It does not replace the physical F5, pacing, presentation, chase-feel, or audible-output gates.

## Renderer Evidence

The local Compatibility-renderer frame `.artifacts/retro-overlay-v100000000.png` was visually inspected. Objective text, desk geometry, props, lighting, and the overlay are clean and readable with no obvious blank-frame or shader-corruption failure.

The frame is uncommitted local developer evidence and was not produced by an authorized physical F5 route. It does not prove full-game presentation, physical controls, chase feel, audible output, or pacing.

## Git Baseline and Pending Audit Commit

- Pushed gameplay/test sequence: `160a0e3` camera, `43be041` audio defaults, `5ef08d5` visuals, `9ff9123` UX/layers, and `40354eb` coverage.
- Pushed release-readiness sequence: `d89e2c7` isolated-profile cleanup and `1c225db` user/maintainer documentation.
- Before this evidence-only plan/audit commit, local `HEAD` and `origin/main` both resolve to `1c225db`.
- The current plan/phase/report edits are intentionally uncommitted at authoring time. Their post-push parity must be verified externally because a commit cannot include its own resulting hash.

## Disk

| Volume | Free space |
|---|---:|
| C: | 11.08 GiB |
| D: | 29.96 GiB |

These readings were recorded at 17:08 ICT after clean-clone rehearsal and safe clone removal; they are not a forecast of export or cache growth. Runner teardown left zero repository-local `godot-user-*` profiles.

## Remaining Gates

1. Obtain authorization for a physical F5 run and record boot-to-credits keyboard/mouse evidence.
2. Record lobby, fourth floor, memory loop, Room 407, chase, credits, and total timings; total must be 15–20 minutes.
3. During that run, verify every physical gate, one capture/recovery, chase fairness, reveal readability, audio balance, pause/settings behavior, comfort toggles, and settings persistence after relaunch.
4. Reconcile any defects found, rerun the exact 12-check suite, and preserve the manual evidence.
5. Commit this evidence-only plan/audit revision, prove a clean working tree, push without rewriting history, and confirm final `HEAD` equals `origin/main`.
6. Change Phase 7, Phase 8, and overall plan status only after all evidence exists.

## Recommendations

1. Treat the physical F5 run as the next release blocker; automation cannot substitute for it.
2. Use a timestamped capture or trace so each chapter and the total can be audited independently.
3. Keep the local renderer frame as diagnostic evidence only unless an approved release-capture workflow commits a verified gameplay image.
4. Repeat clean-clone automation only when runtime, tests, or README commands change; evidence-only plan/report edits require link, diff, secret, and Git-parity checks instead.

## Unresolved Questions

- Who is authorized to perform and record the physical F5 keyboard/mouse run?
- What are the measured chapter and total times from that run?
- Does target hardware confirm chase feel, visual/audio balance, fullscreen behavior, and physical Settings persistence?
