# Codebase Summary

Generated from a Repomix repository compaction on 2026-07-19 (the transient XML snapshot
is intentionally not retained in the working tree). This is an orientation document,
not a substitute for the source,
test logs, or dated evidence reports. The evergreen documentation links below are the
maintained entry points.

## Product and runtime

ROOM 407: THE LAST SHIFT is a Godot 4.7.1 first-person psychological-horror game using
the Compatibility (`gl_compatibility`) renderer. The main scene is a single continuous
`gameplay.tscn` route: lobby → fourth-floor blackout → memory loop → Room 407 → chase →
abandoned-lobby investigation → visible credits. Gameplay progress and checkpoints are
process-local; settings are persisted separately through `user://room407.cfg`.

The project is intentionally asset-light. World geometry, labels, primitive materials,
procedural sound effects, and the Compatibility post-process shader are assembled from
source. The repository also contains a manifest-backed English voice set, four
project-authored runtime stills, staged documentation screenshots/GIF, and a separate
documentation-only cover under `docs/media/`.

## Runtime architecture

`project.godot` configures `scenes/boot/boot.tscn` as the entry scene, the input map,
display defaults, Compatibility renderer, and four autoload services:

| Service | Source | Responsibility |
|---|---|---|
| `GameState` | `scripts/autoload/game-state.gd` | Process-local stage, flags, items, checkpoints, and signals |
| `SceneRouter` | `scripts/autoload/scene-router.gd` | Scene transitions and gameplay entry |
| `AudioManager` | `scripts/autoload/audio-manager.gd` | Music/SFX/Ambience/Chase/Voice buses, procedural tones, cache and teardown |
| `SettingsManager` | `scripts/autoload/settings-manager.gd` | Clamped settings, save/load, and save-failure signaling |

`GameplayDirector` (`scripts/world/gameplay-director.gd`) composes runtime nodes and
delegates ownership to focused controllers:

- `ContinuousWorldBuilder`, `ContinuousStoryLayout`, `WorldLayout`, and `LevelGeometry`
  build the corridor, props, doors, navigation, lights, and authored positions.
- `StoryProgressionController` owns guarded interactions, observations, inventory
  prerequisites, memory-loop transitions, radio completion, Room 407 clues, and chase
  readiness.
- `ChaseSequenceController` owns the entity lifecycle, chase lighting/audio, capture
  recovery, ending reveal, and exactly-once visible credits.
- `HorrorEventDirector` and `HorrorScareSequence` own fixed anticipation/reveal/aftermath
  beats, pause-safe waits, temporary actors, cue IDs, and light/audio cleanup.
- `NarrativeSequencer` and `VoiceOverPlayer` manage manifest-backed voice/subtitle
  playback, pause behavior, fallback text, queueing, and scene-local cancellation.
- `PlaythroughPacingTelemetry` records first-seen stage boundaries, pause-aware active
  time, chapter targets, finalization at credits, and one last-run evidence side-channel.
- `HUD`, pause/settings, note, failure, ending, hallway transition, and visual-effects
  layers provide player-facing UI and comfort controls.

The player implementation is split across `player-controller.gd`,
`player-interaction.gd`, and `player-flashlight.gd`. Interaction classes in
`scripts/interaction/` enforce prerequisite, cooldown, sweep-clearance, and lock rules;
`radio-puzzle.gd` provides the radio UI and validation.

## Repository layout

| Path | Purpose |
|---|---|
| `project.godot` | Godot project settings, autoloads, input map, display, renderer |
| `scenes/` | Boot, continuous gameplay, player, HUD, pause/settings, fail, and ending scenes |
| `scripts/autoload/` | Cross-scene state, routing, audio, and settings services |
| `scripts/world/` | Runtime composition, progression, scares, chase, ending, narration, telemetry |
| `scripts/player/` | Movement, interaction ray, flashlight, and comfort behavior |
| `scripts/interaction/` | Base interactable, doors, drawer, pickup, and story interactions |
| `scripts/ui/` | HUD, transitions, overlays, settings, pause, and visual effects |
| `scripts/audio/` | Voice playback and manifest integration |
| `scripts/puzzles/` | Radio puzzle UI and validation |
| `assets/` | Voice cues/import metadata and project-authored still textures |
| `shaders/` | Compatibility renderer post-process shader |
| `tests/` | GDScript fixtures, host/POSIX runners, packaging checks, physical-evidence runner, export verifier |
| `tools/` | Offline voice-generation tooling; local binaries/models stay out of Git |
| `docs/` | Architecture, standards, PDR, roadmap, testing, limitations, provenance, and media |
| `plans/` | Historical plans and dated verification reports |
| `.artifacts/`, `.tmp/`, `exports/` | Ignored local test, capture, profile, and build output |

## Configuration and delivery contracts

- `project.godot` defines the `LOBBY`-through-`CREDITS` stage flow, physical and logical
  keyboard bindings, layer names, 960×540 viewport with 1280×720 override, and
  Compatibility rendering.
- `export_presets.cfg` contains one credential-free unsigned Windows Desktop x86_64
  preset with an embedded PCK. `tests/verify-windows-export.ps1` validates the selected
  preset, official 4.7.1 template/archive hashes, PE architecture, notices, fresh logs,
  direct headless startup, exclusive locking, staging, and active/rollback publication.
- `Dockerfile` and `docker-compose.yml` package a non-root Godot 4.7.1 headless suite
  image named `nguyenson1710/horror-game-suite`. This is a CI/test image, not the player
  game. `tests/verify-docker-packaging.ps1` and `.sh` are structural contract checks.
- `docs/.gdignore` keeps documentation-only media out of Godot import; the Windows
  export preset also excludes `docs/`, tests, plans, and local output paths.

## Verification surfaces

The host and POSIX runners intentionally expose exactly twelve named Godot checks:

1. `editor-import`
2. `menu`
3. `gameplay`
4. `game-state`
5. `progression`
6. `checkpoint-layout`
7. `physical-route`
8. `player-input`
9. `visual-effects`
10. `settings-audio`
11. `settings-persistence-write`
12. `settings-persistence-read`

`run-headless-tests.ps1` and `run-headless-tests.sh` require their success markers,
non-zero failure checks, and engine/script/assert/leak scans. The focused PowerShell
harnesses are separate gates:

- `physical-playthrough-evidence-regression.ps1` exercises stale/baseline/fresh
  side-channel, timestamp, single-stream snapshot, source-swap, cleanup, and reparse
  rejection cases in an isolated temporary profile. It does not launch Godot or create
  release evidence.
- `windows-export-adversarial.ps1` exercises export transaction recovery, manifest/hash
  tampering, parser rejection, descendant teardown, output containment, timeout, and
  lock preservation against verified active/rollback bundles.
- `run-physical-playthrough.ps1` is the human-evidence wrapper. It binds logs and the
  pacing side-channel to one run but cannot inspect a capture, prove physical input, or
  judge presentation.
- `visual-capture-tour.tscn` is a staged documentation harness. It freezes simulation
  and selects states directly; its PNG/GIF outputs are visual references only.

## Current evidence boundary — 2026-07-19

The current tester report records a fresh Windows host exit 0 with 12/12 checks, focused
side-channel markers, both Docker packaging contract markers, export verification, export
adversarial preservation, secret scan, YAML/link/media checks, and clean diff hygiene.
The Docker daemon was unavailable, so live image build/run and registry publication are
not verified. The cycle-2 review scored 9/10 with zero critical findings.

Role-labeled local export identities are:

| Artifact | Role | SHA-256 |
|---|---|---|
| `ROOM_407_THE_LAST_SHIFT.exe` (`117920024` bytes) | active executable | `420c085640d54e49765362e830b5f6a4ee8b70d18dc1303079485e59e034c771` |
| `room407-windows-x86_64` | active bundle | `2111b6f55d318ec257bc6baa4a43117f5ee4d27ccc7c48452a57e6bfc7dcec4d` |
| `room407-windows-x86_64.previous` | rollback bundle | `3c4890f2b1d6f99329727d0bd008a043d60a462d807e1c811e337b965f2e7701` |

The cover contract is `1280×640`, SHA-256
`58d5893ef611bfa8b5657c40483073c0ba67c086c0fd2577d4538502d2283980`.
See the [tester report](../plans/260719-0746-repository-evidence-closure/reports/tester-2026-07-19.md),
[tester re-verification](../plans/260719-0746-repository-evidence-closure/reports/tester-review-fix-cycle-1-2026-07-19.md),
and [cycle-2 reviewer report](../plans/260719-0746-repository-evidence-closure/reports/code-review-cycle-2-2026-07-19.md)
for command-level evidence.

PDR-07 and parent release-candidate Phase 5 remain open. A human must provide a fresh
physical F5 `START SHIFT`-to-credits run, same-run eligible pacing payload, capture, and
completed traversal/perception review. The maintainer-run side-channel checks retain the
hostile same-profile reparse/TOCTOU limitation; they are not a hostile-filesystem proof.

## Documentation map

- [Project overview and PDR](./project-overview-pdr.md) — requirements and release decision.
- [System architecture](./architecture.md) — controller boundaries and data flow.
- [Code standards](./code-standards.md) — naming, ownership, testing, and evidence rules.
- [Testing matrix](./testing.md) — commands, checks, and manual review matrix.
- [Known limitations](./limitations.md) — distribution, persistence, and evidence boundaries.
- [Asset credits and provenance](./asset-credits.md) — media origins and license scope.
- [Project roadmap](./project-roadmap.md) — phase status and remaining human gate.
