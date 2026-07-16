# ROOM 407: THE LAST SHIFT

A short first-person psychological horror game built with Godot 4.7.1 and GDScript. A student covering a night shift enters a condemned apartment block after a call points to a floor that should have been sealed for years.

The implemented path keeps the lobby, fourth-floor corridor, memory loop, Room 407, chase, reveal, and credits inside one continuous gameplay scene. The intended first-run duration is 15–20 minutes. Scene-local telemetry now measures that route, but the pacing target still requires a recorded physical playthrough and its same-run payload.

## Requirements

- Godot Engine 4.7.1 standard build, not .NET.
- A renderer compatible with Godot's Compatibility/OpenGL path.
- PowerShell to run the bundled Windows headless test runner.

This is a source-only project. The repository has no `export_presets.cfg`, exported executable, or bundled Godot binary.

## Run

1. Import `project.godot` in Godot 4.7.1.
2. Press **F5** to run the project from the configured boot scene.

Use F5 for the intended flow. **F6 runs the currently open scene and may bypass the boot menu.**

Command-line import check:

```powershell
godot --headless --path . --editor --quit
```

## Controls

| Action | Input |
|---|---|
| Move | W, A, S, D |
| Look | Mouse |
| Sprint | Shift |
| Interact | E |
| Flashlight | F |
| Review objective | Tab |
| Pause | Escape |

The pause menu includes Settings. Mouse sensitivity, field of view, four audio levels, fullscreen, light flicker, head bob, camera shake, and film grain controls are available. Changes apply immediately. **SAVE & CLOSE** writes `user://room407.cfg`; if the write returns an error, the modal stays open with **RETRY SAVE** and **CLOSE WITHOUT SAVING**. The latter keeps the current values for this session only.

## Implemented Gameplay

- One continuous `gameplay.tscn` runtime assembled from procedural geometry and authored controllers.
- Guarded phone, logbook, fuse, memory, radio, Room 407, chase, and ending progression.
- Four visibility-switched hallway states: one baseline plus three blackout-driven changes.
- A real `NavigationRegion3D` and an enemy state machine with `APPEAR`, `STALK`, full-speed `CHASE`, line-of-sight loss, bounded `SEARCH`, reacquisition, and terminal `DESPAWN` behavior.
- Chase speed of 3.0 units/second versus player walk 2.0 and sprint 3.1 units/second.
- Corridor-light failure at chase start, checkpoint recovery, an abandoned-lobby reveal, and a credits overlay. Chase start and post-capture recovery each play one bounded, entity-parented spatial cue through SFX; failure and ending teardown stop its player and cache ownership.
- Player-operated doors reject open or close attempts while the actor is inside the authored 1.5 m horizontal sweep. A valid tween applies a unique movement-only lock, keeps camera/mouse input active, and releases that lock on completion or door teardown.
- An atomic fourth-floor key pickup/consumption with a permanent run-local door unlock; the installed fuse is consumed once and cannot reappear after backtracking.
- A radio-completion checkpoint at `room_entrance` before the Room 407 threshold, a fourth-floor elevator display/real-door arrival beat, and a timed non-colliding apparition.
- Procedural fourth-floor dressing, Room 407 height-mark/room dressing, and a pre-chase manifestation that clears before the chase entity starts.
- Optional, state-neutral environmental interactions: a visible lobby desk drawer animates open and closed with sweep-safe movement locking and a positional tone, while the painted fourth-floor false door stays fixed and returns explicit feedback with its own positional tone.
- A two-step in-world ending investigation with six voiced revelations before the credits overlay appears.
- Pause-aware playthrough pacing telemetry for fresh Lobby runs, finalized when the visible credits appear.
- Boot-menu Continue when an in-memory checkpoint exists.

Checkpoints are process-local. Restarting the application clears gameplay progress; settings are the only persisted user data.

## Architecture

F5 loads `boot.tscn`, then enters the single continuous `gameplay.tscn`. `GameplayDirector` builds the procedural world and composes the player, UI, story, hallway, horror-event, chase, ending, and scene-local pacing components at runtime. Four autoloads own process state, scene routing, generated audio, and persisted settings; story controllers reach them through the director facade and stable flag/item IDs. The pacing facade returns a deep copy so callers cannot mutate the live report.

`AudioManager` creates the Music, SFX, Ambience, and Chase buses before `SettingsManager` applies either saved values or the first-run defaults. Its generated PCM cache keys every sample-rendering parameter and loop mode, caps data at 16 MiB with LRU eviction, protects streams held by regular/spatial players, and tears down spatial players synchronously. `NarrativeSequencer` adds a scene-local, pause-aware voice player whose exact manifest match follows the SFX level and falls back to the subtitle/dialogue tick when a cue is unavailable. `VisualEffectsLayer` owns the Compatibility shader; the flashlight uses a bounded, pause-safe pulse. See [Architecture](docs/architecture.md) for controller boundaries, data flow, and extension points.

## Test

Run all twelve headless checks from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1
```

Override the portable Godot executable when it is not at the runner's default path:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1 `
  -Godot "C:\path\to\Godot_v4.7.1-stable_win64_console.exe"
```

The exact checks are `editor-import`, `menu`, `gameplay`, `game-state`, `progression`, `checkpoint-layout`, `physical-route`, `player-input`, `visual-effects`, `settings-audio`, `settings-persistence-write`, and `settings-persistence-read`.

The runner writes one log per check to `.artifacts/test-<name>.log`, isolates Godot user data under `.tmp/`, and removes its unique profile in guaranteed teardown, so it does not overwrite the normal `user://room407.cfg`. Coverage includes import, canonical `project.godot` serialization, and scene construction; state/checkpoint and guarded progression; pacing eligibility, pause accounting, milestone order, finalization, and invalid-run rejection inside the existing progression and checkpoint checks; layout, navigation, chase, and capsule/door invariants; the physical E binding plus the mapped interact action through the production 2.5-unit ray; locked-door spam, the 1.5 m sweep rejection, reason-scoped movement-only lock/release, and close/reopen; objective review; flashlight and pause locks; note and radio modal close/unlock behavior; the chase entity's parented SFX cue at start/recovery plus teardown; visual-effect uniforms and chase fear transitions; first-run audio-bus defaults; settings controls/teardown; and settings persistence across two Godot processes.

The existing `physical-route` check also covers the optional drawer and painted door: structural visibility/alignment, production-ray acquisition, mapped feedback, cooldown/spam behavior, drawer sweep rejection and movement-only locking, open/close animation, unchanged story state, and spatial-tone/lock cleanup on teardown. These remain headless contract assertions, not rendered-visual, audible-mix, or physical-input evidence.

The suite also covers progression/scare/chase invariants, the two-step interactive epilogue, restored-checkpoint isolation, audio cache variants/LRU/live-player teardown, all 76 voice resources, cue replacement and subtitle fallback, queue ordering, pause/resume, voice-duration holds, modal focus return, and visible save failures; the voice and Settings regression helpers run inside `settings-audio` and do not add a thirteenth check. These checks do not prove a full physical F5 boot-to-credits traversal, 15–20 minute pacing, rendered visual balance, audible voice quality or mix balance, live chase fairness, or the physical Settings UI workflow. See [Testing](docs/testing.md) for the assertion-level matrix.

The fresh post-environmental-interaction run on 2026-07-16 passed all 12 checks in 64.7 seconds, produced 12 canonical logs and 10 required markers, contained zero scanned failure lines, and left zero temporary Godot profiles. This is automated contract evidence only; the physical and perceptual gates above remain open.

## Capture a Pacing Payload

Start a fresh shift with **F5**, not Continue, and complete it with physical keyboard and mouse input while recording the run. When the credits become visible, preserve the single console line beginning with:

```text
PLAYTHROUGH_PACING: {JSON payload}
```

Keep that exact payload with the same-run boot-to-credits capture. The game does not save the report to a file or show it in the UI. A headless runner artifact can contain two identical lines because it concatenates the engine log and captured console output; the runtime still emitted once. Even an eligible, complete, in-target payload is instrumentation, not proof of physical traversal, capture behavior, chase feel, presentation, audio, or Settings behavior.

### Record the physical run

The repository includes a separate evidence runner. It opens the editor by default; press **F5** yourself, choose **START SHIFT** rather than Continue, play to visible credits, then close the game and editor:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run-physical-playthrough.ps1 `
  -LaunchMode EditorF5 `
  -ConfirmPhysicalInput `
  -CaptureReference "D:\Captures\room407-full-run.mp4"
```

Raw engine/console logs plus `summary.json` and `summary.md` are written below `.artifacts/manual-playthrough/<timestamp>/`. The command marks the evidence package ready only when the repository stays clean on one unchanged branch/commit, the launched process exits normally, logs contain no engine/script/parse/leak failure, one unique same-run payload is eligible, complete, exact-order-valid, 900–1200 seconds active, within every chapter target, paired with the physical-input confirmation, and paired with a non-empty capture reference. Use `-LaunchMode ProjectRun` to launch the configured main scene directly. `-AnalyzeLog <path>` can inspect an existing log but can never make an evidence package ready.

The generated Markdown includes an unchecked human-review matrix. The capture path is a reference, not automated video verification. A reviewer must still watch the recording, complete that matrix, and evaluate traversal, chase fairness, visual/audio balance, Settings, fullscreen, and input behavior before closing the release gate.

## Assets

There is no third-party art or recorded-sound pack. Corridor geometry, props, materials, labels, and procedural 16-bit mono PCM effects are generated at runtime; `assets/audio/voice-over/` contains 76 compact, generated English story cues with a reviewed manifest and provenance, while Piper binaries/model weights remain local build inputs and are not committed. `icon.svg` is project-authored. The project-authored Compatibility shader adds 2x2 dithering, VHS tracking/jitter, grain, scanlines, a cold grade, and an edge vignette that intensifies and warms during the chase. The **Film Grain** setting controls the entire overlay, including the chase fear vignette.

No gameplay captures are committed. Add only verified in-engine captures under `docs/screenshots/` after a manual visual pass; do not present concept art as gameplay. See [Asset credits and provenance](docs/asset-credits.md).

## Known Limitations

- No recorded manual F5 boot-to-credits pass with its same-run telemetry payload currently verifies the complete physical route.
- The 15–20 minute duration is an instrumented authored target, not a recorded physical-playthrough result.
- Audible audio/mix balance, live chase navigation and fairness, and target-display visual balance remain manually unverified.
- Checkpoints last only for the current application process; only settings persist to disk.
- No export preset, release binary, or platform package is committed or release-tested.

See [Known limitations](docs/limitations.md) for the complete release boundary and required evidence.

## Export

No export preset is committed or release-tested. To prepare a local binary, install the matching Godot 4.7.1 export templates and create a platform preset through **Project > Export**. Keep generated packages outside the repository; treat binary export, platform packaging, and runtime notices as unverified until tested on the target platform.

## Contributing

Keep changes focused, use Conventional Commit messages, and do not commit `.godot/`, `.artifacts/`, local tools, exports, or credentials. Before submitting a change, run the twelve-check suite and `git diff --check`, then update documentation only for behavior the current source or recorded manual evidence proves.

## Project Layout

| Path | Contents |
|---|---|
| `project.godot` | Main scene, autoloads, input map, display, and Compatibility renderer configuration |
| `scenes/boot/` | Boot scene |
| `scenes/gameplay/` | Continuous gameplay scene root |
| `scenes/player/` | Player scene and configured movement values |
| `scenes/ui/` | HUD, pause/settings, fail, and ending overlays |
| `scripts/autoload/` | Game state, scene routing, audio, and settings services |
| `scripts/audio/` | Manifest-backed story voice playback and fallback |
| `scripts/interaction/` | Door, pickup, and story interaction contracts |
| `scripts/player/` | Movement, flashlight, and interaction ray logic |
| `scripts/puzzles/` | Radio puzzle UI and validation |
| `scripts/ui/` | Runtime UI, transitions, and visual effects |
| `scripts/world/` | World construction, progression, horror events, navigation, chase, and ending logic |
| `assets/audio/voice-over/` | Generated English OGG cues, Godot import sidecars, and cue manifest |
| `shaders/` | Project-authored Compatibility canvas shader |
| `tests/` | Native GDScript checks and PowerShell runner |
| `tools/` | Reproducible offline voice generation script; local Piper/model files stay ignored |
| `docs/` | PDR, roadmap, design, architecture, standards, testing, provenance, and limitations |
| `plans/` | Project planning and historical verification artifacts |

Geometry and procedural effects are generated at runtime. The only committed audio assets are the manifest-backed English voice cues under `assets/audio/voice-over/`; the project-authored icon is `icon.svg` at the repository root.

## References

- [Game design](docs/game-design.md)
- [Project overview and PDR](docs/project-overview-pdr.md)
- [Project roadmap](docs/project-roadmap.md)
- [Architecture](docs/architecture.md)
- [Code standards](docs/code-standards.md)
- [Testing](docs/testing.md)
- [Asset credits and provenance](docs/asset-credits.md)
- [Known limitations](docs/limitations.md)
- [Project configuration](project.godot)

## License

Project code and project-authored assets are released under the [MIT License](LICENSE). This license does not relicense Godot Engine or its third-party components; see [Asset credits and provenance](docs/asset-credits.md).
