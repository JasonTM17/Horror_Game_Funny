---
phase: 5
title: "Physical F5 review and pacing validation"
status: in-progress
effort: large
---

# Phase 5: Physical F5 review and pacing validation

## Goal

Exercise the production window from boot to visible credits with OS-level input and
retain same-run artifacts without overstating agent-driven evidence.

## Current execution constraint

The user explicitly requested background/headless self-testing without desktop,
mouse, or keyboard control. No agent-driven computer-control run is authorized under
that instruction. Automated route, input, audio, export, host, and container checks
are complete, but they do not replace this physical/perceptual gate. Leave the phase
open until the user later chooses to perform or explicitly authorize a real-window
review.

## Steps

1. Do not invoke computer control unless the user explicitly reverses the current
   no-desktop-control instruction.
2. Start the evidence runner in EditorF5 mode without falsely asserting human input.
3. Start fresh, traverse every action, fail/recover once during chase, test pause/settings/
   fullscreen/comfort, and reach credits.
4. Preserve same-run capture, raw log, and unique pacing payload.
5. Review objective clarity, scare timing/readability, chase fairness, audio balance,
   focus/relaunch/fullscreen, and comfort row by row.
6. Route any defect back to its source phase, repeat Phase 4, then repeat the run.

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
