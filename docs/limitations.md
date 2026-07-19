# Known Limitations

## Distribution

- The project is source-playable with Godot 4.7.1 standard and targets the Compatibility renderer.
- A credential-free `export_presets.cfg` is tracked for an unsigned Windows Desktop x86_64 release executable with an embedded PCK. Its `0.9.0.0` file/product version is unreleased release-candidate metadata, not a Git tag, GitHub release, or shipped-version claim. Exported binaries, logs, installed templates, and the Godot editor remain outside Git.
- `tests/verify-windows-export.ps1` validates the selected preset, exact official Godot 4.7.1 archive/template hashes, fresh staged export logs, PE x86_64 architecture, and a direct headless startup smoke; it also copies `LICENSE`, `THIRD_PARTY_NOTICES.md`, and `GODOT_COPYRIGHT.txt` beside the ignored output. Its lock, unique staging, path preflight, rollback, and configured-root checks protect the maintainer-run workflow from ordinary stale/partial state; they are not a hostile same-host guarantee against a concurrent reparse swap after preflight. This does not prove a rendered menu, physical input, audible output, display behavior, signing, or installer/store packaging.
- F5 follows the configured boot-to-gameplay flow. F6 runs the editor's current scene and can bypass the boot menu.
- Docker packaging (`Dockerfile`, `docker-compose.yml`, `tests/run-headless-tests.sh`) is a **CI/test surface** that fetches Godot 4.7.1 into an image (`nguyenson1710/horror-game-suite`). A passing `main` push auto-publishes only when both Hub secrets are configured; the workflow has no separate publish approval, and no registry digest means publication is unverified. The image does not ship a player-facing game build or close PDR-07.
- Public-repo hygiene files (`SECURITY.md`, `CONTRIBUTING.md`, Dependabot, packaging CI) document process only; they are not a release certification.
- An automated Windows export is in scope; signed installers, commercial platform packaging, and platform-specific compliance remain out of scope. The verifier stages the project's current notices, but a distributor must still review all requirements for the exact engine build and destination.

## Current Verification Snapshot — 2026-07-19

The current source-completable evidence is green: the Windows Godot runner exited 0 with
all twelve checks passing, the focused physical-evidence regression passed, and the
Windows export/adversarial checks preserved the verified bundle identities. PowerShell
and Bash packaging contracts passed; Docker compose config, local image build, and the
Linux-container suite also passed 12/12. Docker Hub publication was not attempted and is
**not** implied by the local image result.

| Artifact | Role | Stable recorded identity |
|---|---|---|
| `ROOM_407_THE_LAST_SHIFT.exe` (`117920376` bytes) | reproducible active payload | SHA-256 `74ef9d12288a4f687f9d5a7de29cfc684737d2af98da97c90e80e77024099190` |
| Official export-template archive | local export input | SHA-256 `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72` |
| Installed `windows_release_x86_64.exe` template | local export input | SHA-256 `76269a403bb832599edeee4432a5b7a7e88c018eb5c9c798dfd8289359b0ec07` |

Active/rollback transaction identities are deliberately per-run because their manifests
bind a fresh `RUN_ID`. Read the current ignored manifests and dated
[operator handoff](../plans/260718-1319-final-horror-release-candidate/reports/phase-05-operator-handoff-2026-07-18.md); do not promote those rotating values into evergreen docs.

The docs-only cover contract is `1280×640`, SHA-256
`58d5893ef611bfa8b5657c40483073c0ba67c086c0fd2577d4538502d2283980`. See the dated
[final source-closure verification and review](../plans/260719-0746-repository-evidence-closure/reports/pm-260719-1501-source-closure.md)
for command-level evidence.

These checks do not close PDR-07 or parent Phase 5. A human physical production-window
run (`ProjectRun` preferred, `EditorF5` optional) must still cover `START SHIFT` to
credits, preserve its same-run pacing payload and capture, and complete the
perception/input matrix. The hostile same-profile
reparse/TOCTOU race after path preflight remains a documented limitation; the evidence
runner is not a hostile-filesystem proof.

## Persistence

- Gameplay checkpoints exist only in the `GameState` autoload for the current process.
- The boot Continue button appears only when that in-memory checkpoint dictionary is populated.
- Restarting the application removes checkpoint progress and starts a fresh shift.
- Settings changes apply immediately. A successful **SAVE & CLOSE** writes `user://room407.cfg`; `save_settings()` returns an error and emits a failure signal when the write fails, so the modal stays open with **RETRY SAVE** or **CLOSE WITHOUT SAVING**. Isolated writer/reader processes verify file creation and all 11 values across relaunch; physical panel interaction and the real player profile remain manual boundaries.

## Automated Test Boundaries

- The runner has twelve headless checks: editor import plus canonical `project.godot` serialization, boot load, gameplay load, game state, progression, checkpoint/layout, targeted physical-route movement, player-input integration, visual-effects contracts, settings/audio, persistence write, and persistence read.
- Both canonical headless runners intentionally ignore known ObjectDB warning noise at process exit while failing on non-zero exits, missing markers, and engine/script/parse/assert scanners. A dated zero-line ObjectDB scan is an additional closure audit, not their failure policy.
- Every runner invocation uses a unique Godot user-data profile under `.tmp/`; the writer and reader share it, then guaranteed teardown removes it. Automated settings changes do not touch the normal game profile.
- Progression automation calls gameplay and radio widget methods directly. It covers radio Escape/unlock, non-digit filtering, cooldown persistence, the three-failure hint, final-note gating, and an entity-proximity capture recovery after injected positioning. It does not type, click, close the final note through physical input, or run a player-driven chase.
- Progression automation also compresses and directly exercises the authored floor-arrival, photograph, cassette, rabbit, and Room 407 scare lifecycle. It verifies one-shot guards, repeated-trigger rejection, pause-safe waits, non-colliding actors, spatial-cue ownership, local-light restoration, cassette removal at `memory_cassette_recalled`, and scene-exit cleanup. It does not certify rendered scare timing/quality, surprise, tension, audible output, spatial perception, or mix balance.
- Production pacing telemetry observes progression stages and visible credits. Progression automation verifies pause exclusion, actual ordered milestones, complete chapter reporting, finalization/deep-copy behavior, and that its compressed run is outside the 15–20 minute target. Checkpoint/layout automation verifies resumed sessions are incomplete and ineligible with a `null` verdict, remain immutable after reset, and reject out-of-order data. These checks validate instrumentation semantics only; they do not validate real input, blind-player behavior, or human pacing.
- The physical-route smoke synthesizes mapped forward movement through `Input.action_press()`, then reaches the production player's `Input.get_vector()` and physics path. Its optional-interaction helper forces the production ray and passes constructed mapped interaction actions directly to the handler. It proves structural drawer/false-door visibility alignment, ray acquisition, feedback/cooldowns, drawer sweep/animation locking, unchanged story state, spatial-tone/lock teardown, three locked/open door passages, and selected thresholds. It still teleports, sets flags, and calls guarded route doors directly; it does not prove operating-system W/E delivery, rendered optional-prop quality, audible tone balance, the complete route, puzzles, chase feel, or pacing.
- The player-input integration check confirms separate physical-only and logical-only bindings for WASD/Shift/E/F/Escape/Tab, then passes constructed `InputEventAction` objects directly to production handlers. It covers the phone interaction ray, objective review, pause/flashlight locks, note Escape/unlock, door spam, open/close rejection within the 1.5 m sweep without state mutation, safe close/reopen, reason-scoped movement-only lock/release, and authored head-position restoration. It does not inject operating-system keyboard/mouse events or prove input latency, camera feel, or whether the sweep clearance feels natural during a full traversal.
- Layout tests use node, polygon, numeric, collision-ray, and audio-player ownership assertions. They prove that chase start and checkpoint recovery each own one bounded entity-parented SFX cue and that failure/ending teardown removes stale playback/cache ownership; they do not drive the player capsule through the complete route, prove live pathfinding quality, or establish that the cue is audible and balanced.
- The visual-effects check verifies the overlay shader/material, dither/VHS/fear uniforms, chase/ending fear targets, and the film-grain visibility toggle. It does not inspect rendered pixels, readability, comfort, monitor gamma, or GPU performance.
- The settings/audio test verifies buses, selected clamps, controls, pause/boot modal focus and launcher return, visible save-failure retry/discard behavior, parameter-complete loop-aware audio cache variants, LRU/live-stream protection, exact byte accounting, spatial player lifetime/teardown, in-memory Continue, all 76 English voice resources, exact cue/subtitle fallback, voice-duration holds including the six-line epilogue, queue ordering/duplicates, pause/resume, and teardown. Separate persistence checks save and restore all 11 values across two processes and check the returned save error. Nested voice and menu helpers do not add runner checks. No headless check verifies audible performance, intelligibility, mix quality, physical panel interaction, or target-device fullscreen behavior.
- The player-input check verifies bounded flashlight energy, reset when disabled/hidden, and `PROCESS_MODE_PAUSABLE` pause freeze. It does not prove rendered flicker comfort, monitor gamma, or physical pause timing.
- The Windows export verifier is separate from the twelve Godot checks. Its headless process smoke proves that the generated executable starts and exits without scanned engine/script/parse/crash markers; it does not inspect rendered pixels, hear audio, operate the menu, or certify target-hardware performance.
- Headless rendering cannot establish darkness readability, flicker/grain comfort, color balance, ending presentation quality, monitor gamma, audible mix, or frame pacing on target hardware.

## Manual Evidence Still Required

Runtime pacing telemetry is implemented, but no reviewed human physical production-window run (`ProjectRun` preferred, `EditorF5` optional) currently proves the pacing target. Required evidence is a fresh blind keyboard-and-mouse boot-to-credits recording plus its same-run eligible, complete, order-valid `PLAYTHROUGH_PACING: ` payload; compressed automation and checkpoint-start reports are not substitutes.

`tests/run-physical-playthrough.ps1` can preserve raw stdout/stderr plus combined console and engine logs, snapshot and atomically quarantine a pre-launch `user://playthrough_pacing_last.txt` without deleting a replaceable path, cap candidates at 1 MiB, require a strictly post-launch changed regular side-channel with exactly one hash-verified payload, verify source/destination identity and hashes, and bind the result to one unchanged clean branch/commit. Its Job Object kills the process tree on timeout or combined-output overflow. It rejects linked/escaped evidence paths, source swaps, malformed or coercible JSON fields, missing target/chapter maps, inconsistent chapter verdicts, mixed runs, stale data, and out-of-target payloads. These checks fail closed for the covered accidental and deterministic race cases but are not proof against a hostile process that already controls the same user profile. The runner cannot inspect the recording, distinguish a real key press from an inaccurate declaration, or judge presentation quality. Its generated checklist and summary are an evidence package for human review, not automatic proof of the physical gate.

The following are targets or implemented features, not manually verified release claims:

- 15-20 minute blind-run pacing and per-chapter pacing;
- complete production-window boot-to-credits traversal using real input;
- collision plus door and drawer-sweep clearance feel across the entire corridor;
- live `NavigationAgent3D` behavior and chase fairness under player control;
- corridor-light failure and red-guide-light readability during the chase;
- visual balance for flashlight, fog, blackout, flicker, grain, optional props, and ending reveal;
- audible narration/character voice, phone, ambience, radio, footsteps, optional interaction tones, chase, fail, and ending balance;
- rendered timing/quality and audible spatial balance for the fixed story-aligned scare sequences;
- mouse capture, pause/settings behavior, fullscreen, and comfort toggles;
- physical Settings-panel save/close behavior and target-device fullscreen transition.

Use the manual matrix in `testing.md` and attach dated evidence before describing any of these as verified.

## Content and Presentation Scope

- Geometry, materials, labels, shader effects, and sound effects are intentionally procedural and asset-light. Committed media exceptions are the generated English story voice set and four project-authored generated still textures used by the boot menu and selected story props. Shader effects currently include grain, scanlines, ordered dithering, VHS tracking/jitter, and a chase-responsive fear vignette/tint.
- The repository commits four reviewed 960×540 staged in-engine stills and one 640×360 derived visual-reference GIF under `docs/screenshots/`. The reproducible capture harness uses production gameplay/ending scenes but freezes gameplay and player simulation, disables voice, teleports the player, directly selects presentation states, and creates credits manually. These files demonstrate selected rendered views only; they are not a gameplay recording or production-window evidence of traversal, pacing, progression, chase fairness, audio, Settings/fullscreen behavior, pixel determinism, or cross-hardware consistency.
- Eight source PNGs, the 1280×720 12 fps source AVI, and capture logs stay machine-local under ignored `.artifacts/`; only reviewed, optimized documentation media belongs under `docs/screenshots/`.
- Generated English narration/character delivery is implemented for every sequenced story line; human-performed acting, external hero props, crouch, and a secondary ending remain out of scope. Voice quality and mix still require a physical listening pass.
- The radio, subtitles, and credits use runtime UI/default theme behavior rather than committed font assets.
- The current story and credits are English-only.

## Licensing

- The repository MIT license covers project code and project-authored assets.
- It does not relicense Godot Engine or the engine's third-party components.
- Every exported binary must retain the notices required by the Godot Engine distribution it includes. The verifier copies `LICENSE`, `THIRD_PARTY_NOTICES.md`, and the full tag-pinned `GODOT_COPYRIGHT.txt` inventory beside its local output; those staged files do not replace destination-specific legal review.

## References

- [Testing matrix](testing.md)
- [Deployment guide](deployment-guide.md)
- [Architecture](architecture.md)
- [Asset credits and provenance](asset-credits.md)
- [`run-headless-tests.ps1`](../tests/run-headless-tests.ps1)
- [`run-physical-playthrough.ps1`](../tests/run-physical-playthrough.ps1)
- [`verify-windows-export.ps1`](../tests/verify-windows-export.ps1)
- [`export_presets.cfg`](../export_presets.cfg)
- [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md)
- [`GODOT_COPYRIGHT.txt`](../GODOT_COPYRIGHT.txt)
- [`settings-manager.gd`](../scripts/autoload/settings-manager.gd)
- [`game-state.gd`](../scripts/autoload/game-state.gd)
- [`playthrough-pacing-telemetry.gd`](../scripts/world/playthrough-pacing-telemetry.gd)
- [`visual-capture-tour.gd`](../tests/visual-capture-tour.gd)
- [Staged capture testing boundary](testing.md#reproducible-visual-capture-tour)
- [Godot Engine license](https://godotengine.org/license/)
