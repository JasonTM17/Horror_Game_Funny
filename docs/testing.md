# Testing

## Overview

The repository has two equivalent twelve-check Godot 4.7.1 headless runners:

| Runner | Host | Entry |
|---|---|---|
| `tests/run-headless-tests.ps1` | Windows + installed Godot 4.7.1 | PowerShell |
| `tests/run-headless-tests.sh` | Linux / Docker | bash + `godot` on `PATH` or `$GODOT` |

Both drive the same twelve checks and fail on non-zero exit, missing success markers, or scanned engine/script/leak/assert failures. They prove resource loading, selected logic/layout invariants, targeted production-player movement/collision and input-handler behavior, pacing-telemetry contracts, visual-effects contracts, and settings persistence across two separate processes. Windows export verification is a separate packaging/startup gate and does not add a thirteenth check. None of these replace a manual F5 boot-to-credits playthrough.

## Run the Suite

### Windows host

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

### Docker

```powershell
docker compose build suite
docker compose run --rm suite
```

The image is multi-stage, pins Godot **4.7.1** standard (not .NET), runs as non-root UID **65532**, and uses `HEALTHCHECK` via `godot --version`. Image tag: `nguyenson1710/horror-game-suite`. Structural packaging contracts (no Docker Engine required):

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\verify-docker-packaging.ps1
```

On Linux: `bash tests/verify-docker-packaging.sh`.

The host PowerShell runner sets repository-local `TEMP` and `TMP` to `.tmp/`, creates a unique Godot `APPDATA`/`LOCALAPPDATA` profile below that directory, creates `.artifacts/`, and writes `.artifacts/test-<name>.log` for each check. The shell runner isolates under `.tmp/godot-user-*` with XDG paths. Both combine engine log with captured console output and tear the profile down after success or failure so they do not overwrite the normal `user://room407.cfg`.

## Verify the Windows x86_64 Export

The repository tracks `export_presets.cfg` with one credential-free, unsigned `Windows Desktop x86_64` release preset. Its PCK is embedded in the executable; development-only paths (`tests/`, `docs/`, `plans/`, temporary folders, and prior build-output folders) are excluded. The preset's default output and the verifier's output both stay below ignored `.artifacts/` paths.

Prerequisites:

- Godot 4.7.1 standard (not .NET) at the verifier's `-Godot` path;
- the matching `windows_release_x86_64.exe` template installed under the portable editor's `editor_data/export_templates/4.7.1.stable/` directory.

The official 4.7.1 standard export-template archive used on the recorded Windows host has SHA-256 `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72`. The archive and installed templates are required local build inputs but are not committed.

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\verify-windows-export.ps1
```

The verifier parses and binds checks to the selected preset, verifies the exact Godot version and official template-archive/member/installed-template hashes, rejects credentials/signing/remote deployment/resource encryption/unexpected filters, rejects reparse-point output/profile ancestors, and takes an exclusive export lock. It exports through a unique staging tree and isolated profile, scans the fresh export logs, copies `LICENSE`, `THIRD_PARTY_NOTICES.md`, and `GODOT_COPYRIGHT.txt`, runs the staged executable directly in headless mode, scans startup logs, verifies PE machine `0x8664`, and only then replaces the published files in the same directory with the executable last. Temporary profiles, staging trees, publish files, and the lock are removed in `finally`.

The hardened 2026-07-18 Windows gate produced a `117914600`-byte release executable with SHA-256 `e783cfa076d1bf4c9bbf7da7301b233fcded9235fa52ba6bbe595018688ff30e` and completed a direct headless process-startup smoke without scanned error markers. The official template archive hash was `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72`, the matched installed template hash was `76269a403bb832599edeee4432a5b7a7e88c018eb5c9c798dfd8289359b0ec07`, and the bundled Godot inventory hash was `cb1980c88089573bcacd7221d777c689bb8bbd778799f24c27fca0fe5f774d6d`. Generated output remains ignored and reproducible rather than committed; record the current verifier markers, size, and hash with any later release handoff. This proves exportability, architecture, notice staging, and headless process startup only. It does not prove a rendered menu, operating-system input, audible output, fullscreen transitions, target-GPU performance, code signing, or installer/store behavior.

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
| 1 | `editor-import` / `test-editor-import.log` | `--editor --quit`, then `project-settings-stability-test.gd` | project imports; scripts/resources parse; canonical save bytes exactly match committed `project.godot` | rendered gameplay, input, audio output |
| 2 | `menu` / `test-menu.log` | `scenes/boot/boot.tscn`; `--quit-after 120` | boot scene loads under its configured smoke limit | button navigation with physical input, visual layout |
| 3 | `gameplay` / `test-gameplay.log` | `scenes/gameplay/gameplay.tscn`; `--quit-after 300` | continuous runtime scene constructs and survives the smoke window | full route traversal or progression |
| 4 | `game-state` / `test-game-state.log` | `game-state-test.gd` | item/flag idempotency, checkpoint inventory restore, and post-restore collection isolation from the saved snapshot | scene recovery, disk persistence |
| 5 | `progression` / `test-progression.log` | `progression-test.tscn`; `--quit-after 60000` | guarded progression; imported double-sided story-clue textures and corridor-facing Room 407 drawing; fixed floor/photo/cassette/rabbit/Room scare anticipation and reveal, unique cue IDs, both emissive Room eyes, non-colliding actors, scaled pause-safe waits, repeated-trigger rejection, light/audio/actor ownership, cassette narration-bound cleanup, director-exit cleanup; production stage thresholds, blackout/radio/final-note gates, production-threshold chase start, scheduled-physics proximity capture, terminal capture/ending overlap, two-step epilogue gating, delayed exactly-once credits/input lock, display-named carried item without inventory header, gameplay-HUD suppression behind credits, checkpoint immutability, and complete fresh-run pacing order/pause/finalization/deep-copy assertions | physical input, player-driven chase traversal, real pacing, rendered scare/presentation quality, audible mix |
| 6 | `checkpoint-layout` / `test-checkpoint-layout.log` | `checkpoint-layout-test.tscn`; `--quit-after 120000` | room spawn and Variant3 restore, barriers/doors, alternating chase obstruction collision and capsule clearance, connected navigation bypass path, real-LOS entity traversal, APPEAR pause, measured STALK/CHASE speeds, pause freeze, LOS/last-seen, reacquisition, bounded SEARCH/DESPAWN, restart/exit behavior, retreat recovery, entity-parented SFX cue at start/recovery plus teardown, authored distances, production-ray acquisition of both epilogue props, same-scene interaction order and lock timing, restored checkpoint immutability, plus restored-run pacing ineligibility/null verdict, visible-credits finalization, reset immutability, and out-of-order rejection | player-driven chase feel, rendered route/epilogue readability, audible cue/mix quality, fresh-run pacing |
| 7 | `physical-route` / `test-physical-route.log` | `physical-route-smoke-test.tscn`; `--quit-after 120000` | optional drawer/painted-door visibility alignment, production-ray acquisition, mapped feedback/cooldowns, drawer sweep/animation lock safety, unchanged story state, and spatial-tone/lock teardown; production `CharacterBody3D` receives synthesized movement through three locked/open doors; prerequisite thresholds, Room 407 checkpoint, and chase creation | rendered optional-prop quality, audible tone/mix quality, OS-delivered E/W, complete route, puzzles, timing, chase feel |
| 8 | `player-input` / `test-player-input.log` | `player-input-integration-test.tscn`; `--quit-after 30000` | separate physical-only and logical-only bindings for WASD/Shift/E/F/Escape/Tab; production ray/handlers accept synthesized actions for phone, objective, pause, flashlight, note Escape, and door cycles; story direction has no technical header and empty inventory stays hidden; unsafe open/close inside the 1.5 m sweep has no state side effect; safe tweens hold only movement and release it; flashlight flicker stays within energy bounds and freezes while paused; authored head pose and head-bob reset | OS-delivered keys/mouse, input latency, mouse-look/door feel, full traversal |
| 9 | `visual-effects` / `test-visual-effects.log` | `visual-effects-test.tscn`; `--quit-after 3000` | overlay shader/material and dither/VHS/fear uniforms exist; chase/ending fear targets and film-grain visibility toggle respond | rendered pixels, readability, comfort, GPU performance, monitor gamma |
| 10 | `settings-audio` / `test-settings-audio.log` | `settings-audio-test.tscn`; `--quit-after 60000` | Master plus Music/SFX/Ambience/Chase/Voice buses, first-run default and mirrored Voice levels, idempotent Voice-keyed SFX ducking and Master limiting, selected clamps, parameter/loop-aware audio variants, LRU/live-stream protection, spatial teardown, controls, textured boot-menu background, pause/boot modal focus and launcher return, save-failure retry/discard, audio teardown, in-memory Continue; all 76 voice cues/imports across 22 exact sequence groups, protected Voice routing/SFX-level control/pause/single-voice contracts, real-cue pause/resume, external-subtitle interruption, replacement, fallback, queue duplicate/order/reentrancy, unscaled long-cue hold, at least 21 seconds of voiced epilogue material, malformed-manifest rejection, and teardown; voice and menu regressions run as nested helpers | audible voice/effects quality, ducking/mix balance, rendered menu quality, and physical UI navigation |
| 11 | `settings-persistence-write` / `test-settings-persistence-write.log` | `settings-persistence-write-test.tscn`; `--quit-after 1200` | writes 11 distinct bounded settings to isolated `room407.cfg` | real player profile and physical UI save action |
| 12 | `settings-persistence-read` / `test-settings-persistence-read.log` | `settings-persistence-read-test.tscn`; `--quit-after 1200` | a new Godot process restores all 11 values from the same isolated profile | target-device fullscreen transition and physical UI interaction |

Checks 1 and 4-12 require these ten success markers respectively:

```text
PROJECT_SETTINGS_STABILITY_OK
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

The runner fails on a non-zero Godot exit, a missing expected marker, or matching log text for engine/script/parse errors, ObjectDB leak warnings, and the progression, layout, physical-route, player-input, visual-effects, or settings assertion prefixes. Menu and gameplay smoke have no success marker; editor import runs the project-settings post-script and requires its marker.

The runner passes finite frame/iteration watchdogs through `--quit-after`. In particular, progression uses 60000, checkpoint-layout and physical-route use 120000, player-input uses 30000, visual-effects uses 3000, settings-audio uses 60000, and settings persistence uses 1200. Reaching a watchdog is not a pass: every marker-based check must print its expected marker before exit. These values are test safety caps, not gameplay durations.

Pacing assertions extend the existing `progression` and `checkpoint-layout` checks. The suite remains exactly twelve checks; there is no separate thirteenth pacing check.

## Reproducible Visual-Capture Tour

`tests/visual-capture-tour.tscn` is a separate staged QA/documentation harness. It is not invoked by `run-headless-tests.ps1`, does not add a thirteenth check, and is not the manual evidence runner.

Run it from the repository root with Godot 4.7.1:

```powershell
New-Item -ItemType Directory -Force .\.artifacts\visual-capture-current | Out-Null
godot --path . `
  --write-movie .artifacts/visual-capture-current/room-407-tour.avi `
  --fixed-fps 12 `
  --log-file .artifacts/visual-capture-current/engine.log `
  res://tests/visual-capture-tour.tscn -- `
  --output-root=res://.artifacts/visual-capture-current
```

The harness creates the output directory, instantiates `scenes/gameplay/gameplay.tscn`, waits for runtime composition, disables gameplay processing, player physics, and voice playback, then stages eight viewpoints, including a dedicated final-clue view. It teleports the production player, directly selects hallway/chase/epilogue state, positions the chase entity, and manually instantiates `scenes/ui/ending-overlay.tscn`. The harness writes eight PNGs under `.artifacts/visual-capture-current/`, prints one **VISUAL_CAPTURE_FRAME** line per PNG, and finishes with **VISUAL_CAPTURE_TOUR_OK**; Godot Movie Maker separately writes the 1280×720, 12 fps AVI requested by the command. A headless display is rejected before capture with exit code 2, so a dummy renderer cannot produce a false success marker.

The recorded capture environment was Godot 4.7.1 Compatibility/OpenGL 3.3 with NVIDIA driver 581.08 on an NVIDIA GeForce RTX 3060 Laptop GPU. The immersive-copy refresh used `.artifacts/visual-capture-ui-polish-v2/` as its exact ignored source root; the command above keeps `visual-capture-current` as the stable path for future reproductions. This is single-machine provenance, not pixel determinism or cross-hardware certification.

Four reviewed artifact PNGs were resized and optimized to 960×540 with ImageMagick 7.1.2 and copied to [`docs/screenshots/`](./screenshots/): [lobby](./screenshots/room-407-lobby.png), [Room 407 bedroom](./screenshots/room-407-bedroom.png), [chase entity](./screenshots/room-407-chase-entity.png), and [ending reveal](./screenshots/room-407-ending-reveal.png). The [640×360 visual-reference GIF](./screenshots/room-407-gameplay-tour.gif) was derived separately with FFmpeg 8.1.1 at 8 fps using `palettegen` with `max_colors=96` and `paletteuse` with `sierra2_4a`; it contains 59 frames and runs for 7.38 seconds. The four PNGs and GIF total 4.65 MiB. GDScript did not generate the GIF. Source AVI, all eight current source PNGs, and logs remain ignored artifacts.

This tour checks reproducible scene composition and supplies reviewed documentation views only. Because it freezes simulation and selects state directly, it is not an F5 playthrough, gameplay recording, manual test, pacing sample, progression proof, player-driven chase, fairness review, audible-output review, Settings/fullscreen check, or perceptual certification. Use `tests/run-physical-playthrough.ps1` and the manual matrix below for those gates.

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

On 2026-07-18, after the source fixes, Dependabot merge, tracked export preset, and verifier hardening, the Windows host runner passed all 12 checks in about 77.5 seconds. It produced exactly 12 canonical logs, zero scanned current engine/script/assertion/lambda/leak failure lines, and zero remaining `godot-user-*` runner profiles after concurrent verification settled. Focused `progression` and `settings-audio` runs also passed.

A fresh non-root Linux image built from the same runtime tree then passed all 12 checks in about 82.9 seconds with `ALL_TWELVE_HEADLESS_CHECKS_OK`; its `--rm` container left no stopped instance. The hardened Windows export verifier independently reproduced the `117914600`-byte x86_64 executable and direct headless process-startup smoke with SHA-256 `e783cfa076d1bf4c9bbf7da7301b233fcded9235fa52ba6bbe595018688ff30e`. Rerun all applicable gates after later source changes before treating a handoff artifact as current.

This evidence proves automated contracts only. The compressed progression fixture remains unsuitable for 15–20 minute pacing evidence, and no headless result certifies rendered scare timing/quality, audible mix, spatial perception, physical input, or a full physical route. Earlier automated runs remain historical evidence only.

## Synthetic Actions Versus Physical Input

The automation reaches production code, but it does not inject operating-system keyboard or mouse events:

- `physical-route-smoke-test.gd` calls `Input.action_press("move_forward")` / `Input.action_release("move_forward")` for route movement. Its optional-interaction helper also constructs an `interact` action and passes it directly to the production interaction handler after forcing the production ray update. The normal controller, ray, and interactables run, but Windows delivers no physical W or E key.
- `player-input-integration-test.gd` verifies separate physical-only and logical-only InputMap events for WASD/Shift/E/F/Escape/Tab, then constructs `InputEventAction` objects and passes them directly to production `_unhandled_input()` methods. This exercises the production ray, locks, door logic, and UI handlers without proving that Windows delivered those keys from hardware.
- `progression-test.gd` calls story methods and radio widget methods directly. It does not type into the `LineEdit`, click buttons, or close the final note through a real device.

Physical keyboard/mouse traversal, event delivery, mouse capture, and input feel therefore remain manual requirements.

## Progression Coverage

`progression-test.gd` instantiates the production gameplay scene and calls its public story facade. Narrative duration is reduced only for test execution. It verifies:

- fresh-run ending and early logbook rejection;
- direct action calls reject premature lobby, floor, memory-loop, radio, and Room 407 interactions instead of relying only on hidden prompts;
- phone briefing, stopped-clock and night-register observations, logbook, floor-notice observation, fuse pickup/install, and power stabilization;
- phone, observations, logbook, fuse, memories, radio, and Room 407 actions preserve one-shot behavior and expected inventory side effects;
- the carried fourth-floor key appears as `Fourth-floor key`, without the internal `floor_key` ID or a `POCKETS` header;
- the four fixed buildup scares—floor arrival, photograph, cassette turn-away, and rabbit—plus the Room 407 climax stage anticipation before reveal and clean their aftermath without random selection;
- every scare cue ID is unique; local lights restore exactly; shared factory actors have no collision objects; repeated event triggers cannot duplicate actors or sequences;
- scaled waits and cassette reveal cleanup freeze while paused; an unrevealed cassette actor ends at `memory_cassette_recalled`; director exit releases owned audio/cache entries, lights, and actors;
- scare lifecycle code does not stop or replace the narrative voice queue;
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
- `ContinuousCorridorNavigation` exists with 13 connected convex segments that taper through three alternating bypasses and reach the exit-side endpoint;
- every chase obstruction blocks its authored lane, retains measured player/entity capsule clearance, and aligns exact red text, floor-marker, and guide-light cues with the safe lane;
- a production entity with live LOS traverses the first physical obstruction, deviates into the bypass, remains in `CHASE`, and does not enter failure recovery;
- the entity remains frozen during `APPEAR`, reaches `STALK`, and records measured `STALK` and full-speed `CHASE` movement;
- entity 3.0 is faster than walk 2.0 and slower than sprint 3.1, while pause freezes chase movement;
- chase start creates exactly one bounded `AudioStreamPlayer3D` at the entity origin on SFX, failure removes the stale player, checkpoint recovery creates one replacement, and ending teardown removes both player and cache ownership;
- LOS loss records a last-seen position, traverses `LOST_TARGET`/bounded `SEARCH`, reacquires a nearby player, then reaches `DESPAWN` after the search budget; restart and exit boundaries hide/stop the entity cleanly;
- retreat beyond the chase boundary requests recovery and restores the chase marker;
- a restored Room 407 session is incomplete and ineligible, keeps `within_target` `null`, and represents missing chapter durations as `null`;
- visible credits finalize that restored report, and a subsequent Replay/Menu-style `GameState.reset_run()` cannot mutate it;
- an all-milestone fixture with deliberately invalid occurrence order remains incomplete, reports `boundary_order_valid: false`, and rejects its negative chapter span as `null`;
- representative story props retain recognizable child parts (phone handset, clock digits, book title, rabbit ears, radio dial, and family-table plate);
- memory-loop distance is at least 180 units, chase distance at least 280, and total corridor length at least 850.

These checks now include one live `NavigationAgent3D` obstruction traversal, but they do not move the player capsule through all three chase barriers or prove rendered readability, collision feel, and fairness under a player-driven pursuit.

## Production Movement, Door, and Optional Interaction Coverage

`physical-route-smoke-test.gd` instantiates the production gameplay scene and production `CharacterBody3D`. Its nested `environmental-interaction-route-verifier.gd` first exercises optional targets through the production ray and interaction handler. It verifies:

- the closed drawer face remains outside the opaque desk and the false-door collider aligns with the visible panel;
- the production ray acquires both targets at authored stances;
- the drawer rejects its unsafe sweep stance without motion or a player lock, then opens and closes with one response per accepted mapped action;
- active drawer motion blocks mapped movement with a movement-only lock, suppresses interaction spam, remains in ray range when open, and releases the lock after motion;
- the painted door returns clear feedback, remains fixed, suppresses spam during its cooldown, and accepts interaction again afterward;
- neither optional target changes story state; and
- both spatial tones own live audio/cache entries, while target teardown removes those entries and releases an active drawer lock.

The route portion then presses the mapped `move_forward` action across physics frames, which reaches the player controller's normal `Input.get_vector()` and `move_and_slide()` path. It verifies:

- the floor, power, and Room 407 doors remain closed without their prerequisite flags;
- the capsule receives forward movement but stops at each locked door;
- each valid flag opens its door and lets the same capsule cross the passage;
- valid door interactions begin outside the authored 1.5 m sweep instead of unrealistically opening while the capsule is pressed into the rotating panel;
- the memory threshold rejects entry before `power_stable` and activates after it;
- the Room 407 threshold creates the expected gameplay-scene checkpoint snapshot; and
- the chase threshold rejects premature entry, then starts once `chase_ready` and creates a valid entity.

The harness teleports between focused targets and gates, forces ray updates, passes a constructed interaction action directly to the production handler, sets prerequisite flags, and calls guarded route doors directly. It does not deliver operating-system E/W input, solve the complete puzzles, traverse every meter, exercise a player-driven chase, judge rendered visibility or audible tone balance, or measure 15-20 minute pacing.

## Player Input Integration Coverage

`player-input-integration-test.gd` instantiates the production gameplay scene, production player, production interaction ray, and production door logic. It verifies:

- authored eye height `1.52` and initial head pitch `-8.0` degrees;
- separate physical-only and logical-only key events exist for the nine WASD/Shift/E/F/Escape/Tab actions, and the interaction ray uses collision mask `4`;
- after focused player placement and a forced ray update, a synthesized `interact` action reaches the phone through the production interaction handler;
- the HUD shows the story direction without an `OBJECTIVE` header and keeps its empty inventory label hidden;
- synthesized objective, pause, and flashlight actions refresh the HUD, preserve the flashlight state while paused, and toggle it after resume;
- a test-created production note reader locks input, then a synthesized Escape action closes the note and releases the lock;
- the production ray reaches the floor door; a locked attempt stays closed; repeated synthesized interaction during the opening tween does not cancel it; and the same door closes and reopens after ray reacquisition from the appropriate side;
- player positions inside the authored 1.5 m sweep receive the move-clear prompt and cannot start either close or reopen, change rotation/cooldown, emit the success signal, lose the permanent unlock, or acquire a movement lock;
- a safe open/close/reopen acquires a per-door movement-only lock, blocks mapped movement without setting a full input lock, and releases the reason after every completed tween; and
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

`settings-audio-test.gd` verifies the presence of Master, Music, SFX, Ambience, Chase, and internal Voice buses. It also proves Voice sends to Master, mirrors the SFX setting, keys an idempotent compressor on SFX, and coexists with a single Master hard limiter. It asserts these boundary examples and the generated-audio lifecycle:

| Setter call | Expected clamp |
|---|---:|
| mouse sensitivity `99.0` | `0.25` |
| field of view `12.0` | `60.0` |
| master volume `-99.0` | `-40.0` dB |

It also verifies settings controls for music, SFX, ambience, fullscreen, camera shake, film grain, and reset; parameter-complete one-shot/loop cache keys; capped-duration reuse; LRU recency; protection of cached streams held by regular or spatial players; spatial finish/queued-parent/stop cleanup; `stop_tone()` variant reclamation; and `stop_all()` cache/player/byte-accounting reset. The nested `menu-settings-regression.gd` helper verifies boot/pause modal focus traversal, launcher focus return, hidden-control focus release, and full-rect modal blocking. Its presentation checks require the configured native window title to remain player-facing; require **Camera movement**, **Music**, **Atmosphere**, and **Screen texture**; positively anchor the 23:47 opening, in-world failure line, creator attribution, and closing thank-you; reject checkpoint wording and production metadata; and ensure a failed config save keeps the panel open for retry or discard without showing a raw system error. It also checks a visible **CONTINUE SHIFT** button after creating an in-memory checkpoint. Headless mode cannot inspect the operating-system title bar, so the runtime suffix removal still requires a non-headless visual check.

The nested `voice-over-regression.gd` helper validates the 22 expected narrative groups and all 76 importable OGG cues, schema/field/role/path rejection, exact cue/subtitle matching, lazy stream loading, protected Voice routing under the SFX user level, real-cue playback-position pause/resume, external-subtitle interruption, replacement/stop behavior, a long line whose voice duration cannot be shortened by compressed test timing, and at least 21 seconds across the six ending cues. It also drives production `NarrativeSequencer` queue ordering, active/pending duplicate rejection, synchronous signal reentrancy, pause freeze/resume, completion flags, and free-during-wait cancellation. The full progression fixture independently records every accepted production sequence and requires exact manifest matches for all 76 cue IDs/texts. Progression, physical-route, and player-input fixtures disable actual voice output so their compressed timing remains intentional rather than depending on asset duration.

The writer process saves distinct values for all 11 settings into an isolated `user://room407.cfg`; it checks the returned `Error` instead of silently accepting a failed write. The reader starts as a new Godot process with the same temporary profile and asserts every value after autoload initialization calls `load_settings()`. This proves config persistence without touching the normal player profile. It does not send physical UI events or prove fullscreen/display behavior on target hardware. Headless voice tests prove resource decoding and runtime contracts, not intelligibility, character performance, audible output, or mix quality on a target device.

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
.artifacts/builds/room407-windows-x86_64/export.log
.artifacts/builds/room407-windows-x86_64/export-console.log
.artifacts/builds/room407-windows-x86_64/smoke-engine.log
.artifacts/builds/room407-windows-x86_64/smoke-console.log
```

Use the console summary for quick status and the matching log for diagnosis. A pacing payload begins with `PLAYTHROUGH_PACING: ` and contains eligibility, completeness, actual order validity, milestone/chapter times, active/wall/paused totals, target metadata, and verdicts. The combined progression log contains two identical copies because it concatenates engine and console streams; the runtime emission itself is single. Logs are generated artifacts, not committed proof. Preserve a dated external test report if release evidence must survive cleanup.

## Physical Playthrough Evidence Runner

`tests/run-physical-playthrough.ps1` is a manual evidence wrapper, not a thirteenth automated check. Its default `EditorF5` mode opens Godot Editor and waits while the tester physically presses F5, starts a fresh shift, reaches visible credits, and closes the game/editor. `ProjectRun` launches the configured main scene directly. Both modes preserve new same-session engine and console logs under `.artifacts/manual-playthrough/<timestamp>/`.

The parser deduplicates identical engine/console copies of one payload and refuses two distinct payloads, preventing evidence from separate runs being merged. It rejects engine/script/parse/ObjectDB-leak failure lines and verifies fresh-Lobby eligibility, completion, exact boundary order, no missing milestones, the fixed 900–1200-second target metadata, active total, every chapter verdict, and the final total verdict. The generated summary records the unchanged clean branch/commit before and after the run, Godot path/version, UTC start/end, launch mode, engine exit, log failures, physical-input declaration, capture reference, log paths, pacing checks, C:/D: free space, and an unchecked human-review matrix.

`evidence_package_ready` requires an unchanged clean branch/commit, all pacing checks, zero scanned log failures, a normal launched-process exit, `-ConfirmPhysicalInput`, and a non-empty `-CaptureReference`. The script always records `review_required: true`: it does not inspect video contents, prove operating-system input, or judge the manual matrix. `-AnalyzeLog` intentionally cannot make an evidence package ready.

Parser verification on 2026-07-16 covered six adversarial cases: the canonical 6.58-second compressed log was rejected; a synthetic 1000-second structurally valid payload passed pacing but remained package-ineligible in analysis mode; a log with two distinct payloads was rejected rather than mixed; a structurally valid payload beside a synthetic `ERROR:` line recorded the failure; a dirty worktree was marked unstable; and a clean post-commit analysis preserved identical before/after SHAs while remaining package-ineligible. Synthetic fixtures were deleted and are not release evidence.

## Required Manual Matrix

No current automated check fully verifies the following. Record each result, environment, date, tester, and evidence link before a release claim.

| Area | Manual procedure | Evidence required |
|---|---|---|
| Intended flow | Start a fresh shift with F5, use physical keyboard/mouse, reach credits without method calls | complete capture or timestamped trace |
| Pacing | Record a fresh blind/new-player run and preserve the `PLAYTHROUGH_PACING: ` payload emitted at the same run's credits | capture plus eligible/complete/order-valid payload; compare chapter durations and active total with the 900–1200 second target |
| Physical traversal | Walk/sprint through every closed/open door, loop return, Room 407, and chase route | no snag/bypass report and capture |
| Chase fairness | Complete, fail once, recover, and complete again | distance/readability/collision observations |
| Visual balance | Check corridor darkness, flashlight, blackout, flicker, grain, red guide lights, and ending reveal | screenshots/video on target hardware |
| Audio balance | Listen to all 76 English story cues, including the six ending revelations, plus phone, fixed story-scare layers, procedural feedback, ambience, footsteps, radio static, the positional entity cue at chase start/recovery, chase drone, fail, and ending | device plus bus-level and spatial observations |
| Settings UI workflow | Change values through the panel, **SAVE & CLOSE**, quit, relaunch, and inspect the controls; separately force/observe a failed save and choose retry or discard | before/after capture; automated config persistence and failure UI already pass |
| Comfort/input | Toggle flicker, head bob, shake, grain, fullscreen; pause/resume and open settings | mouse capture and toggle behavior trace |
| Exported build | Launch the generated Windows executable normally on target hardware, operate the boot menu, and start a shift | rendered-window, physical-input, fullscreen, performance, and audible-output observations; headless export smoke already passes |

Do not mark 15-20 minute pacing, visual/audio balance, audible output, full physical traversal, or the physical Settings UI workflow as verified until this evidence exists.

## References

- [`run-headless-tests.ps1`](../tests/run-headless-tests.ps1)
- [`run-physical-playthrough.ps1`](../tests/run-physical-playthrough.ps1)
- [`verify-windows-export.ps1`](../tests/verify-windows-export.ps1)
- [`export_presets.cfg`](../export_presets.cfg)
- [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md)
- [`GODOT_COPYRIGHT.txt`](../GODOT_COPYRIGHT.txt)
- [`visual-capture-tour.gd`](../tests/visual-capture-tour.gd)
- [`visual-capture-tour.tscn`](../tests/visual-capture-tour.tscn)
- [`game-state-test.gd`](../tests/game-state-test.gd)
- [`progression-test.gd`](../tests/progression-test.gd)
- [`horror-event-director.gd`](../scripts/world/horror-event-director.gd)
- [`horror-scare-sequence.gd`](../scripts/world/horror-scare-sequence.gd)
- [`horror-apparition-factory.gd`](../scripts/world/horror-apparition-factory.gd)
- [`turn-away-apparition.gd`](../scripts/world/turn-away-apparition.gd)
- [`checkpoint-layout-test.gd`](../tests/checkpoint-layout-test.gd)
- [`chase-sequence-controller.gd`](../scripts/world/chase-sequence-controller.gd)
- [`chase-entity.gd`](../scripts/world/chase-entity.gd)
- [`playthrough-pacing-telemetry.gd`](../scripts/world/playthrough-pacing-telemetry.gd)
- [`physical-route-smoke-test.gd`](../tests/physical-route-smoke-test.gd)
- [`environmental-interaction-route-verifier.gd`](../tests/environmental-interaction-route-verifier.gd)
- [`drawer-interactable.gd`](../scripts/interaction/drawer-interactable.gd)
- [`atmospheric-door-interactable.gd`](../scripts/interaction/atmospheric-door-interactable.gd)
- [`player-input-integration-test.gd`](../tests/player-input-integration-test.gd)
- [`player-flashlight.gd`](../scripts/player/player-flashlight.gd)
- [`visual-effects-test.gd`](../tests/visual-effects-test.gd)
- [`settings-audio-test.gd`](../tests/settings-audio-test.gd)
- [`voice-over-regression.gd`](../tests/voice-over-regression.gd)
- [`voice-over-player.gd`](../scripts/audio/voice-over-player.gd)
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
