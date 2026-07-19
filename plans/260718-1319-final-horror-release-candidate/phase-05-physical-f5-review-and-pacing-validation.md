---
phase: 5
title: "Human physical production-window review and pacing validation"
status: in-progress
effort: large
---

# Phase 5: Human Physical Production-Window Review and Pacing Validation

## Goal

Exercise the production window from boot to visible credits with OS-level input and
retain same-run artifacts without overstating agent-driven evidence.

## Current execution constraint

The source/docs closure is delivered: `c28beeed7a4bafd871e09225152f329beac09e9a`
contains the report set, the real-index gate emitted all four success markers, remote
parity reached 0/0, and both matching CI workflows passed. Automated route, input, audio,
export, host, and container checks still do not replace this physical/perceptual gate.
Leave the phase open until a human runs the current clean pushed `main`, watches its same-
run capture, and signs the review matrix.

## Steps

1. Do not treat agent-driven computer control as the authorized human review.
2. Prefer the evidence runner in **ProjectRun** mode so `--log-file` binds to the game
   process. Use `-LaunchMode EditorF5` only when the editor is required; that path
   does not attach `--log-file` to the F5 game process and depends on the
   `user://playthrough_pacing_last.txt` side-channel after credits. Never pass
   `-ConfirmPhysicalInput` unless a human actually used keyboard/mouse.
3. Start fresh with **START SHIFT** (not Continue), traverse every action, fail/recover
   once during chase, test pause/settings/fullscreen/comfort, and reach credits.
4. Preserve the same-run capture, bounded raw/combined logs, and unique pacing payload;
   every verified side-channel must contain exactly one canonical payload.
5. Review objective clarity, scare timing/readability, chase fairness, audio balance,
   focus/relaunch/fullscreen, and comfort row by row.
6. Route any defect back to its source phase, repeat automated regressions, then
   repeat the physical run.

## Success Criteria

- [ ] Fresh production boot reaches visible credits with OS-level keyboard/mouse input.
- [ ] Capture/log/pacing payload belong to the same run.
- [ ] Fail/recover, Settings/fullscreen, chase, and ending are exercised.
- [ ] Found defects are fixed and reverified.
- [ ] Agent evidence is not mislabeled as a human blind playtest.

## Automated substitute evidence (not completion proof)

- [x] Canonical host and Linux-container suites pass 12/12.
- [x] Synthesized route/input, settings/audio, scare lifecycle, checkpoint recovery,
  and pacing-payload contracts pass headlessly.
- [x] Windows x86_64 export and exported-process headless startup smoke pass.
- [x] Defects found by source review were fixed and reverified.
- [ ] Rendered readability, audible balance, physical controls, full-duration pacing,
  chase feel, comfort, and visible credits remain human/physical observations.

Current automated authority:
[final tester](../260719-0746-repository-evidence-closure/reports/tester-final-2026-07-19.md)
and [final reviewer](../260719-0746-repository-evidence-closure/reports/code-review-final-2026-07-19.md).
The reviewer verdict was Pass for staging and the delivery gates subsequently passed;
neither result is human approval.

## Next owner and done definition

- Human release reviewer: use the
  [operator handoff](./reports/phase-05-operator-handoff-2026-07-18.md), with `ProjectRun`
  preferred. Done only when all five human success criteria and the perception matrix are
  evidence-backed; any defect routes to its source phase and forces a rerun.
