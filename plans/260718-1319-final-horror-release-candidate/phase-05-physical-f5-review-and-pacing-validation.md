---
phase: 5
title: Owner-waived physical review and pacing validation
status: completed
effort: large
---

# Phase 5: Owner-Waived Physical Review and Pacing Validation

## Goal

Resolve the physical/perceptual review requirement truthfully: preserve its optional
evidence path, record the owner's risk acceptance, and never present absent human
evidence as a passed playtest.

## Owner decision and disposition — 2026-07-19

The project owner explicitly waived a human physical production-window run and
perceptual review as project-closure requirements. No human boot-to-credits run,
same-run pacing package, listening pass, rendered chase/readability review, or physical
Settings/fullscreen/input check exists. The owner accepts those residual risks. This
phase therefore completes by documented waiver, not by successful human validation.

Automated route, input, audio, export, host, and container checks retain their narrower
meaning. The optional evidence workflow remains available if a later reviewer wants to
replace the accepted uncertainty with observed evidence.

## Optional future evidence path

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

## Closure Criteria

- [x] Owner waiver and acceptance date are recorded without claiming a human pass.
- [x] Missing pacing, chase, audio, visual, input, Settings, fullscreen, and comfort
  observations remain explicit residual risks.
- [x] Automated evidence is described only within its actual source/runtime/export scope.
- [x] Optional future evidence instructions remain available and fail closed.
- [x] Agent or headless evidence is not mislabeled as a human blind playtest.

## Automated basis and accepted boundary

- [x] Canonical host and Linux-container suites pass 12/12.
- [x] Synthesized route/input, settings/audio, scare lifecycle, checkpoint recovery,
  and pacing-payload contracts pass headlessly.
- [x] Windows x86_64 export and exported-process headless startup smoke pass.
- [x] Defects found by source review were fixed and reverified.
- [x] Owner accepts that rendered readability, audible balance, physical controls,
  full-duration pacing, chase feel, comfort, and visible credits remain unverified.

Current automated authority:
[final tester](../260719-0746-repository-evidence-closure/reports/tester-final-2026-07-19.md)
and [final reviewer](../260719-0746-repository-evidence-closure/reports/code-review-final-2026-07-19.md).
The reviewer verdict was Pass for staging and the delivery gates subsequently passed;
neither result is human approval, and this closure does not reinterpret it as one.

## Optional next owner

- A future human reviewer may use the
  [optional operator handoff](./reports/phase-05-operator-handoff-2026-07-18.md), with
  `ProjectRun` preferred. Any observed defect still routes to its source phase and
  requires automated re-verification before a new evidence claim is made.
