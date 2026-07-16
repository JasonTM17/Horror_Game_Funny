---
title: Voice-over and Stability Hardening
description: >-
  Fix reproducible release-blocking defects and add licensed English story
  voice-over synchronized with the existing subtitle flow.
status: in-progress
priority: P1
branch: main
tags:
  - bugfix
  - audio
  - godot
created: '2026-07-16T17:21:10+07:00'
createdBy: ck:cook
---

# Voice-over and Stability Hardening

## Outcome

Turn the current silent subtitle sequences into audible story delivery without
breaking the one-piece 15–20 minute route, and remove defects that make the
release/evidence workflow unreliable. The current English UI establishes the
default voice language for this slice; localization is separate scope.

## Phases

| Phase | Name | Status |
|---|---|---|
| 1 | [Reproduction and project stability](./phase-01-reproduction-and-project-stability.md) | In progress |
| 2 | [Licensed voice-over runtime](./phase-02-licensed-voice-over-runtime.md) | Pending |
| 3 | [Regression, review, and delivery](./phase-03-regression-review-and-delivery.md) | Pending |

## Acceptance Criteria

- A Godot 4.7.1 editor import/open no longer changes tracked project settings.
- Every mandatory character line in the phone, radio, and Room 407 recording
  has a committed OGG cue; important environmental whispers may also be voiced.
- Voice uses the existing SFX volume path, remains pause-aware, never overlaps
  the next line, and stops when the sequencer or gameplay scene exits.
- Subtitles remain the accessibility source of truth. Missing/unloadable audio
  falls back to the existing timed subtitle and dialogue tick without blocking
  progression.
- Existing `NarrativeSequencer.play(lines, completion_flag, seconds_per_line)`
  callers remain compatible.
- The exact twelve-check headless suite passes from a clean worktree with no
  engine/script/leak failures or leftover Godot test profiles.
- Voice provenance, attribution, regeneration process, and remaining manual
  audio gates are documented truthfully.
- Each verified cluster ends with disk/secrets/status checks, a focused
  Conventional Commit, and a non-force push to `origin/main`.

## Boundaries

- No paid/cloud TTS dependency at runtime.
- Do not commit Piper binaries, Python environments, model weights, WAV
  intermediates, caches, or user data.
- No Blender work: this slice fixes playability, configuration, and audio.
- No claim of audible balance or full physical-route completion without a
  future authorized physical Godot run.

## Commit Sequence

1. `fix(config): keep project settings stable in Godot editor`
2. `feat(audio): add licensed story voice-over playback`
3. `test(audio): cover voice sequencing and fallback`
4. `docs: document voice provenance and QA evidence`

## Risks and Rollback

- Generated speech may be intelligible but stylized. Preserve subtitles and
  source manifest so individual cues can be replaced without code changes.
- Audio imports increase repository size. Use mono 22.05 kHz OGG and check both
  disks before/after generation.
- If a cue fails to import, the runtime must degrade to subtitle timing rather
  than aborting the narrative queue.

