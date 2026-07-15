# Code Standards

## Goals

Prefer YAGNI, KISS, then DRY. Code must protect a complete short game, not become a generic horror framework.

## Files and Naming

- New files and directories use descriptive lowercase kebab-case.
- GDScript classes use PascalCase; methods, variables, and signals use snake_case.
- Stable IDs and input actions use lowercase snake_case strings defined once.
- Scene and resource paths are lowercase and case-exact for Linux compatibility.
- Keep code files under 200 lines where practical. Split only at real ownership boundaries.

## Typed GDScript

- Type public methods, signals, exported values, member state, and return values.
- Avoid `Variant`/untyped dictionaries at public boundaries unless serialization requires them.
- Use enums for finite states and constants for tuning limits.
- Treat nullable node/resource references explicitly and fail with clear errors.

## Node Access

- Cache stable child references with `@onready`.
- Never call `get_node()` repeatedly in `_process()` or `_physics_process()`.
- Use exported `NodePath`/typed node references for designer-owned connections.
- Use groups only for true many-to-many discovery, not as a service locator.

## Scene Ownership

- Autoloads own cross-scene data/services only.
- Level controllers own level events, local props, and scene sequencing.
- Player scripts own movement and player input, not story event choreography.
- An interactable owns its local state transition and reports semantic results.
- Avoid cyclic references between autoloads and scene nodes.

## Signals

- Prefer typed signals for state changes and UI updates.
- Connect once during scene initialization and disconnect with node lifetime.
- Signal names describe completed facts: `objective_changed`, `item_added`, `checkpoint_restored`.
- Do not emit a signal for a mutation that failed its guard.

## Physics and Frame Work

- Movement runs in `_physics_process(delta)` and uses `move_and_slide()` correctly.
- Normalize combined movement input before applying speed.
- Apply timers, fades, and animation using delta, Timer, AnimationPlayer, or Tween.
- Disable processing for inactive hallway variants and dormant entities.
- Prefer signals/timers over polling when behavior is event-driven.

## Input and Accessibility

- Read actions from the Input Map; never hard-code keys in gameplay scripts.
- Keep sensitivity, FOV, volume, flicker, shake, and bob values within documented bounds.
- Centralize input-lock reasons so closing one UI cannot unlock another active lock.
- Restore mouse capture explicitly after pause, note, failure, and scene changes.

## Error Handling

- Use guard clauses for invalid state, missing requirements, duplicate events, and busy transitions.
- Do not swallow errors or leave debug prints in release code.
- Use `push_error()` for broken authoring contracts and player-facing feedback for valid locked states.
- Treat resource-load failure as blocking during tests.

## Interaction and Progression

- Prompt lookup is read-only.
- Pickups, puzzle solutions, event IDs, checkpoints, and capture are idempotent.
- Gates validate prerequisites before consuming items or advancing stages.
- Snapshot data contains values only—never live nodes, callables, or tweens.

## Assets

- Prefer primitive meshes, procedural materials, simple SVG, and generated audio.
- Record every committed asset in `docs/asset-credits.md`.
- Do not add unclear copyrighted media, paid plugins, or unnecessary large binaries.
- Keep import settings needed for deterministic assets; ignore generated cache directories.

## Tests and Verification

- Run the narrowest state/scene test after each coherent edit.
- Before every commit, run Godot headless import as applicable, `git diff --check`, staged secret scan, and inspect staged names.
- Automated tests cover positive and negative guards, duplicate interaction, and reset behavior.
- Manual evidence is mandatory for navigation, collision feel, lighting, audio, and 15–20 minute pacing.
- Never weaken an assertion to make a regression disappear.

## Git

- Use small Conventional Commits with imperative messages under 72 characters.
- Do not mix unrelated code, docs, tests, or refactors.
- Never commit cache, tools, logs, credentials, or local CK workspace support.
- Never force-push `main`.
