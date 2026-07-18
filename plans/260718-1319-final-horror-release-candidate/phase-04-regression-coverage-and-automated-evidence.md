---
phase: 4
title: "Regression coverage and automated evidence"
status: completed
effort: medium
---

# Phase 4: Regression coverage and automated evidence

## Goal

Prove the final source blast radius and obtain mandatory tester/adversarial review before release claims.

## Steps

1. Run all owning focused checks, then the canonical Windows twelve-check suite.
2. Verify exactly 12 logs, required markers, zero current scanner failures, and no leftover profiles.
3. Run Docker packaging verification/container suite when available.
4. Delegate mandatory tester and code review against the contract/evidence map.
5. Fix all Critical/High/Medium findings and rerun affected focused/full suites.
6. Record commands, revision, elapsed time, log inventory, limits, and review result in a dated report.

## Canonical Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1 `
  -Godot D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe
```

## Success Criteria

- [x] Final source passes all 12 checks with clean current logs.
- [x] Tester and reviewer find no unresolved Critical/High/Medium defects.
- [x] Public contracts and callers of touched services are reviewed.
- [x] Report separates automated proof from perceptual unknowns.
