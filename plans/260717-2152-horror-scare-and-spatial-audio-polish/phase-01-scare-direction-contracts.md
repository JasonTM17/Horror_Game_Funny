---
phase: 1
title: "Scare direction contracts"
status: in-progress
effort: "small"
---

# Phase 1: Scare direction contracts

## Overview

Audit current trigger timing, audio ownership, lights, cleanup, and tests. Lock a
four-beat direction contract before production edits.

## Implementation Steps

1. Map each story trigger to anticipation, reveal, and aftermath actions.
2. Preserve one-shot `GameState` guards and state-neutral visual/audio behavior.
3. Define shared helper ownership, pause-safe timers, bounded spatial range, unique
   cue IDs, actor/light restoration, and director-exit cleanup.
4. Define regression assertions before implementation.

## Success Criteria

- [x] Existing scare/audio/light contracts inspected.
- [x] Scope and acceptance criteria recorded in `plan.md`.
- [ ] Plan validates and receives implementation review.
