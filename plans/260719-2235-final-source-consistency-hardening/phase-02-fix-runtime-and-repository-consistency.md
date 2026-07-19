---
phase: 2
title: Fix runtime and repository consistency
status: completed
priority: P1
effort: small
dependencies:
  - 1
---

# Phase 2: Fix runtime and repository consistency

## Overview

Apply the smallest runtime fixes required by Phase 1, then reconcile factual repository
and historical-plan wording found by the documentation scout.

## Requirements

- Accept the `Variant` type promised by `SettingsManager.setting_changed`.
- Keep one-shot fade behavior; generate loops at constant amplitude over a nearest-whole
  cycle count so the two-second PCM boundary is periodic.
- Remove spatial-player registry entries immediately when their owning parent exits.
- Use LF consistently and distinguish local/unpublished exports from future binaries.
- Label old plan records as superseded without rewriting historical evidence.

## Related Code Files

- Modify: `scripts/player/player-controller.gd`
- Modify: `scripts/autoload/audio-manager.gd`
- Modify: `.editorconfig`, `SECURITY.md`
- Modify: `plans/260715-0936-room-407-the-last-shift/{plan.md,phase-08-documentation-release-and-push.md}`

## Refactor

1. Widen only the ignored callback argument from `float` to `Variant`.
2. Split loop phase/envelope math inside the existing PCM generator; preserve keys,
   byte accounting, ownership, player lifetime, and non-looping output behavior.
3. Remove the PowerShell CRLF override so EditorConfig agrees with Git attributes.
4. Add current-authority/superseded notes and correct only present-day cue/export claims.

## Implementation Steps

1. Patch runtime files, then run focused `settings-audio`.
2. Patch repository/docs files, then run repository-doc and diff checks.
3. Inspect the live diff for scope creep and public-contract changes.

## Success Criteria

- [x] Phase 1 regressions pass without weakening assertions.
- [x] One-shot fade and cache identity remain unchanged.
- [x] Spatial player ownership tears down on finish, stop, parent exit, and stop-all.
- [x] LF/security/historical-authority wording is internally consistent.
- [x] PDR-07 and human physical review remain explicitly open.

## Risk Assessment

Cycle alignment slightly quantizes arbitrary future loop frequencies (0.5 Hz at two
seconds). This is preferable to a seam and leaves all current 43/58 Hz calls exact.
