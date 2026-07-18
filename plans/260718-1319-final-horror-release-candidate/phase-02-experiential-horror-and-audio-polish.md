---
phase: 2
title: "Experiential horror and audio polish"
status: completed
effort: medium
---

# Phase 2: Experiential horror and audio polish

## Goal

Increase fear through contrast, spatial anticipation, and intelligible voice/SFX
coexistence—never random spam or progression mutation.

## Owned Files

- `scripts/autoload/audio-manager.gd`
- `scripts/audio/voice-over-player.gd`
- horror sequence/director/turn-away files as required
- `tests/settings-audio-test.gd`, `tests/voice-over-regression.gd`, `tests/progression-test.gd`

## Steps

1. Add an internal Voice bus routed through the existing SFX user control.
2. Add safe voice-keyed SFX ducking if Godot 4.7.1 supports an idempotent contract;
   otherwise enforce documented cue ceilings without a new setting.
3. Rebalance warnings, reveals, and tails; prevent simultaneous near-0 dB tones.
4. Strengthen fuse/cassette/rabbit/Room identities using timing and direction.
5. Add a short state-neutral pre-chase warning only if checkpoint/start races remain impossible.
6. Test bus/effect idempotence, settings inheritance, voice isolation, and teardown.

## Success Criteria

- [x] Voice is distinct internally but obeys the existing SFX setting.
- [x] Scene recreation cannot duplicate buses/effects.
- [x] Scares do not stop or replace voice.
- [x] Every new cue has unique ownership and deterministic cleanup.
- [x] Focused progression/settings-audio checks pass.
