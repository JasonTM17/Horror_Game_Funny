---
phase: 1
title: Add regression contracts
status: completed
priority: P1
effort: small
dependencies: []
---

# Phase 1: Add regression contracts

## Overview

Write failing-first coverage for the two scout findings without changing the canonical
twelve-check runner or success markers.

## Requirements

- Exercise a live `player.tscn` subscriber while boolean settings signals are emitted.
- Inspect signed PCM16 data, not only `loop_mode`, and reject a loop whose ending-window
  energy collapses relative to its beginning or whose seam exceeds normal sample steps.

## Related Code Files

- Modify: `tests/settings-audio-test.gd`

## Tests Before

1. Add a live-player boolean-signal regression inside `settings-audio`.
2. Add local PCM16 sample/energy helpers and loop-boundary assertions.
3. Run the focused scene and confirm the new assertions expose the current defects.

## Implementation Steps

1. Reuse the existing `settings-audio` lifecycle so the runner remains exactly 12 checks.
2. Keep fixtures isolated and teardown synchronous.
3. Preserve all existing cache, bus, voice, and persistence assertions.

## Success Criteria

- [x] Boolean settings emit through the production signal with a live production player.
- [x] Loop PCM regression measures actual data and fails the decaying-envelope fixture.
- [x] No thirteenth runner check or public marker is introduced.

## Risk Assessment

False-positive audio math could encode implementation details. Assert perceptual seam
properties (stable window energy and bounded seam step), not exact sample bytes.
