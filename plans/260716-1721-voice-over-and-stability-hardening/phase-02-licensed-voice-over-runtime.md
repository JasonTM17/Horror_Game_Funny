---
phase: 2
title: Licensed Voice-over Runtime
status: pending
dependencies:
  - 1
---

# Phase 2: Licensed Voice-over Runtime

## Design

- Generate English narration offline from Piper `en_US-kristin-medium`, whose
  model card records public-domain LibriVox training audio and training from
  scratch. Apply deterministic FFmpeg filters for manager, radio/protagonist,
  mother, child, and whisper identities.
- Keep a text/cue/role manifest as the single source of truth. Commit only
  normalized mono OGG outputs plus the manifest and generation script.
- Add a small scene-local voice player/catalog beside `NarrativeSequencer`.
  Derive stable cue IDs from the completion flag and line index so existing
  callers do not require a signature change.
- Route playback through `SFX`; retain the procedural dialogue tick only when
  a cue is absent.

## Files

- Create `assets/audio/voice-over/*.ogg`.
- Create `assets/audio/voice-over/voice-over-manifest.json`.
- Create `tools/generate-voice-over.ps1`.
- Create `scripts/audio/voice-over-player.gd`.
- Modify `scripts/world/narrative-sequencer.gd`.

## Validation

- Manifest text matches every source line selected for voice.
- All referenced OGG resources import, report nonzero duration, and remain
  beneath the agreed compact asset budget.
- Playback wait time is at least the cue duration plus readable padding.
- Pause, replacement, queue completion, and scene teardown are deterministic.

