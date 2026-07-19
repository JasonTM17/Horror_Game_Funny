# Codebase Summary

Snapshot provenance: Repomix 1.14.0 was run from the repository root on 2026-07-19 with
its default XML output (`repomix-output.xml`): 4,129 files were packed and Repomix's
security scan reported no suspicious files. The snapshot reflects files visible to that
workspace run, including repository-local tooling; it is orientation input, not a
substitute for source, test logs, or dated evidence reports.

Refresh this summary and its Repomix snapshot whenever `project.godot`, runtime
scenes/controllers, test runners, delivery workflows, export contracts, or documentation
navigation materially changes. Verify claims against the named source files after every
refresh; do not treat the compaction as an executable specification.

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

- `scripts/autoload/game-state.gd` defines the monotonic `GameState.Stage` enum:
  `LOBBY`, `FLOOR4_DARK`, `FLOOR4_POWERED`, `MEMORY_LOOP`, `ROOM_407`, `CHASE`, and
  terminal `ENDING`. `credits` is not a game-state enum value; it is the final pacing
  telemetry boundary emitted after the visible credits overlay opens.
- `project.godot` registers the four autoloads, boot scene, physical/logical keyboard
  bindings, layer names, 960×540 viewport with 1280×720 override, and Compatibility
  rendering.
- `export_presets.cfg` contains one credential-free unsigned Windows Desktop x86_64
  preset with an embedded PCK. `tests/verify-windows-export.ps1` validates the selected
  preset, official 4.7.1 template/archive hashes, PE architecture, notices, fresh logs,
  direct headless startup, exclusive locking, staging, and active/rollback publication.
  Its `0.9.0.0` file/product version is unreleased release-candidate metadata, not a tag
  or published release claim.
- `Dockerfile` and `docker-compose.yml` package a non-root Godot 4.7.1 headless suite
  image named `nguyenson1710/horror-game-suite`. This is a CI/test image, not the player
  game. A passing `main` push auto-publishes only when both Hub secrets are configured;
  there is no separate workflow approval, and no digest means publication is unverified.
  `tests/verify-docker-packaging.ps1` and `.sh` are structural contract checks.
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
non-zero failure checks, and engine/script/parse/assert scans. They intentionally ignore
known ObjectDB warning noise at process exit; any dated zero-line ObjectDB scan is an
additional closure audit, not runner failure policy. The focused PowerShell harnesses are
separate gates:

- `physical-playthrough-evidence-regression.ps1` exercises stale/baseline/fresh
  side-channel, strict pacing schema, atomic quarantine, size ceiling, timestamp,
  single-stream snapshot, source-swap, containment, cleanup, and reparse rejection cases
  in an isolated temporary profile. It does not launch Godot or create release evidence.
- `windows-export-adversarial.ps1` exercises export transaction recovery, manifest/hash
  tampering, parser rejection, descendant teardown, output containment, timeout, and
  lock preservation against verified active/rollback bundles.
- `run-physical-playthrough.ps1` supports a human physical production-window run;
  `ProjectRun` preferred, `EditorF5` optional. It binds bounded Job Object logs and an
  exact-one-payload verified side-channel to one run but cannot inspect a capture, prove
  physical input, or judge presentation.
- `visual-capture-tour.tscn` is a staged documentation harness. It freezes simulation
  and selects states directly; its PNG/GIF outputs are visual references only.
- `verify-repository-docs.py` validates required public docs, committed media hashes and
  structure, malformed-cover negative cases, and inline/explicit/collapsed local
  Markdown links using only the Python standard library. It reads stage-0 regular blobs
  by indexed object ID, rejects unapproved media extensions and staged mode/blob drift,
  and requires local targets in the Git index; anchors and external URL reachability are
  outside its scope. See
  [Testing](./testing.md#verify-repository-documentation-and-media) for caps and markers.

## Current evidence boundary — 2026-07-19

The final source-closure report records a fresh Windows host exit 0 with 12/12 checks,
focused side-channel markers, both Docker packaging contract markers, export adversarial
preservation, secret scan, YAML/link/media checks, and clean diff hygiene. Docker compose
config, image build, and the local Linux-container suite passed 12/12; runtime identity
confirmed Godot 4.7.1 under UID/GID 65532. Registry publication was not performed. The
fresh three-stage current-diff review found zero Critical or Medium defects.

Stable recorded export identities are:

| Artifact | Role | Identity |
|---|---|---|
| `ROOM_407_THE_LAST_SHIFT.exe` (`117920024` bytes) | reproducible active payload | SHA-256 `420c085640d54e49765362e830b5f6a4ee8b70d18dc1303079485e59e034c771` |
| Official export-template archive | local export input | SHA-256 `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72` |
| Installed `windows_release_x86_64.exe` template | local export input | SHA-256 `76269a403bb832599edeee4432a5b7a7e88c018eb5c9c798dfd8289359b0ec07` |

Per-run active/rollback transaction identities rotate because `BUNDLE_SHA256` binds a
fresh `RUN_ID`; read the ignored manifests and dated
[operator handoff](../plans/260718-1319-final-horror-release-candidate/reports/phase-05-operator-handoff-2026-07-18.md) instead of copying them into evergreen docs.

The cover contract is `1280×640`, SHA-256
`58d5893ef611bfa8b5657c40483073c0ba67c086c0fd2577d4538502d2283980`.
See the [final source-closure verification and review](../plans/260719-0746-repository-evidence-closure/reports/pm-260719-1501-source-closure.md)
for command-level evidence. Earlier tester/reviewer reports remain historical traces.

PDR-07 and parent release-candidate Phase 5 remain open. A human physical
production-window run (`ProjectRun` preferred, `EditorF5` optional) must provide a fresh
`START SHIFT`-to-credits capture, same-run eligible pacing payload, and completed
traversal/perception review. The maintainer-run side-channel checks retain the
hostile same-profile reparse/TOCTOU limitation; they are not a hostile-filesystem proof.

## Documentation map

- [Project overview and PDR](./project-overview-pdr.md) — requirements and release decision.
- [System architecture](./architecture.md) — controller boundaries and data flow.
- [Code standards](./code-standards.md) — naming, ownership, testing, and evidence rules.
- [Testing matrix](./testing.md) — commands, checks, and manual review matrix.
- [Deployment guide](./deployment-guide.md) — source launch, QA, export, CI/Hub, handoff, and rollback.
- [Known limitations](./limitations.md) — distribution, persistence, and evidence boundaries.
- [Asset credits and provenance](./asset-credits.md) — media origins and license scope.
- [Project roadmap](./project-roadmap.md) — phase status and remaining human gate.
