# Changelog

All notable changes to this project are documented here.

## [Unreleased]

### Added

- Godot 4.7.1 Compatibility-renderer project foundation, boot scene, input map, and project icon.
- One continuous lobby-to-ending gameplay scene with guarded phone, logbook, fuse, memory, radio, Room 407, chase, and ending progression.
- `GameplayDirector` facade with dedicated `StoryProgressionController` and `ChaseSequenceController` collaborators.
- Full-screen blackout transitions that hide memory-hallway reconfiguration without changing gameplay scenes.
- Procedural corridor geometry, a `NavigationRegion3D`, enemy `STALK` and chase states, chase-time corridor-light failure, checkpoint recovery, abandoned-lobby reveal, and credits.
- Boot-menu Continue for process-local checkpoints and pause-menu access to Settings.
- Persisted settings at `user://room407.cfg` for controls, display, audio, and comfort options.
- Seven-check Windows headless runner with per-check logs under `.artifacts/`.

### Changed

- Split progression, chase, recovery, and ending responsibilities out of the gameplay facade.
- Added authored observation beats inside the continuous route: the stopped desk clock, floor notice, three memory echoes, and two Room 407 searches now gate the next story step with readable narrative feedback.
- Raised bounded ambient, lobby focus, corridor pool, flashlight, and chase-guide lighting floors after real Compatibility-renderer captures; the route remains dark without losing its main silhouettes.
- Tuned chase speed to 3.0 units/second against player walk 2.0 and sprint 3.1 units/second.
- Expanded progression coverage to exercise radio wrong/correct UI behavior, chase recovery, ending success, and the abandoned-lobby reveal.
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

### Known Validation Gaps

- The 15–20 minute pacing target, full physical input traversal, visual readability, audio balance, audible device output, and chase feel still require manual evidence.
- Settings save/load across a full application relaunch is implemented but not covered by the headless suite.
- The repository remains source-only and has no export presets or binary build.

## References

- [Testing matrix](docs/testing.md)
- [Architecture](docs/architecture.md)
- [Known limitations](docs/limitations.md)
