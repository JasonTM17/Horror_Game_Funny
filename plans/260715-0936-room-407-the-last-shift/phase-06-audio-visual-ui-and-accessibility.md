---
phase: 6
title: Audio Visual UI and Accessibility
status: completed
priority: P1
dependencies:
  - 5
effort: large
---

# Phase 6: Audio Visual UI and Accessibility

## Overview

Polish the complete game with cached procedural audio, positional ambience, low-cost PS1 visual treatment, lighting/fog, full menu/HUD/note/fail/credits consistency, subtitles, and accessibility settings.

## Context Links

- [Plan](./plan.md)
- [Architecture research](./research/researcher-01-godot-architecture.md)

## Requirements

- Master/Music/SFX/Ambience buses; ambient, one-shot, footstep, door, radio, sting, enemy, chase streams.
- Cold low-poly lighting, fog, optional grain/dither, restrained flicker/shake/vignette.
- Settings: sensitivity, FOV, volumes, fullscreen/windowed, head bob, shake, grain, reduced flicker, reset.
- English UI and subtitles for every important phone/radio/story line.

## Architecture

`AudioManager` caches generated `AudioStreamWAV` buffers by a parameter-complete semantic key (ID, sample rate, frequency, effective duration, and loop mode), uses a 16 MiB LRU budget, protects streams held by regular/spatial players, and tears down players synchronously. `scripts/player/player-flashlight.gd` owns bounded flicker pulses and explicitly runs as `PROCESS_MODE_PAUSABLE`. `VisualEffectsLayer` drives the single Compatibility canvas shader; the authored UI scenes own settings, modal focus, and save-error handling.

## File Inventory

| Action | Paths | Rough size | Test impact |
|---|---|---:|---|
| Maintain | `scripts/autoload/audio-manager.gd` | generated PCM/cache service | variant/LRU/lifetime tests |
| Maintain | `scripts/player/player-flashlight.gd` | bounded pulse component | bounds and pause tests |
| Maintain | `scripts/ui/visual-effects-layer.gd`, `shaders/retro-screen-overlay.gdshader` | Compatibility retro treatment | import/uniform tests |
| Maintain | `scripts/autoload/settings-manager.gd`, `scripts/ui/{settings-panel,pause-menu,boot-menu}.gd`, `scenes/ui/settings-panel.tscn` | settings, modal focus, persistence UX | UI/persistence tests |
| Modify | runtime world/UI controllers for cues/lights/fog/subtitles | scoped scene/runtime edits | full-flow regression |

## Function and Interface Checklist

- [x] Generated audio is cached, amplitude-bounded, and assigned to semantic buses.
- [x] Procedural buffers are mono 16-bit at 22.05 kHz with bounded duration; total cached PCM stays below 16 MiB.
- [x] Named loop start is idempotent; `stop_all()` clears streams, players, cache, and byte accounting without leaks.
- [x] Cache identity includes pitch/duration/loop variants; LRU eviction protects live regular/spatial streams and stop paths reclaim exact accounting.
- [x] Flicker is bounded, pause-safe, resets to base energy when disabled/hidden, and can be disabled through settings.
- [x] Shader supports grain off and imports under the Compatibility renderer.
- [x] Important phone/radio/story content has English subtitles.
- [x] Settings save failures return an error, remain visible in the modal, and offer retry or session-only discard; boot/pause focus returns to the launcher.

## Dependency Map

`complete gameplay -> semantic audio cues + lighting hooks -> settings application -> full-flow polish -> Phase 7`

## Implementation Steps

1. Configure buses and implement cached procedural tones/noise/impulses with safe amplitude.
2. Attach positional cues, ambience zones, footsteps, doors, radio, stings, entity, and chase drone.
3. Add Compatibility-safe fog/material palette and optional low-resolution grain/dither shader.
4. Add bounded flicker, flashlight tuning, shadow budget, and guidance lighting.
5. Finish all UI states, subtitles, keyboard navigation, and settings persistence/reset.
6. Run full playthrough at default and reduced-effects settings; normalize volume and darkness.
7. Profile node/light/process counts and remove inactive processing.
8. Commit feature polish then performance adjustments separately.

## Atomic Commit Checkpoints

- `feat: add procedural audio visual effects and accessibility`
- `perf: reduce active lights and procedural update cost`

## Test Scenario Matrix

| Priority | Scenario | Expected |
|---|---|---|
| Critical | Disable grain/bob/shake/reduce flicker | immediate stable visual behavior |
| Critical | Repeated scene/reload | no stacked loop or duplicate bus/service |
| High | Volume/FOV/sensitivity extremes | clamped, persisted, resettable |
| High | Compatibility renderer shader import | no compile error or blank frame |
| Medium | Darkness/subtitles | route readable; story understandable without audio |

## Success Criteria

- [x] Every required sound category has an authored procedural cue or drone.
- [x] PS1 treatment, fog, flashlight, grain toggle, flicker toggle, head bob, and camera shake settings are implemented.
- [ ] Manual visual/audio pass confirms cohesive readability, comfort, and balance on real hardware.
- [x] Menus/HUD/subtitles/fail/credits states are implemented in English.
- [x] Settings use bounded defaults and write to `user://room407.cfg`; automated tests use an isolated profile.
- [x] Separate isolated Godot processes verify all 11 settings persist through save, quit, autoload, and reload.
- [ ] Manual Settings-panel save/quit/relaunch verifies physical controls and fullscreen behavior.
- [x] Active shadow-light cost was reduced in a focused performance commit.

## Risks and Mitigation

| Risk | Mitigation |
|---|---|
| Synthetic audio is harsh | envelope, filtering/low amplitude, manual peak listening |
| Shader hurts low-end GPUs | one optional single-pass shader; Compatibility syntax only |
| Flicker discomfort | slow cap, reduced setting, no full-screen rapid flashes |

## Security and Licensing

All audio, shaders, UI, materials, and vector graphics are created specifically for the project and recorded in asset credits.

## Next Steps

- Phase 7 performs automated regression, manual QA, and adversarial progression hardening.

## Evidence Reconciliation — 2026-07-16

- `4be615a` hardens the generated-tone cache: complete keys, four-second effective-duration cap, true LRU under 16 MiB, live-player protection, spatial lifetime cleanup, and deterministic `stop_tone()`/`stop_all()` teardown.
- `f1bc63c` bounds flashlight interval/pulse/energy and keeps the component pausable, with reset behavior when disabled or hidden.
- `c38fde9` completes the settings UX slice: `save_settings()` error propagation, visible retry/discard state, full-rect modal blocking, boot/pause focus return, and hidden-control focus release.
- The exact twelve-check runner and focused settings/audio checks pass. `menu-settings-regression.gd` is invoked inside `settings-audio`; it does not create a thirteenth runner check.
- Manual visual/audio balance, rendered comfort/readability, physical Settings save/fullscreen behavior, and the physical F5 route remain unchecked and are intentionally carried into Phase 7.
