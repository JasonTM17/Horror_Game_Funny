---
type: settings-persistence-relaunch
date: 2026-07-15
commit: 8a9bfc6ba9e24a261cd954b31b209d77aeed4955
status: automated-persistence-complete-physical-ui-open
---

# Settings Persistence Relaunch Evidence

## Contract

Prove that `SettingsManager.save_settings()` writes the complete settings contract and that a newly started Godot process restores it through autoload initialization. Keep the test isolated from the player's normal `user://room407.cfg`.

## Implementation

- Writer process sets distinct values for mouse sensitivity, FOV, master/music/SFX/ambience volumes, flicker, head bob, camera shake, film grain, and fullscreen, then saves the config.
- Reader process starts with the same temporary profile and asserts all 11 loaded values.
- Each process has its own expected marker and canonical log.
- Runner error scanning includes `SETTINGS_PERSISTENCE_ASSERT`.
- The entire nine-check sequence is wrapped in guaranteed teardown that verifies the resolved profile path is under repository-local `.tmp/godot-user-*` before recursive removal.

## Evidence

- Focused two-process run: `SETTINGS_PERSISTENCE_WRITE_OK`, `SETTINGS_PERSISTENCE_READ_OK`, and `SETTINGS_TWO_PROCESS_PERSISTENCE_OK`.
- Full runner: 9/9 checks passed twice after integration.
- Canonical logs: 9; parse, engine, assertion, and ObjectDB leak matches: 0.
- Teardown probe: profile directory count was 24 before and 24 after the complete runner.
- Remote `main` after the test push: `8a9bfc6ba9e24a261cd954b31b209d77aeed4955`.

## Remaining Manual Boundary

Automation proves config I/O and relaunch loading. A real user still needs to operate the Settings panel, confirm mouse capture and fullscreen transition on target hardware, and judge comfort/audio output. Those are physical UI/presentation checks, not persistence-logic gaps.

## Environment

- Godot: `4.7.1.stable.official.a13da4feb`
- C: approximately 11.88 GiB free after the first nine-check run
- D: approximately 21.14 GiB free after the first nine-check run

## Unresolved Questions

- None beyond the explicit physical UI/presentation matrix.
