---
title: Final source consistency hardening
date: 2026-07-19
plan: ../../plans/260719-2235-final-source-consistency-hardening/plan.md
status: completed
---

# Final Source Consistency Hardening

## Context

The project was already source-complete at a broad level, but the final CK scout found
two runtime consistency defects and small repository-documentation drift. The goal was
to close every terminal-verifiable gap without using Computer Use or pretending that
automation can satisfy the human physical/perceptual release gate.

## What Happened

- Added failing-first coverage for the production player's `Variant` settings callback
  and for real PCM loop energy, seam motion, and preserved one-shot fade.
- Changed procedural drones to constant-amplitude, whole-cycle loops while keeping
  one-shot behavior, cache identity, ownership, and byte accounting stable.
- Made spatial tones unregister on parent-tree exit, not only finish or explicit stop.
- Aligned LF/security/historical-plan contracts and refreshed the active Windows export
  identity across evergreen docs and the physical operator handoff.
- The first mandatory review blocked on stale export fingerprints and weak silent-loop
  coverage. Two review-fix cycles closed both issues; the final review scored 10/10 with
  zero unresolved Critical, High, or Medium findings.

## Verification

- Godot 4.7.1 focused settings/audio check: pass.
- Canonical host suite: 12/12, clean regenerated logs.
- Physical-evidence regression, Windows export adversarial, fresh export and process
  smoke, packaging, docs/media, secrets, Compose config, and diff checks: pass.
- Final executable: `117920376` bytes; SHA-256
  `74ef9d12288a4f687f9d5a7de29cfc684737d2af98da97c90e80e77024099190`.

## Decisions

- Keep checkpoints process-local, procedural content, keyboard-first input, unsigned RC
  packaging, and external Docker Hub publication outside this hardening slice.
- Treat generated/headless evidence as contract proof only. It cannot certify rendered
  pacing, chase fairness, visual comfort, audible mix, or real keyboard/mouse behavior.
- Keep parent Phase 5/PDR-07 open until a human completes the documented production-
  window run and signs the perception matrix.

## Next

Run the dated Phase 5 operator handoff from a clean committed revision, using
`ProjectRun` preferably, retain the same-run capture and pacing payload, and complete the
human review matrix. The local Docker daemon was unavailable during this session; remote
CI evidence remains separate from registry publication.
