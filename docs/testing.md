# Testing

## Overview

The repository has one PowerShell runner that executes twelve Godot 4.7.1 headless checks. These checks prove resource loading, selected logic/layout invariants, targeted production-player movement/collision and input-handler behavior, pacing-telemetry contracts, visual-effects contracts, and settings persistence across two separate processes. They do not replace a manual F5 boot-to-credits playthrough.

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

The runner sets repository-local `TEMP` and `TMP` to `.tmp/`, creates a unique Godot `APPDATA`/`LOCALAPPDATA` profile below that directory, creates `.artifacts/`, and writes `.artifacts/test-<name>.log` for each check. It combines Godot's engine log with captured console output, so stderr-only leak warnings are still scanned. Because Godot mirrors `print()` output to both sources, a combined artifact can contain two identical pacing lines even though the runtime emitted once. Writer and reader checks share this temporary profile, and guaranteed teardown removes it after success or failure. This prevents the suite from reading or overwriting the normal `user://room407.cfg`.

## Recorded Environment

This inventory records the current Windows verification machine. It is reproducibility context, not cross-hardware certification.

| Component | Recorded value | Boundary |
|---|---|---|
| Operating system | Windows 11 Pro 10.0.26200, build 26200 | one Windows installation only |
| PowerShell | 5.1.26100.8737 | runner host |
| Godot | 4.7.1, official revision `a13da4feb` | standard build, not .NET |
| Automated suite | headless | no rendered frames or audible-output judgment |
| Visual capture path | OpenGL 3.3 Compatibility; NVIDIA driver 581.08; NVIDIA GeForce RTX 3060 Laptop GPU | separate capture path, not the headless suite |
| Secondary graphics adapter | Intel UHD Graphics installed | not the adapter used for the recorded capture |
| Audio devices | operating system reports devices OK | audible output and sound quality remain unverified |

## Exact Twelve-Check Matrix

| # | Check / log | Invocation target | Automated evidence | Not proven |
|---:|---|---|---|---|
| 1 | `editor-import` / `test-editor-import.log` | `--editor --quit` | project imports; scripts/resources parse during editor scan | rendered gameplay, input, audio output |
| 2 | `menu` / `test-menu.log` | `scenes/boot/boot.tscn` | boot scene loads under its configured `--quit-after 8` smoke limit | button navigation with physical input, visual layout |
| 3 | `gameplay` / `test-gameplay.log` | `scenes/gameplay/gameplay.tscn` | continuous runtime scene constructs and survives the smoke window | full route traversal or progression |
| 4 | `game-state` / `test-game-state.log` | `game-state-test.gd` | item/flag idempotency and checkpoint inventory restore | scene recovery, disk persistence |
| 5 | `progression` / `test-progression.log` | `progression-test.tscn`; `--quit-after 1200` | guarded progression, production stage thresholds, blackout/radio/final-note gates, production-threshold chase start, scheduled-physics proximity capture, staged ending/reveal, and complete fresh-run pacing order/pause/finalization/deep-copy assertions | physical input, player-driven chase traversal, real pacing, presentation |
| 6 | `checkpoint-layout` / `test-checkpoint-layout.log` | `checkpoint-layout-test.tscn`; `--quit-after 1200` | room spawn and Variant3 restore, barriers/doors, navigation polygon, APPEAR pause, measured STALK/CHASE speeds, pause freeze, LOS/last-seen, reacquisition, bounded SEARCH/DESPAWN, restart/exit behavior, retreat recovery, authored distances, plus restored-run pacing ineligibility/null verdict, visible-credits finalization, reset immutability, and out-of-order rejection | navigation quality under real play, collision feel, route readability, fresh-run pacing |
| 7 | `physical-route` / `test-physical-route.log` | `physical-route-smoke-test.tscn` | production `CharacterBody3D` receives synthesized movement through three locked/open doors; prerequisite thresholds, Room 407 checkpoint, and chase creation | E/raycast interaction, complete route, puzzles, physical keyboard/mouse, timing, chase feel |
| 8 | `player-input` / `test-player-input.log` | `player-input-integration-test.tscn`; `--quit-after 600` | physical E binding exists; production ray/handlers accept synthesized actions for phone, objective, pause, flashlight, note Escape, and door cycles; flashlight flicker stays within energy bounds and freezes while paused; authored head pose and head-bob reset | OS-delivered keys/mouse, input latency, mouse-look feel, full traversal |
| 9 | `visual-effects` / `test-visual-effects.log` | `visual-effects-test.tscn`; `--quit-after 180` | overlay shader/material and dither/VHS/fear uniforms exist; chase/ending fear targets and film-grain visibility toggle respond | rendered pixels, readability, comfort, GPU performance, monitor gamma |
| 10 | `settings-audio` / `test-settings-audio.log` | `settings-audio-test.tscn` | buses and first-run default levels, selected clamps, parameter/loop-aware audio variants, LRU/live-stream protection, spatial finish/parent/stop teardown, controls, pause/boot modal focus trap and launcher return, visible save-failure retry/discard behavior, pause Settings/Escape locks, audio teardown, in-memory Continue; `menu-settings-regression.gd` runs as a nested helper | audible sound and physical UI navigation |
| 11 | `settings-persistence-write` / `test-settings-persistence-write.log` | `settings-persistence-write-test.tscn` | writes 11 distinct bounded settings to isolated `room407.cfg` | real player profile and physical UI save action |
| 12 | `settings-persistence-read` / `test-settings-persistence-read.log` | `settings-persistence-read-test.tscn` | a new Godot process restores all 11 values from the same isolated profile | target-device fullscreen transition and physical UI interaction |

Checks 4-12 require these success markers respectively:

```text
GAME_STATE_TEST_OK
PROGRESSION_TEST_OK
CHECKPOINT_LAYOUT_TEST_OK
PHYSICAL_ROUTE_SMOKE_TEST_OK
PLAYER_INPUT_INTEGRATION_TEST_OK
VISUAL_EFFECTS_TEST_OK
SETTINGS_AUDIO_TEST_OK
SETTINGS_PERSISTENCE_WRITE_OK
SETTINGS_PERSISTENCE_READ_OK
```

The runner fails on a non-zero Godot exit, a missing expected marker, or matching log text for engine/script/parse errors, ObjectDB leak warnings, and the progression, layout, physical-route, player-input, visual-effects, or settings assertion prefixes. The import, menu, and gameplay smoke checks have no success marker; they rely on process exit and the same log scan.

The runner passes finite frame/iteration watchdogs through `--quit-after`. In particular, progression/checkpoint-layout use 1200, physical-route 1800, player-input 600, visual-effects 180, and settings-audio/persistence 60. Reaching a watchdog is not a pass: every marker-based check must print its expected marker before exit. These values are test safety caps, not gameplay durations.

Pacing assertions extend the existing `progression` and `checkpoint-layout` checks. The suite remains exactly twelve checks; there is no separate thirteenth pacing check.

## Pacing Telemetry Contract

The scene-local `PlaythroughPacingTelemetry` begins after gameplay runtime composition. It snapshots eligibility once, so only a fresh session whose initial stage is `LOBBY` is eligible. It records the first occurrence of each boundary in the order actually observed:

```text
lobby, floor4_dark, floor4_powered, memory_loop,
room_407, chase, ending, credits
```

Visible credits trigger finalization. The telemetry disconnects from `GameState.stage_changed`, freezes the report, and prints one runtime JSON line prefixed `PLAYTHROUGH_PACING: `. It does not persist a file or render a UI. `GameplayDirector.get_playthrough_pacing_report()` returns a recursive copy, preventing caller mutation of both top-level fields and nested targets.

The node inherits gameplay pause behavior. Monotonic `NOTIFICATION_PAUSED`/`NOTIFICATION_UNPAUSED` timestamps accumulate pause duration while normal active-time processing is suspended. Reports include `wall_clock_seconds`, `active_gameplay_seconds`, and `paused_seconds`; active time is clamped to at most unpaused wall time.

| Report chapter | Boundaries | Target seconds |
|---|---|---:|
| `opening` | `lobby` → `floor4_dark` | 120–180 |
| `floor4` | `floor4_dark` → `memory_loop` | 180–240 |
| `memory_loop` | `memory_loop` → `room_407` | 240–300 |
| `room407` | `room_407` → `chase` | 180–240 |
| `chase_ending` | `chase` → visible `credits` | 120–180 |
| total | initial `lobby` → visible `credits` active time | 900–1200 |

The total target is independent of the chapter verdicts. A missing boundary pair yields a `null` chapter duration and appears in `missing_milestones`; it is not represented as zero. Checkpoint and otherwise incomplete runs keep `within_target` `null`. A complete eligible compressed headless run is valid telemetry but returns `within_target: false`. A report with every milestone but an out-of-order actual sequence remains invalid and incomplete.

## Recorded Automated Evidence

The canonical 2026-07-16 exact twelve-check suite passed with 12 logs, 9 required markers, zero scanned failure lines, and zero temporary profiles. Its fresh compressed payload measured `6.58 s` active, `6.82 s` wall, and `0.22 s` paused, with `complete: true`, `boundary_order_valid: true`, and `within_target: false`; checkpoint/layout also passed with an incomplete, ineligible report and a `null` total verdict. These compressed results validate instrumentation behavior, not 15–20 minute physical pacing. Earlier focused runs at 3.66–3.67 active seconds are historical evidence only (see the dated plan reports).

## Synthetic Actions Versus Physical Input

The automation reaches production code, but it does not inject operating-system keyboard or mouse events:

- `physical-route-smoke-test.gd` calls `Input.action_press("move_forward")` and `Input.action_release("move_forward")`. The production controller then reads the action through `Input.get_vector()` and moves with `move_and_slide()`, but no physical W key is pressed.
- `player-input-integration-test.gd` confirms that `interact` has an E-key binding, then constructs `InputEventAction` objects and passes them directly to production `_unhandled_input()` methods. This exercises the production ray, locks, door logic, and UI handlers without proving that Windows delivered E, F, Tab, or Escape from hardware.
- `progression-test.gd` calls story methods and radio widget methods directly. It does not type into the `LineEdit`, click buttons, or close the final note through a real device.

Physical keyboard/mouse traversal, event delivery, mouse capture, and input feel therefore remain manual requirements.

## Progression Coverage

`progression-test.gd` instantiates the production gameplay scene and calls its public story facade. Narrative duration is reduced only for test execution. It verifies:

- fresh-run ending and early logbook rejection;
- direct action calls reject premature lobby, floor, memory-loop, radio, and Room 407 interactions instead of relying only on hidden prompts;
- phone briefing, stopped-clock and night-register observations, logbook, floor-notice observation, fuse pickup/install, and power stabilization;
- phone, observations, logbook, fuse, memories, radio, and Room 407 actions preserve one-shot behavior and expected inventory side effects;
- ordered photo, cassette, and rabbit collection with one completed environmental echo required after each memory;
- first, second, and final blackout transition completion;
- duplicate memory rejection;
- radio UI opening, Escape close/unlock and reopen, non-digit filtering, wrong-code cooldown/disabled submit state, rejection of `0007` during cooldown, close/reopen cooldown preservation, three-failure hint, cooldown recovery, accepted `0007`, and `radio_solved` completion;
- Room 407 recording, drawing, bed/wardrobe/family-table observations, final-note gate, direct note-close callback, and chase readiness;
- production-threshold chase start, an attached-navigation entity positioned 0.05 units horizontally within capture range and 1.1 units above the floor, APPEAR pause, measured STALK/CHASE movement, pause freeze, LOS/last-seen updates, reacquisition, bounded SEARCH-to-DESPAWN, clean restart/exit behavior, proximity recovery through two scheduled physics frames, the chase respawn marker, and no duplicate entity after recovery;
- successful ending gate, `ENDING` stage, `AbandonedLobbyFloor` reveal node, delayed credits appearance, one finalized pacing report, duplicate-ending stability, and recursive report-copy isolation;
- a deliberate paused interval is excluded from active gameplay while remaining in monotonic wall and pause totals; and
- the compressed fresh route records every boundary in actual order, produces complete chapter durations, and is correctly rejected as shorter than 15–20 minutes.

The test manipulates UI fields and calls methods directly. It synthesizes Escape for the radio handler but does not submit that event through the operating system or scene input queue. For the capture case it injects the entity position, advances physics, and lets production proximity logic request failure; it does not call `request_failure()` directly. It does not walk a player-driven chase route.

## Checkpoint, Layout, Navigation, and Chase Coverage

`checkpoint-layout-test.gd` verifies:

- restored Room 407 spawn position and objective;
- restored final hallway variant and root visibility derived from three completed memories;
- partition pieces and absence of a full-width wall across the Room 407 route;
- guarded floor, power, and room doors;
- collision rays cannot bypass closed barriers at center or side positions;
- an opened door clears the tested passage ray;
- `ContinuousCorridorNavigation` exists with one navigation polygon;
- the entity remains frozen during `APPEAR`, reaches `STALK`, and records measured `STALK` and full-speed `CHASE` movement;
- entity 3.0 is faster than walk 2.0 and slower than sprint 3.1, while pause freezes chase movement;
- LOS loss records a last-seen position, traverses `LOST_TARGET`/bounded `SEARCH`, reacquires a nearby player, then reaches `DESPAWN` after the search budget; restart and exit boundaries hide/stop the entity cleanly;
- retreat beyond the chase boundary requests recovery and restores the chase marker;
- a restored Room 407 session is incomplete and ineligible, keeps `within_target` `null`, and represents missing chapter durations as `null`;
- visible credits finalize that restored report, and a subsequent Replay/Menu-style `GameState.reset_run()` cannot mutate it;
- an all-milestone fixture with deliberately invalid occurrence order remains incomplete, reports `boundary_order_valid: false`, and rejects its negative chapter span as `null`;
- representative story props retain recognizable child parts (phone handset, clock digits, book title, rabbit ears, radio dial, and family-table plate);
- memory-loop distance is at least 180 units, chase distance at least 280, and total corridor length at least 850.

These are structural and numeric assertions. They do not move a player capsule through every doorway or prove that a `NavigationAgent3D` follows the route correctly under player-driven pursuit.

## Production Movement and Door Coverage

`physical-route-smoke-test.gd` instantiates the production gameplay scene and production `CharacterBody3D`. It presses the mapped `move_forward` action across physics frames, which reaches the player controller's normal `Input.get_vector()` and `move_and_slide()` path. It verifies:

- the floor, power, and Room 407 doors remain closed without their prerequisite flags;
- the capsule receives forward movement but stops at each locked door;
- each valid flag opens its door and lets the same capsule cross the passage;
- the memory threshold rejects entry before `power_stable` and activates after it;
- the Room 407 threshold creates the expected gameplay-scene checkpoint snapshot; and
- the chase threshold rejects premature entry, then starts once `chase_ready` and creates a valid entity.

The harness teleports between focused gates, sets prerequisite flags, and calls `door.interact()` directly. It does not press E through the production raycast, solve the complete puzzles, traverse every meter, exercise a player-driven chase, or measure 15-20 minute pacing.

## Player Input Integration Coverage

`player-input-integration-test.gd` instantiates the production gameplay scene, production player, production interaction ray, and production door logic. It verifies:

- authored eye height `1.52` and initial head pitch `-8.0` degrees;
- an E-key event exists in the `interact` InputMap action and the interaction ray uses collision mask `4`;
- after focused player placement and a forced ray update, a synthesized `interact` action reaches the phone through the production interaction handler;
- synthesized objective, pause, and flashlight actions refresh the HUD, preserve the flashlight state while paused, and toggle it after resume;
- a test-created production note reader locks input, then a synthesized Escape action closes the note and releases the lock;
- the production ray reaches the floor door; a locked attempt stays closed; repeated synthesized interaction during the opening tween does not cancel it; and the same door closes and reopens after ray reacquisition from the appropriate side; and
- disabling head bob restores the authored head origin.

The test positions the player, forces ray updates, sets the door prerequisite flag, constructs action objects, and calls handlers directly. It proves production handler and state behavior, not physical key delivery, mouse-look delivery, or a complete route.

## Visual Effects Coverage

`visual-effects-test.gd` creates the production `VisualEffectsLayer` and verifies:

- `RetroOverlay` exists with a `ShaderMaterial`;
- the shader exposes `dither_strength`, `vhs_strength`, and `fear_intensity`;
- fear intensity starts at zero, rises above `0.9` after directly advancing the game state to `CHASE`, and falls below `0.2` after directly advancing to `ENDING`; and
- the film-grain comfort setting hides and restores the complete retro overlay.

The shader source also contains grain, scanline, ordered-dither, VHS tracking/jitter, fear-vignette pulse, and chase-edge tint logic. The automated check validates the shader contract and state response; it does not compare rendered pixels, capture screenshots, measure frame time, or establish visual comfort/readability.

## Settings and Audio Coverage

`settings-audio-test.gd` verifies the presence of Master, Music, SFX, Ambience, and Chase buses. It asserts these boundary examples and the generated-audio lifecycle:

| Setter call | Expected clamp |
|---|---:|
| mouse sensitivity `99.0` | `0.25` |
| field of view `12.0` | `60.0` |
| master volume `-99.0` | `-40.0` dB |

It also verifies settings controls for music, SFX, ambience, fullscreen, camera shake, film grain, and reset; parameter-complete one-shot/loop cache keys; capped-duration reuse; LRU recency; protection of cached streams held by regular or spatial players; spatial finish/queued-parent/stop cleanup; `stop_tone()` variant reclamation; and `stop_all()` cache/player/byte-accounting reset. The nested `menu-settings-regression.gd` helper verifies boot/pause modal focus traversal, launcher focus return, hidden-control focus release, full-rect modal blocking, and a failed config save that keeps the panel open for retry or discard. It also checks a visible Continue button after creating an in-memory checkpoint.

The writer process saves distinct values for all 11 settings into an isolated `user://room407.cfg`; it checks the returned `Error` instead of silently accepting a failed write. The reader starts as a new Godot process with the same temporary profile and asserts every value after autoload initialization calls `load_settings()`. This proves config persistence without touching the normal player profile. It does not send physical UI events or prove fullscreen/display behavior on target hardware. The audio fixture calls generated cues, but headless execution remains no evidence of audible-output quality.

## Logs

Each run overwrites these machine-local files:

```text
.artifacts/test-editor-import.log
.artifacts/test-menu.log
.artifacts/test-gameplay.log
.artifacts/test-game-state.log
.artifacts/test-progression.log
.artifacts/test-checkpoint-layout.log
.artifacts/test-physical-route.log
.artifacts/test-player-input.log
.artifacts/test-visual-effects.log
.artifacts/test-settings-audio.log
.artifacts/test-settings-persistence-write.log
.artifacts/test-settings-persistence-read.log
```

Use the console summary for quick status and the matching log for diagnosis. A pacing payload begins with `PLAYTHROUGH_PACING: ` and contains eligibility, completeness, actual order validity, milestone/chapter times, active/wall/paused totals, target metadata, and verdicts. The combined progression log contains two identical copies because it concatenates engine and console streams; the runtime emission itself is single. Logs are generated artifacts, not committed proof. Preserve a dated external test report if release evidence must survive cleanup.

## Physical Playthrough Evidence Runner

`tests/run-physical-playthrough.ps1` is a manual evidence wrapper, not a thirteenth automated check. Its default `EditorF5` mode opens Godot Editor and waits while the tester physically presses F5, starts a fresh shift, reaches visible credits, and closes the game/editor. `ProjectRun` launches the configured main scene directly. Both modes preserve new same-session engine and console logs under `.artifacts/manual-playthrough/<timestamp>/`.

The parser deduplicates identical engine/console copies of one payload and refuses two distinct payloads, preventing evidence from separate runs being merged. It rejects engine/script/parse/ObjectDB-leak failure lines and verifies fresh-Lobby eligibility, completion, exact boundary order, no missing milestones, the fixed 900–1200-second target metadata, active total, every chapter verdict, and the final total verdict. The generated summary records commit, UTC start/end, launch mode, engine exit, log failures, physical-input declaration, capture reference, log paths, pacing checks, and C:/D: free space.

`evidence_package_ready` requires all pacing checks, zero scanned log failures, a normal launched-process exit, `-ConfirmPhysicalInput`, and a non-empty `-CaptureReference`. The script always records `review_required: true`: it does not inspect video contents, prove operating-system input, or judge the manual matrix. `-AnalyzeLog` intentionally cannot make an evidence package ready.

Parser verification on 2026-07-16 covered four adversarial cases: the canonical 6.58-second compressed log was rejected; a synthetic 1000-second structurally valid payload passed pacing but remained package-ineligible in analysis mode; a log with two distinct payloads was rejected rather than mixed; and a structurally valid payload beside a synthetic `ERROR:` line recorded the failure and remained package-ineligible. Synthetic fixtures were deleted and are not release evidence.

## Required Manual Matrix

No current automated check fully verifies the following. Record each result, environment, date, tester, and evidence link before a release claim.

| Area | Manual procedure | Evidence required |
|---|---|---|
| Intended flow | Start a fresh shift with F5, use physical keyboard/mouse, reach credits without method calls | complete capture or timestamped trace |
| Pacing | Record a fresh blind/new-player run and preserve the `PLAYTHROUGH_PACING: ` payload emitted at the same run's credits | capture plus eligible/complete/order-valid payload; compare chapter durations and active total with the 900–1200 second target |
| Physical traversal | Walk/sprint through every closed/open door, loop return, Room 407, and chase route | no snag/bypass report and capture |
| Chase fairness | Complete, fail once, recover, and complete again | distance/readability/collision observations |
| Visual balance | Check corridor darkness, flashlight, blackout, flicker, grain, red guide lights, and ending reveal | screenshots/video on target hardware |
| Audio balance | Listen to phone, narration tones, ambience, footsteps, radio static, chase, fail, and ending | device plus bus-level observations |
| Settings UI workflow | Change values through the panel, **SAVE & CLOSE**, quit, relaunch, and inspect the controls; separately force/observe a failed save and choose retry or discard | before/after capture; automated config persistence and failure UI already pass |
| Comfort/input | Toggle flicker, head bob, shake, grain, fullscreen; pause/resume and open settings | mouse capture and toggle behavior trace |

Do not mark 15-20 minute pacing, visual/audio balance, audible output, full physical traversal, or the physical Settings UI workflow as verified until this evidence exists.

## References

- [`run-headless-tests.ps1`](../tests/run-headless-tests.ps1)
- [`run-physical-playthrough.ps1`](../tests/run-physical-playthrough.ps1)
- [`game-state-test.gd`](../tests/game-state-test.gd)
- [`progression-test.gd`](../tests/progression-test.gd)
- [`checkpoint-layout-test.gd`](../tests/checkpoint-layout-test.gd)
- [`chase-sequence-controller.gd`](../scripts/world/chase-sequence-controller.gd)
- [`chase-entity.gd`](../scripts/world/chase-entity.gd)
- [`playthrough-pacing-telemetry.gd`](../scripts/world/playthrough-pacing-telemetry.gd)
- [`physical-route-smoke-test.gd`](../tests/physical-route-smoke-test.gd)
- [`player-input-integration-test.gd`](../tests/player-input-integration-test.gd)
- [`player-flashlight.gd`](../scripts/player/player-flashlight.gd)
- [`visual-effects-test.gd`](../tests/visual-effects-test.gd)
- [`settings-audio-test.gd`](../tests/settings-audio-test.gd)
- [`settings-persistence-write-test.gd`](../tests/settings-persistence-write-test.gd)
- [`settings-persistence-read-test.gd`](../tests/settings-persistence-read-test.gd)
- [`settings-manager.gd`](../scripts/autoload/settings-manager.gd)
- [`settings-panel.gd`](../scripts/ui/settings-panel.gd)
- [`pause-menu.gd`](../scripts/ui/pause-menu.gd)
- [`boot-menu.gd`](../scripts/ui/boot-menu.gd)
- [`menu-settings-regression.gd`](../tests/menu-settings-regression.gd)
- [`audio-manager.gd`](../scripts/autoload/audio-manager.gd)
- [`visual-effects-layer.gd`](../scripts/ui/visual-effects-layer.gd)
- [`retro-screen-overlay.gdshader`](../shaders/retro-screen-overlay.gdshader)
- [Known limitations](limitations.md)
