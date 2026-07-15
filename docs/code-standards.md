# Code Standards

## Overview

Prefer YAGNI, KISS, then DRY. Protect the contracts of this complete short game instead of turning it into a generic horror framework. Follow existing GDScript and Godot scene patterns before introducing a new abstraction.

## Files and Naming

- Use descriptive lowercase kebab-case for new files and directories.
- Use PascalCase for named GDScript classes.
- Use snake_case for methods, variables, signals, and input actions.
- Use stable lowercase snake_case strings for story flags, inventory IDs, event IDs, and spawn IDs.
- Keep `res://` paths lowercase and case-exact for Linux compatibility.
- Consider a split when a code file exceeds 200 lines, but split only at a real ownership boundary.

The current primary boundary is deliberate: `GameplayDirector` is the runtime facade, `StoryProgressionController` owns guarded progression and loop transitions, and `ChaseSequenceController` owns pursuit, recovery, and ending behavior.

## Typed GDScript

- Type public methods, signals, exported values, member state, and return values.
- Avoid untyped dictionaries at public boundaries unless serialization requires a value container.
- Use enums for finite states and constants for layout/tuning invariants.
- Cast scene instances and nullable node lookups explicitly.
- Keep node ownership visible; do not hide scene dependencies in generic service locators.

## Scene and Service Ownership

| Owner | Allowed responsibilities | Must not own |
|---|---|---|
| Autoload | cross-scene state, routing, audio service, persisted settings | scene nodes, local animations, story choreography |
| Gameplay facade | runtime assembly, zone observation, delegation | detailed puzzle UI or chase internals |
| Story controller | prompts, guards, flags/items, narrative completion, memory-loop swaps | player movement or enemy physics |
| Chase controller | entity lifecycle, failure recovery, chase lighting/audio, ending reveal | general story interactions |
| Player | movement, look, flashlight, input locks, comfort effects | story stage decisions |
| Interactable | local enabled/cooldown state and semantic call | unrelated global progression |

## Node Access

- Cache stable child references with `@onready`.
- Never call `get_node()` repeatedly in `_process()` or `_physics_process()`.
- Use typed references or exported `NodePath` values for designer-owned connections.
- Use groups only for true discovery such as the active player, not as a service locator.
- Construct runtime nodes once during setup; avoid per-frame allocation.

## Signals and Asynchrony

- Prefer typed signals for completed facts such as `objective_changed` and `transition_finished`.
- Connect during initialization and rely on node lifetime for disconnection.
- Do not emit success signals when a guard rejects a mutation.
- Protect tweens, timers, transitions, chase recovery, and UI cooldowns with explicit busy/idempotency flags.
- After `await`, confirm referenced nodes still exist before mutating them.

## Physics and Navigation

- Run character movement in `_physics_process(delta)` and call `move_and_slide()` once per movement step.
- Normalize combined input before applying speed.
- Use collision layers from `project.godot`; do not hard-code ad hoc layer semantics in documentation only.
- Create or configure `NavigationAgent3D` during setup, and check the map iteration before requesting path points.
- Keep fallback movement bounded by authored world limits.
- Preserve the tested chase ordering: player walk 2.0 < entity 3.0 < player sprint 3.1.

## Interaction and Progression

- Prompt lookup must remain read-only.
- Validate prerequisites before consuming inventory or advancing stage.
- Make pickups, puzzle solutions, event completion, checkpoint creation, and capture recovery idempotent.
- Store values only in checkpoint snapshots—never live nodes, resources, callables, tweens, or signals.
- Display strings are presentation, never identifiers.
- Keep the `GameState.Stage` progression monotonic.

## Input Locks and UI

- Read gameplay input through actions defined in `project.godot`.
- Use independent lock reasons (`pause`, `settings`, `note`, `radio`, `hallway`, `fail`, `ending`) so one UI cannot release another lock.
- Restore mouse capture explicitly when the final lock clears.
- Set pause-capable UI to `PROCESS_MODE_ALWAYS`.
- Keep valid locked-state feedback player-facing; reserve `push_error()` for broken authoring contracts.

## Settings Contract

All setters clamp or normalize at `SettingsManager`, not only at slider widgets.

| Setting | Default | Allowed range or values |
|---|---:|---|
| Mouse sensitivity | 0.08 | 0.01–0.25 |
| Field of view | 74 | 60–95 degrees |
| Master volume | 0 dB | −40 to +6 dB |
| Music/chase volume | −10 dB | −40 to +6 dB |
| SFX volume | −4 dB | −40 to +6 dB |
| Ambience volume | −8 dB | −40 to +6 dB |
| Flicker | on | boolean |
| Comfort head bob | on | boolean |
| Camera shake | on | boolean |
| Film grain/scanlines | on | boolean |
| Fullscreen | off | boolean |

Settings save to `user://room407.cfg` when the settings panel closes. Checkpoints are intentionally process-local and must not be added to that file without a deliberate save-system design.

## Audio and Visual Assets

- Prefer primitive meshes, project-authored shaders/SVG, and generated audio.
- Record every committed or generated asset source in `asset-credits.md`.
- Do not add media with unclear copyright or license terms.
- Keep procedural audio inputs positive and respect the 16 MiB cache cap.
- Keep Compatibility-renderer shader syntax and test the shader through editor import.
- Do not claim that the project MIT license relicenses Godot Engine or its third-party components.

## Error Handling

- Use guard clauses for missing prerequisites, duplicates, invalid inputs, and active transitions.
- Propagate scene-load failures and broken resource paths through clear errors.
- Do not swallow errors, weaken assertions, or leave debug prints in release paths.
- Treat `ResourceLoader.exists()` and scene instantiation failures as blocking when routing.
- Keep valid player mistakes, such as a wrong radio code, in the UI instead of engine errors.

## Tests and Evidence

- Run the narrowest relevant check first, then the complete ten-check runner for shared contracts.
- Automated progression tests must cover success, early rejection, duplicate rejection, and recovery where applicable.
- Keep expected success markers and assertion prefixes synchronized with `run-headless-tests.ps1`.
- Logs belong under `.artifacts/test-<name>.log`; do not commit them as source evidence.
- A headless pass is not evidence of complete physical keyboard/mouse traversal, visual/audio balance, audible output, the physical Settings UI workflow, or 15–20 minute pacing. The targeted movement smoke proves only its listed capsule/door/threshold cases, and the two-process writer/reader pair proves only config persistence.
- Record manual evidence separately; never convert an unobserved design target into a verified claim.

## Documentation and Git

- Verify every code path, class name, node path, setting, command, and test claim against current source before documenting it.
- Add references to the source or test that supports non-obvious claims.
- Normalize documentation as UTF-8 and reject mojibake.
- Keep commits focused and use Conventional Commit messages without AI attribution.
- Never commit `.godot/`, `.tmp/`, `.artifacts/`, credentials, exported binaries, or a local Godot executable.
- Never force-push `main`.

## References

- [`project.godot`](../project.godot)
- [`gameplay-director.gd`](../scripts/world/gameplay-director.gd)
- [`story-progression-controller.gd`](../scripts/world/story-progression-controller.gd)
- [`chase-sequence-controller.gd`](../scripts/world/chase-sequence-controller.gd)
- [`settings-manager.gd`](../scripts/autoload/settings-manager.gd)
- [`run-headless-tests.ps1`](../tests/run-headless-tests.ps1)
- [Architecture](architecture.md)
- [Testing matrix](testing.md)
