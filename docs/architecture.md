# Architecture

## Overview

ROOM 407 uses one boot scene, one continuous gameplay scene, typed GDScript controllers, four autoload services, procedural world construction, and composed UI scenes. The configured runtime is Godot 4.7.1 using the Compatibility renderer.

The gameplay scene file contains only a `Node3D` with `GameplayDirector`. At runtime, the facade builds the corridor, navigation region, story interactables, player, UI, events, hallway variants, progression controller, and chase controller, then starts a scene-local pacing component after composition is complete.

## Runtime Flow

```text
F5 / project start
  -> boot.tscn
  -> START SHIFT or process-local CONTINUE CHECKPOINT
  -> gameplay.tscn
       -> continuous lobby / floor 4 / memory loop / Room 407 / chase
       -> abandoned-lobby reveal and ending overlay in the same scene
       -> replay gameplay or return to boot
```

F6 is editor current-scene execution and can skip the boot scene. The memory loop never changes gameplay scenes: `HallwayTransitionLayer` fades to black, invokes a midpoint hallway swap/reposition, waits, and fades back in.

## Gameplay Controller Split

| Component | Current responsibility |
|---|---|
| `GameplayDirector` | Runtime facade; assembles the scene, spawns player/UI, watches zone boundaries, and delegates public story/chase calls |
| `StoryProgressionController` | Interaction prompts, story guards, inventory/flags, narrative completion, memory-loop transitions, radio/note UI, checkpoints, and ending prerequisites |
| `ChaseSequenceController` | Entity creation, chase start, corridor-light failure, capture recovery, abandoned-lobby reveal, and exactly-once visible credits boundary |
| `EndingEpilogueController` | Same-scene condemnation notice/roster props, ordered narration gates, ending prompts/actions, and credits request |
| `PlaythroughPacingTelemetry` | Scene-local eligibility snapshot, first-occurrence milestone order, pause-aware timing, target evaluation, visible-credits finalization, and one runtime JSON line |
| `DynamicHallwayController` | Four visibility-switched corridor variants and memory-driven dressing changes |
| `HorrorEventDirector` | Idempotent, local visual/audio events and apparitions |
| `NarrativeSequencer` | Timed subtitle lines, exact manifest-backed voice cues, fallback ticks, and completion flags |
| `VisualEffectsLayer` | Full-screen retro shader, settings visibility, and stage-driven fear intensity |

`GameplayDirector` exposes a small facade (`get_story_prompt`, `handle_story_action`, `on_radio_solved`, `on_note_closed`, `fail_chase`, and `finish_ending`) so interactables and UI do not need direct references to the specialized controllers.

## World Construction

`ContinuousWorldBuilder` creates the shared environment, 870-unit corridor shell, partitions, Room 407 dressing, lights, guide lights, and navigation region. The authored dressing includes the fourth-floor elevator display/visible false-door panel, the real arrival-door closure and timed apparition, Room 407 wallpaper/height marks/ceiling ribs, and alternating chase wall scars. `ContinuousStoryLayout` creates the story objects, guarded doors, mesh-backed lobby drawer, and an interaction body aligned to that false-door panel. `LevelGeometry` is the low-level box, label, material, and light factory.

The navigation surface is a real `NavigationRegion3D` named `ContinuousCorridorNavigation`. Its `NavigationMesh` contains a four-vertex polygon spanning the playable corridor. This is created directly in code rather than baked from imported meshes.

## Global Services

| Service | Owns | Persistence |
|---|---|---|
| `GameState` | stage, objective, subtitle, inventory, flags, completed events, checkpoint dictionary, pending spawn ID | memory only |
| `SceneRouter` | serialized scene replacement and checkpoint scene reload | none |
| `AudioManager` | runtime buses, procedural PCM cache, named tones and drones | none |
| `SettingsManager` | bounded controls/display/audio/comfort values and config I/O | `user://room407.cfg` |

Autoloads do not own scene nodes or story choreography. `AudioManager` creates missing Music, SFX, Ambience, and Chase buses during startup; Master is Godot's existing bus.

## Interaction and Progression Data Flow

```text
Player interaction ray
  -> StoryInteractable / DoorInteractable
  -> GameplayDirector facade
  -> StoryProgressionController guard
  -> GameState item, flag, stage, objective, or subtitle mutation
  -> signals consumed by HUD and narrative/event controllers
```

Prompt lookup is read-only. Mutating actions guard prerequisites first. `DoorInteractable` additionally rejects player-operated opening and closing while the actor is within its designer-tunable 1.5 m horizontal motion sweep. The check happens before cooldown, signal, item, unlock, or tween mutation. Accepted motion acquires a per-door reason-scoped movement lock and releases it when the tween finishes or the door leaves the tree; event-driven closure can omit an actor and therefore does not claim that player lock. Story stages are monotonic:

`DrawerInteractable` and `AtmosphericDoorInteractable` are state-neutral local branches from the same production ray. The visible lobby drawer translates open and closed, rejects actors inside its 1.45 m sweep, holds a movement-only lock during its tween, and releases that lock on completion or teardown. The collider aligned to the painted false-door panel returns clear fixed-door feedback behind a bounded cooldown. Each owns a per-instance spatial tone stopped during teardown; neither calls the director or mutates `GameState`.

```text
LOBBY
  -> FLOOR4_DARK
  -> FLOOR4_POWERED
  -> MEMORY_LOOP
  -> ROOM_407
  -> CHASE
  -> ENDING
```

Stable lowercase IDs, not display text, identify flags, inventory items, and completed events.

## Pacing Telemetry Data Flow and Lifecycle

`GameplayDirector` creates `PlaythroughPacingTelemetry` after the world, player/UI, story controller, and chase controller are composed. It calls `begin(fresh_run, GameState.stage)`, then connects `ChaseSequenceController.credits_shown` to `record_credits()`. Eligibility is snapshotted once: only a fresh run whose initial stage is `LOBBY` can produce pacing verdicts. A Continue/checkpoint session remains ineligible even if it later reaches credits.

```text
runtime composition complete
  -> begin(fresh_run, initial_stage)
  -> record the initial stage and subscribe to GameState.stage_changed
  -> append each stage's first occurrence in the order actually observed
  -> ending overlay becomes visible and emits credits_shown
  -> record credits, disconnect the stage signal, freeze totals, print one JSON line
```

The expected boundary order is:

```text
lobby -> floor4_dark -> floor4_powered -> memory_loop
      -> room_407 -> chase -> ending -> credits
```

Boundaries are de-duplicated at first occurrence but are not sorted afterward. `complete` therefore requires both no `missing_milestones` and a valid actual order. Missing boundary pairs produce `null` chapter durations, not zero. Ineligible or incomplete runs keep the total `within_target` verdict `null`; a complete eligible run evaluates the independent 900–1200 second total. Chapter verdicts use opening 120–180, floor 4 180–240, memory loop 240–300, Room 407 180–240, and chase/ending 120–180 seconds.

The telemetry node keeps inherited pause behavior. Its normal `_process()` accumulation stops with paused gameplay, while `NOTIFICATION_PAUSED` and `NOTIFICATION_UNPAUSED` use monotonic tick timestamps to accumulate pause intervals. The report exposes wall-clock, active-gameplay, and paused totals; active time is clamped so it cannot exceed unpaused wall time (`wall - paused`) even under a heavily loaded or compressed headless frame.

`GameplayDirector.get_playthrough_pacing_report()` returns a recursive duplicate, so callers cannot change the live report or nested targets. Visible-credits finalization disconnects the stage signal and makes the current instance immutable through duplicate ending calls and replay/menu reset signals; changing scenes frees that instance, and a new gameplay scene creates a new one.

Finalization prints exactly one runtime line prefixed `PLAYTHROUGH_PACING: ` followed by JSON. There is no report file, autoload persistence, or UI. A runner artifact can show two identical lines because `run-headless-tests.ps1` concatenates the engine log and captured console output, not because the runtime emitted twice.

## Hidden Hallway Transitions

`HallwayTransitionLayer` owns a full-screen black curtain and one transition lock. During a transition it:

1. locks the player with the `hallway` reason;
2. fades the curtain to opaque;
3. calls the supplied midpoint action;
4. swaps the hallway variant and optionally moves the actor to `MEMORY_START_Z`;
5. plays the blackout tone and holds the blackout;
6. fades out the curtain and unlocks the player.

The first two memories loop the actor to the memory start. The third memory swaps to the final variant, disables the loop gate, and opens radio progression without teleporting the actor.

## Player Composition

The `CharacterBody3D` player owns movement, bounded look pitch, pause input, input-lock reasons, movement-only lock reasons, head bob, camera shake, flashlight visibility, and settings application. A child interaction node owns the 2.5-unit ray and calls interactable contracts. Full input locks expose the cursor and gate camera look plus flashlight input; selected modal reasons also gate pause. Movement-only locks zero physics velocity while preserving captured mouse, camera look, flashlight, and other unlocked input.

The scene overrides movement defaults to walk speed 2.0 and sprint multiplier 1.55, producing sprint speed 3.1. Movement uses `_physics_process`, normalized input, acceleration toward target velocity, gravity, and `move_and_slide()`.

## Enemy and Navigation

`ChaseSequenceController` creates one entity at chase start and attaches a capsule mesh/collider. The entity root is placed at floor level; the visual capsule and collider use Y offsets `1.25` and `1.2`, so the body does not start half-buried or float. The entity creates a `NavigationAgent3D` during setup and uses these states:

```text
DORMANT -> APPEAR -> STALK -> CHASE -> LOST_TARGET -> SEARCH -> LOST_TARGET
                                      ^             |          |
                                      |             +----------+
                                      +-- reacquire -> CHASE
any active state -------------------------------------------------> DESPAWN
```

When the navigation map is ready, the agent supplies the next path point. Before that, motion falls back to the current target or last visible target vector; it is not a separate waypoint system. The continuous navigation mesh is now 13 connected convex segments. Three physical chase barriers alternate right, left, and right bypasses; each taper uses the same authoritative layout data as its collision body, red text cue, floor marker, and guide light. The narrowest authored navigation lane is 1.55 units, with tested clearance for the 0.34 player capsule and 0.42 entity capsule.

Line of sight is sampled every 0.2 seconds, and `LOST_TARGET`/`SEARCH` use the last visible target position. A successful reacquisition returns to `CHASE`; after the bounded `max_search_cycles` budget the entity enters `DESPAWN`, sets `active=false`, hides itself, and zeros velocity. Player recovery/despawn checks use the authored Z thresholds; the entity itself is not directly clamped to a corridor Z range. Restarting the chase resets search cycles, LOS timing, target position, visibility, and state.

Entity speed is 3.0. The configured player walks at 2.0 and sprints at 3.1; `STALK`, `LOST_TARGET`, and `SEARCH` apply their authored multipliers before full-speed `CHASE`. Automated checks measure these transitions and speeds, verify a server path through all three alternating bypasses, and run one production entity across the first obstruction with live LOS. Manual traversal is still required to validate all-barrier player feel, rendered cue readability, and human chase fairness.

## Chase, Checkpoint, and Ending Flow

At chase readiness, `GameState` captures serializable values and spawn ID `chase_start`. Chase start dims named corridor lights, creates one entity, starts chase audio, and advances the stage. It also creates one 92 Hz, 1.4-second `AudioStreamPlayer3D` under the entity. The cue is routed through SFX and bounded to the normal 18-unit spatial distance, so it follows the source rather than the controller.

Capture recovery happens inside the existing gameplay scene. It restores the checkpoint dictionary, resets the existing player and entity positions, restarts the entity and chase drone, replays one fresh entity-parented presence cue, and releases the fail lock. The stale presence cue is stopped before failure feedback and before every replay; finishing the chase stops the cue and releases its cache ownership. Recovery does not serialize nodes, reload the gameplay scene, or create a replacement enemy.

The boot menu's Continue path is different: when a checkpoint exists in the current process, it calls `SceneRouter.reload_checkpoint()`, which restores state and reloads the snapshot's scene path. During story-controller setup, completed memory flags derive the active hallway variant before control returns to the player. Because `GameState` is not written to disk, Continue disappears after application restart.

Ending success remains in the gameplay scene. The chase controller first makes Ending terminal, cancels any in-flight recovery, stops the entity/audio, and builds abandoned-lobby geometry without applying the ending input lock. `EndingEpilogueController` then creates two gameplay-root `StoryInteractable` props: the 2007 condemnation notice and night roster. Gameplay prompt/action routing checks this controller first only while its Ending flow is active, then falls back to normal story routing.

The notice narration must finish before the roster prompt appears, and the roster narration must finish before the controller requests credits. The player retains movement, look, and interaction during both investigations. The chase controller remains the single credits boundary: `show_credits()` applies the terminal input lock, instantiates and visibly opens `ending-overlay.tscn`, then emits `credits_shown` exactly once so pacing keeps its existing finalization contract. Restored checkpoint collections are deep-copied before becoming live state, preventing the two epilogue completion flags from aliasing and mutating the saved chase snapshot. Replay and Main Menu perform explicit scene changes.

## Settings and Audio

`SettingsManager` clamps values at the service boundary and applies audio levels to named buses. `save_settings()` returns the `Error` from `ConfigFile.save()` and emits `settings_save_failed` on failure. `settings-panel.gd` reads current values on open and applies edits immediately; a successful **SAVE & CLOSE** writes the full config, while a failed save keeps the modal open with a visible error, **RETRY SAVE**, and **CLOSE WITHOUT SAVING**. The discard path closes without writing a new file, so the active values are session-only. Escape closes normally after a successful save and uses the discard path after a failed save.

`AudioManager` precedes `SettingsManager` in the autoload list. It creates the Music, SFX, Ambience, and Chase buses, then `SettingsManager.load_settings()` applies saved levels. When no config exists, the same method calls the four audio setters with their in-code defaults, including mapping music volume to Chase. The settings/audio check starts with an isolated first-run profile and asserts every named bus matches those defaults.

`AudioManager` creates 16-bit, 22,050 Hz mono PCM tones. Cache identity includes the semantic ID, sample rate, frequency, effective duration (capped at four seconds), and loop mode. The cache uses true LRU order with a 16 MiB byte budget; eviction skips streams still referenced by regular or spatial players, and a stream is returned uncached if every resident entry is live. Spatial players unregister on finish or stop, queued/deleted parents are rejected, and `stop_tone()` removes every variant for an ID. `stop_all()` stops streams, clears cache/index/accounting and cache-limit overrides, and frees player nodes synchronously. Drones are skipped under the headless display server, so a successful headless call does not prove audible output.

`NarrativeSequencer` creates one scene-local `VoiceOverPlayer`. Cue identity is the completion flag plus one-based line index, but playback also requires schema 1, required metadata, the exact cue file path, and a manifest subtitle matching the live subtitle; changed text therefore cannot silently play stale speech. Streams load lazily, cache per cue for the scene lifetime, route through SFX, use one voice, and inherit pausable processing. Each subtitle waits for the larger of its authored scaled hold or the unscaled cue duration plus 0.35 seconds. If interaction feedback or another system replaces the owned subtitle, the now-mismatched voice stops immediately while the sequence timer remains deterministic. A missing, malformed, unloadable, or mismatched cue uses the existing dialogue tick/authored wait without blocking the queue. Duplicate active or pending completion flags are rejected, synchronous completion listeners remain serialized behind the existing queue, and sequence or scene teardown stops playback and clears subtitle/runtime state.

`VisualEffectsLayer` creates a full-screen `ColorRect` with the project-authored Compatibility canvas shader. The shader combines 2x2 dithering, VHS horizontal jitter/tracking, animated grain, scanlines, a cold color grade, and an edge vignette. `GameState.stage_changed` targets fear intensity at 1.0 for `CHASE`, 0.12 for `ENDING`, and 0.0 otherwise; the shader darkens and warms the edge as that value rises. `film_grain_enabled` controls visibility of the entire overlay, so disabling **Film Grain** also disables dither, VHS, scanline, grade, and chase fear-vignette effects. `player-flashlight.gd` uses a minimum interval, bounded pulse duration/energy, recovery to base energy, and `PROCESS_MODE_PAUSABLE`; disabling or hiding the light resets its pulse state. Head bob and camera shake read their separate settings at runtime.

## Extension Guide

These are the current extension points verified against the source and headless checks.

### Interaction

1. Add a stable lowercase ID through `_add_story()` or `_add_door()` in `continuous-story-layout.gd`.
2. Keep the player ray on collision mask value `4`, the named Interactable physics bit. Existing story props and doors use collision layer value `5` (`World` value `1` plus `Interactable` value `4`), so the player capsule sees their solid world collision while the interaction ray can acquire them.
3. Use `StoryInteractable` for director-routed actions, `DoorInteractable` for animated guarded doors, `PickupInteractable` for a direct inventory pickup, or a state-neutral `Interactable` subclass for optional local feedback. Each target must retain a `CollisionShape3D` and implement the `get_prompt()` / `interact()` contract inherited from `Interactable`.
4. Add a production-ray assertion to `player-input-integration-test.gd`; use `physical-route-smoke-test.gd` as well when the object must block or clear player movement. The existing environmental helper demonstrates sweep, cooldown, state-neutrality, and spatial-audio teardown coverage inside that check.

### Story Beat

1. Register the prop and ID in `ContinuousStoryLayout`.
2. Put prompt prerequisites in `StoryProgressionController.get_prompt()` and repeat the guard in `handle_action()` or its delegated method; hidden prompt text is not an authorization boundary. Observation-only sequences belong in `StoryObservationController`.
3. Store durable run state through stable `GameState` flags/items/stages, update the objective explicitly, and send timed lines through `NarrativeSequencer` when completion must occur after playback.
4. Extend `progression-test.gd` with premature rejection, accepted progression, one-shot behavior, and exact state side effects. Add checkpoint restore assertions when the beat can exist before a Continue reload.

### Hallway Variant

`DynamicHallwayController._build_variant_props()` owns the geometry below `Variant0` through `Variant3`; add or replace dressing under the intended `variant_roots[index]`. A new state beyond those four also requires increasing the root-creation count, changing the clamp in `reconfigure_for_memory()`, extending the ordered memory IDs/count thresholds in `StoryProgressionController`, and updating the restored-variant assertions in `checkpoint-layout-test.gd`. The current three-memory contract deliberately caps the final state at index 3.

### Setting

1. Add a typed default, bounded setter, `setting_changed` emission, reset value, and save/load key in `settings-manager.gd`.
2. Add the control to `settings-panel.tscn`, initialize and connect it in `settings-panel.gd`, and make the runtime consumer read the current value plus subscribe to changes when live updates are required.
3. Extend both persistence processes for the new serialized value. Add boundary or initial-application coverage to `settings-audio-test.gd`; visual overlay behavior belongs in `visual-effects-test.gd`.

### Test Check

Create a focused `.gd` script and `.tscn` harness under `tests/`, print one unique success marker only after all assertions pass, then add one `Invoke-GodotCheck` entry in `run-headless-tests.ps1`. If the check uses a new assertion prefix, add that prefix to the runner's failure scan. Keep external profile/config behavior inside the runner's isolated `.tmp/` user-data tree and document the new check in `testing.md`. A helper may be invoked from an existing check when its assertions share the same lifecycle; `menu-settings-regression.gd` is intentionally nested inside `settings-audio` and does not create a thirteenth runner entry.

## Verification Boundaries

The exact twelve checks are `editor-import`, `menu`, `gameplay`, `game-state`, `progression`, `checkpoint-layout`, `physical-route`, `player-input`, `visual-effects`, `settings-audio`, `settings-persistence-write`, and `settings-persistence-read`.

Together they verify import, canonical `project.godot` serialization, and scene construction; state snapshots, post-restore collection isolation, and guarded progression; radio cooldown across close/reopen; pacing eligibility, pause accounting, actual boundary order, deep-copy isolation, visible-credits finalization, incomplete/null semantics, reset immutability, and out-of-order rejection; layout, navigation, restored hallway, elevator/arrival scare invariants, chase APPEAR pause, measured STALK/CHASE speed, LOS/last-seen/reacquisition, bounded search/DESPAWN, restart/exit behavior, retreat and capture recovery, entity-parented SFX cue start/recovery/teardown, terminal failure/ending overlap, ray-reachable two-step epilogue gates, pre-credits movement, and exactly-once credits locking; synthesized production-player movement through three doors; physical E binding and production ray acquisition; phone interaction, objective review, pause/flashlight locks, bounded pause-safe flicker, note Escape, door spam, 1.5 m sweep rejection, reason-scoped movement-only lock/release, and close/reopen; optional drawer/painted-door visibility alignment, ray acquisition, cooldown, mapped feedback, drawer motion safety, unchanged story state, and spatial-tone/lock teardown; shader uniforms, stage-driven fear intensity, and the film-grain visibility toggle; settings controls/clamps, modal focus traversal/launcher return, visible save-failure handling, first-run bus defaults, parameter-complete audio variants/LRU/live-player protection/spatial teardown, and in-memory Continue visibility; all 76 manifest-backed English voice resources and sequencing/fallback contracts; and settings persistence across two Godot processes.

The movement checks teleport between focused gates and the input check positions the player at selected production targets. The telemetry checks extend progression and checkpoint/layout; they do not add a thirteenth runner check. The suite does not generate a complete physical F5 keyboard/mouse playthrough or verify a same-run physical capture, monitor output, rendered effect quality, audible output or mix balance, live chase navigation/fairness, the physical Settings UI workflow, or 15–20 minute pacing. These require the manual matrix in `testing.md`.

## References

- [`gameplay.tscn`](../scenes/gameplay/gameplay.tscn)
- [`gameplay-director.gd`](../scripts/world/gameplay-director.gd)
- [`story-progression-controller.gd`](../scripts/world/story-progression-controller.gd)
- [`chase-sequence-controller.gd`](../scripts/world/chase-sequence-controller.gd)
- [`ending-epilogue-controller.gd`](../scripts/world/ending-epilogue-controller.gd)
- [`chase-entity.gd`](../scripts/world/chase-entity.gd)
- [`playthrough-pacing-telemetry.gd`](../scripts/world/playthrough-pacing-telemetry.gd)
- [`continuous-world-builder.gd`](../scripts/world/continuous-world-builder.gd)
- [`continuous-story-layout.gd`](../scripts/world/continuous-story-layout.gd)
- [`hallway-transition-layer.gd`](../scripts/ui/hallway-transition-layer.gd)
- [`door-interactable.gd`](../scripts/interaction/door-interactable.gd)
- [`drawer-interactable.gd`](../scripts/interaction/drawer-interactable.gd)
- [`atmospheric-door-interactable.gd`](../scripts/interaction/atmospheric-door-interactable.gd)
- [`player-controller.gd`](../scripts/player/player-controller.gd)
- [`visual-effects-layer.gd`](../scripts/ui/visual-effects-layer.gd)
- [`retro-screen-overlay.gdshader`](../shaders/retro-screen-overlay.gdshader)
- [`player-flashlight.gd`](../scripts/player/player-flashlight.gd)
- [`game-state.gd`](../scripts/autoload/game-state.gd)
- [`audio-manager.gd`](../scripts/autoload/audio-manager.gd)
- [`settings-manager.gd`](../scripts/autoload/settings-manager.gd)
- [`settings-panel.gd`](../scripts/ui/settings-panel.gd)
- [`pause-menu.gd`](../scripts/ui/pause-menu.gd)
- [`boot-menu.gd`](../scripts/ui/boot-menu.gd)
- [`player-input-integration-test.gd`](../tests/player-input-integration-test.gd)
- [`environmental-interaction-route-verifier.gd`](../tests/environmental-interaction-route-verifier.gd)
- [`visual-effects-test.gd`](../tests/visual-effects-test.gd)
- [`menu-settings-regression.gd`](../tests/menu-settings-regression.gd)
- [Testing matrix](testing.md)
