# Changelog

All notable changes to this project are documented here.

## [Unreleased]

### Added

- Godot 4.7.1 Compatibility-renderer project foundation, boot scene, input map, and project icon.
- One continuous lobby-to-ending gameplay scene with guarded phone, logbook, fuse, memory, radio, Room 407, chase, and ending progression.
- `GameplayDirector` facade with dedicated `StoryProgressionController` and `ChaseSequenceController` collaborators.
- Full-screen blackout transitions that hide memory-hallway reconfiguration without changing gameplay scenes.
- Procedural corridor geometry, a `NavigationRegion3D`, enemy `STALK` and chase states, chase-time corridor-light failure, checkpoint recovery, abandoned-lobby reveal, and credits.
- Scene-local, pause-aware playthrough telemetry that snapshots fresh-Lobby eligibility, records first-occurrence stage order, finalizes at visible credits, and prints one `PLAYTHROUGH_PACING: ` JSON line.
- Boot-menu Continue for process-local checkpoints and pause-menu access to Settings.
- Persisted settings at `user://room407.cfg` for controls, display, audio, and comfort options.
- Twelve-check Windows headless runner with per-check logs under `.artifacts/`, including targeted production-player movement/door collision and isolated two-process settings persistence.

### Changed

- Split progression, chase, recovery, and ending responsibilities out of the gameplay facade.
- Added authored observation beats inside the continuous route: the stopped desk clock, night register, floor notice, three memory echoes, and three Room 407 searches now gate the next story step with readable narrative feedback.
- Replaced generic story-prop boxes with readable procedural PS1 silhouettes for phones, clocks, books, paper clues, fuses, cassettes, the rabbit, radio, search markers, the family table, and the exit panel.
- Raised bounded ambient, lobby focus, corridor pool, flashlight, and chase-guide lighting floors after real Compatibility-renderer captures; the route remains dark without losing its main silhouettes.
- Tuned chase speed to 3.0 units/second against player walk 2.0 and sprint 3.1 units/second.
- Expanded progression coverage to exercise radio wrong/correct UI behavior, production-threshold chase start, scheduled physics/collision/proximity capture, ending success, the abandoned-lobby reveal, and complete fresh-run pacing telemetry.
- Extended checkpoint/layout coverage with restored-run pacing ineligibility, null verdicts for incomplete evidence, visible-credits finalization, reset immutability, and deliberately out-of-order rejection without adding a thirteenth runner check.
- Expanded settings/audio coverage to assert buses, clamped values, expected controls, pause-menu Settings, and in-memory Continue visibility.
- Reworked project documentation to separate automated evidence from manual targets and to record exact settings bounds, test logs, provenance, and release limitations.

### Fixed

- Restored the memory-derived hallway variant when Continue rebuilds a Room 407 or chase checkpoint.
- Preserved radio cooldown across close/reopen attempts and prevented stale feedback timers from clearing a new attempt.
- Added an in-world observation window before the ending credits cover the abandoned-lobby reveal.
- Converted chase retreat beyond the authored route into checkpoint recovery instead of silently disabling the entity.
- Isolated headless test settings from the real Godot user profile and made leak warnings fail the runner.
- Released procedural audio players synchronously and added a short audio-server drain in the regression fixture so WAV playback objects do not leak during shutdown.
- Captured both Godot log files and console stderr in the headless runner so engine leak warnings cannot be hidden by a clean log file.
- Enforced observation and Room 407 prerequisites inside action handlers, preventing direct interaction spam from bypassing prompt-level story gates.
- Raised the finite checkpoint-layout frame cap from 600 to 1200 so its authored door and recovery timers finish before the runner evaluates the success marker.
- Added guaranteed repository-local test-profile cleanup so repeated runner invocations do not accumulate isolated Godot user data.

### Known Validation Gaps

- The telemetry contract and twelve-check suite pass, but a fresh physical F5 boot-to-credits capture with its same-run JSON payload is still required before claiming the 15–20 minute pacing target.
- Full physical input traversal, capture behavior, chase/presentation quality, visual readability, audio balance and audible device output, and physical Settings behavior still require manual evidence.
- Settings persistence is verified across two isolated Godot processes; the physical Settings-panel save/relaunch workflow on target hardware remains manual evidence.
- The repository remains source-only and has no export presets or binary build.

## References

- [Testing matrix](docs/testing.md)
- [Architecture](docs/architecture.md)
- [Known limitations](docs/limitations.md)
