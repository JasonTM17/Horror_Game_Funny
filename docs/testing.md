# Testing

## Overview

The repository has one PowerShell runner that executes seven Godot 4.7.1 headless checks. These checks prove resource loading and selected logic/layout invariants. They do not replace a manual F5 boot-to-credits playthrough.

## Run the Suite

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1
```

The default executable is:

```text
D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe
```

Override it with the runner's `-Godot` parameter:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1 `
  -Godot "C:\path\to\Godot_v4.7.1-stable_win64_console.exe"
```

The runner sets repository-local `TEMP` and `TMP` to `.tmp/`, creates a unique Godot `APPDATA`/`LOCALAPPDATA` profile below that directory, creates `.artifacts/`, and writes `.artifacts/test-<name>.log` for each check. It combines Godot's engine log with captured console output, so stderr-only leak warnings are still scanned. This prevents the suite from reading or overwriting the normal `user://room407.cfg`.

## Exact Seven-Check Matrix

| # | Check / log | Invocation target | Automated evidence | Not proven |
|---:|---|---|---|---|
| 1 | `editor-import` / `test-editor-import.log` | `--editor --quit` | project imports; scripts/resources parse during editor scan | rendered gameplay, input, audio output |
| 2 | `menu` / `test-menu.log` | `scenes/boot/boot.tscn` | boot scene loads under its configured `--quit-after 8` smoke limit | button navigation with physical input, visual layout |
| 3 | `gameplay` / `test-gameplay.log` | `scenes/gameplay/gameplay.tscn` | continuous runtime scene constructs and survives the smoke window | full route traversal or progression |
| 4 | `game-state` / `test-game-state.log` | `game-state-test.gd` | item/flag idempotency and checkpoint inventory restore | scene recovery, disk persistence |
| 5 | `progression` / `test-progression.log` | `progression-test.tscn` | director-level guarded progression semantics, blackout completion, radio close/reopen cooldown, chase recovery, staged ending and reveal | human interaction timing, physical chase traversal, presentation |
| 6 | `checkpoint-layout` / `test-checkpoint-layout.log` | `checkpoint-layout-test.tscn` | room spawn and Variant3 restore, barriers/doors, navigation polygon, `STALK`, speed ordering, retreat recovery, authored distances | navigation quality under real play, collision feel, route readability |
| 7 | `settings-audio` / `test-settings-audio.log` | `settings-audio-test.tscn` | buses, selected clamps, controls, pause Settings/Escape locks, audio teardown, in-memory Continue | persisted config contents/reload, relaunch persistence, audible sound |

Checks 4–7 require these success markers respectively:

```text
GAME_STATE_TEST_OK
PROGRESSION_TEST_OK
CHECKPOINT_LAYOUT_TEST_OK
SETTINGS_AUDIO_TEST_OK
```

The runner fails on a non-zero Godot exit, a missing expected marker, or matching log text for engine/script/parse errors, ObjectDB leak warnings, and the progression, layout, or settings assertion prefixes.

The checkpoint-layout check has a finite 1200-frame hard cap because it intentionally waits for three door animations plus chase/recovery timers. A shorter 600-frame cap could end a fast headless run cleanly before the marker without indicating a gameplay assertion failure.

## Progression Coverage

`progression-test.gd` instantiates the production gameplay scene and calls its public story facade. Narrative duration is reduced only for test execution. It verifies:

- fresh-run ending and early logbook rejection;
- direct action calls reject premature lobby, floor, memory-loop, radio, and Room 407 interactions instead of relying only on hidden prompts;
- phone briefing, stopped-clock and night-register observations, logbook, floor-notice observation, fuse pickup/install, and power stabilization;
- phone, observations, logbook, fuse, memories, radio, and Room 407 actions preserve one-shot behavior and expected inventory side effects;
- ordered photo, cassette, and rabbit collection with one completed environmental echo required after each memory;
- first, second, and final blackout transition completion;
- duplicate memory rejection;
- radio UI opening, wrong-code cooldown/disabled submit state, close/reopen cooldown preservation, cooldown recovery, correct `0007`, and `radio_solved` completion;
- Room 407 recording, drawing, bed/wardrobe/family-table observations, note, and chase readiness;
- chase stage, capture recovery marker, and no duplicate entity after recovery;
- successful ending gate, `ENDING` stage, `AbandonedLobbyFloor` reveal node, and delayed credits appearance.

The test manipulates UI fields and calls methods directly. It does not send actual E/keyboard/mouse events or walk the physical route.

## Checkpoint, Layout, Navigation, and Chase Coverage

`checkpoint-layout-test.gd` verifies:

- restored Room 407 spawn position and objective;
- restored final hallway variant and root visibility derived from three completed memories;
- partition pieces and absence of a full-width wall across the Room 407 route;
- guarded floor, power, and room doors;
- collision rays cannot bypass closed barriers at center or side positions;
- an opened door clears the tested passage ray;
- `ContinuousCorridorNavigation` exists with one navigation polygon;
- the entity reaches `STALK` after `APPEAR`;
- entity 3.0 is faster than walk 2.0 and slower than sprint 3.1;
- retreat beyond the chase boundary requests recovery and restores the chase marker;
- representative story props retain recognizable child parts (phone handset, clock digits, book title, rabbit ears, radio dial, and family-table plate);
- memory-loop distance is at least 180 units, chase distance at least 280, and total corridor length at least 850.

These are structural and numeric assertions. They do not move a player capsule through every doorway or prove that a `NavigationAgent3D` follows the route correctly under player-driven pursuit.

## Settings and Audio Coverage

`settings-audio-test.gd` verifies the presence of Master, Music, SFX, Ambience, and Chase buses. It asserts these boundary examples:

| Setter call | Expected clamp |
|---|---:|
| mouse sensitivity `99.0` | `0.25` |
| field of view `12.0` | `60.0` |
| master volume `−99.0` | `−40.0` dB |

It also verifies settings controls for music, SFX, ambience, fullscreen, camera shake, film grain, and reset; a Settings button/panel in the pause scene; Escape closes Settings without clearing the pause lock; `stop_all()` clears players, cached samples, and byte accounting; and a visible Continue button after creating an in-memory checkpoint.

Closing the pause settings panel reaches `save_settings()`, but the test does not assert the result, inspect `user://room407.cfg`, launch a second process, or verify `load_settings()` after relaunch. It calls `start_drone()` and `stop_tone()`, but `AudioManager` intentionally skips drone creation under the headless display server, so this is not audible-output evidence.

## Logs

Each run overwrites these machine-local files:

```text
.artifacts/test-editor-import.log
.artifacts/test-menu.log
.artifacts/test-gameplay.log
.artifacts/test-game-state.log
.artifacts/test-progression.log
.artifacts/test-checkpoint-layout.log
.artifacts/test-settings-audio.log
```

Use the console summary for quick status and the matching log for diagnosis. Logs are generated artifacts, not committed proof. Preserve a dated external test report if release evidence must survive cleanup.

## Required Manual Matrix

No current automated check verifies the following. Record each result, environment, date, tester, and evidence link before a release claim.

| Area | Manual procedure | Evidence required |
|---|---|---|
| Intended flow | Press F5, use physical keyboard/mouse, reach credits without method calls | complete capture or timestamped trace |
| Pacing | Record lobby, floor, memory, Room 407, chase, and total times | chapter timings; compare with 15–20 minute target |
| Physical traversal | Walk/sprint through every closed/open door, loop return, Room 407, and chase route | no snag/bypass report and capture |
| Chase fairness | Complete, fail once, recover, and complete again | distance/readability/collision observations |
| Visual balance | Check corridor darkness, flashlight, blackout, flicker, grain, red guide lights, and ending reveal | screenshots/video on target hardware |
| Audio balance | Listen to phone, narration tones, ambience, footsteps, radio static, chase, fail, and ending | device plus bus-level observations |
| Settings persistence | Change values, Save & Close, quit, relaunch, and inspect restored values | before/after capture and config result |
| Comfort/input | Toggle flicker, head bob, shake, grain, fullscreen; pause/resume and open settings | mouse capture and toggle behavior trace |

Do not mark 15–20 minute pacing, visual/audio balance, audible output, full physical traversal, or settings relaunch persistence as verified until this evidence exists.

## References

- [`run-headless-tests.ps1`](../tests/run-headless-tests.ps1)
- [`game-state-test.gd`](../tests/game-state-test.gd)
- [`progression-test.gd`](../tests/progression-test.gd)
- [`checkpoint-layout-test.gd`](../tests/checkpoint-layout-test.gd)
- [`settings-audio-test.gd`](../tests/settings-audio-test.gd)
- [`settings-manager.gd`](../scripts/autoload/settings-manager.gd)
- [`audio-manager.gd`](../scripts/autoload/audio-manager.gd)
- [Known limitations](limitations.md)
