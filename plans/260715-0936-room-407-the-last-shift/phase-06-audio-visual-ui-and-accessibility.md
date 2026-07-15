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

`AudioManager` caches generated `AudioStreamWAV` buffers by semantic ID and prevents duplicate named loops. `VisualSettingsApplier` broadcasts bounded comfort settings. A single lightweight canvas shader reads uniform toggles; level lights use a shared flicker component with capped frequency/intensity.

## File Inventory

| Action | Paths | Rough size | Test impact |
|---|---|---:|---|
| Create | `scripts/audio/{procedural-audio-factory,audio-cue}.gd` | <380 lines | generation/cache tests |
| Create | `scripts/visual/{light-flicker,visual-settings-applier}.gd` | <280 lines | bounds tests |
| Create | `shaders/ps1-screen.gdshader`, procedural materials/resources | <200 lines | compile/load checks |
| Create | `default_bus_layout.tres`, UI theme/resources | text resources | bus/UI tests |
| Modify | all authored levels for cues/lights/fog/subtitles | scoped scene edits | full-flow regression |
| Modify | settings panel, HUD, pause, note, fail, ending UI | <250 lines | UI navigation |

## Function and Interface Checklist

- [x] Generated audio is cached, amplitude-bounded, and assigned to semantic buses.
- [x] Procedural buffers are mono 16-bit at 22.05 kHz with bounded duration; total cached PCM stays below 16 MiB.
- [x] Named loop start is idempotent; `stop_all()` clears streams, players, cache, and byte accounting without leaks.
- [x] Flicker is bounded and can be disabled through settings.
- [x] Shader supports grain off and imports under the Compatibility renderer.
- [x] Important phone/radio/story content has English subtitles.

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
