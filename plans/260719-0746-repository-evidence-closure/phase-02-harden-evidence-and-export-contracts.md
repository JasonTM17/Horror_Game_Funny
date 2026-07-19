---
phase: 2
title: Harden evidence and export contracts
status: in-progress
effort: medium
---

# Phase 2: Harden evidence and export contracts

## Overview

Resolve only Phase 1 defects, then verify focused edge cases before the full suite.

## Prerequisites and inventory

- Phase 1 finding list is complete.
- Primary files: the three PowerShell test/runner paths, CI cover check, and only the
  documentation paths whose wording changes with proven behavior.

## Steps

1. Preserve the existing evidence summary schema and manual-review boundary while
   correcting any proven stale/replay, reparse, TOCTOU, hash/size, or cleanup defect.
2. Keep baseline archival and source clearing fail-closed; a rejected candidate must
   remain diagnosable without becoming an accepted pacing payload.
3. Extend the isolated focused regression for each changed branch. It must never launch
   Godot or manufacture a release-ready evidence package.
4. Preserve Windows verifier/preset/manifest/lock/rollback contracts. Add adversarial
   coverage only when a concrete mutation or containment gap exists.
5. Keep the cover check dependency-free: canonical PNG header/IHDR and exact dimensions;
   do not treat pixel content as automated artistic approval.
6. Run PowerShell parsing and the two focused harnesses after each relevant edit; clean
   temporary profiles, processes, and test copies without touching accepted bundles.

## Focused commands

```powershell
[void][scriptblock]::Create((Get-Content -Raw tests/run-physical-playthrough.ps1))
[void][scriptblock]::Create((Get-Content -Raw tests/physical-playthrough-evidence-regression.ps1))
[void][scriptblock]::Create((Get-Content -Raw tests/windows-export-adversarial.ps1))
powershell -NoProfile -ExecutionPolicy Bypass -File tests/physical-playthrough-evidence-regression.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/windows-export-adversarial.ps1
```

## Success criteria

- [x] Every edit closes a recorded finding and has focused failure-path coverage.
- [x] Stale, baseline-identical, mixed, reparse, size/hash-mismatched evidence is rejected.
- [x] Export negative tests preserve verified active and rollback bundles.
- [x] Focused scripts parse and emit their unique success markers with exit code 0.
- [x] Exact twelve-check and public runtime/export contracts remain unchanged.

## Result

Completed against the Phase 1 blockers. Fresh focused markers, the 12/12 host suite,
packaging/export evidence, and cycle-2 review are recorded in the child reports.

## Non-goals and risks

- Do not harden speculative races by weakening portability or inventing a new protocol.
- Do not add runtime/gameplay work, a thirteenth canonical check, or physical claims.
