# Changelog

All notable changes to this project are documented here.

## [Unreleased]

### Changed

#### Professional Docker Hub + repository docs polish — 2026-07-19

- Dockerfile now verifies the official Godot 4.7.1 Linux zip with pinned SHA-256 `c7ff14fd28472c8d4f193043de30278dcf7e5241a1dcf7566b02e27addaa33ba` before install.
- `.gitignore` / `.dockerignore` exclude dotenv and common key material; secret-pattern scan covers workflows and markdown; CI workflows set `permissions: contents: read`.
- Docker Hub publish step documents required secrets, enforces username `nguyenson1710`, and tags `latest` + full `GITHUB_SHA`.
- README gallery presents cover, staged stills, and GIF with explicit evidence boundaries; historical 2026-07-18 export hashes are demoted in testing/roadmap handoff language.
- Phase 5 physical steps prefer `ProjectRun` over EditorF5 for same-run log integrity.
- Physical-evidence regression pins a strictly post-launch write timestamp so the fresh-harvest case is non-flaky under coarse wall-clock resolution.

#### Repository evidence closure snapshot — 2026-07-19

- Fresh Windows host verification passed all 12 canonical Godot checks (exit 0); the focused physical-evidence regression and Windows export adversarial harness also passed.
- PowerShell and Bash Docker packaging contracts passed. Live image build/run and Docker Hub publication remain environment- and secrets-dependent.
- The active Windows executable is `117920024` bytes with SHA-256 `420c085640d54e49765362e830b5f6a4ee8b70d18dc1303079485e59e034c771`; active bundle `2111b6f55d318ec257bc6baa4a43117f5ee4d27ccc7c48452a57e6bfc7dcec4d`; rollback bundle `3c4890f2b1d6f99329727d0bd008a043d60a462d807e1c811e337b965f2e7701`.
- The documentation-only cover contract is `1280×640`, SHA-256 `58d5893ef611bfa8b5657c40483073c0ba67c086c0fd2577d4538502d2283980`.
- [Tester re-verify](plans/260719-0746-repository-evidence-closure/reports/tester-review-fix-cycle-1-2026-07-19.md) and [cycle-2 review](plans/260719-0746-repository-evidence-closure/reports/code-review-cycle-2-2026-07-19.md) are current references; PDR-07/parent Phase 5 remains open for human physical F5 and perception review.

#### Story jumpscare staging polish — 2026-07-18

- Apparitions use elongated humanoid silhouettes (shoulders/arms), face the player on reveal, and Room 407 flashes emission eyes.
- Scare sequences jolt camera shake (comfort-gated) and pulse monitor-safe fear vignette without random spam.
- Cassette turn-away silhouette matches factory language; look-back snap faces the player with layered cues.

### Fixed

#### Physical playthrough evidence capture — 2026-07-18

- Credits now overwrite one last-run `user://playthrough_pacing_last.txt` line with the same `PLAYTHROUGH_PACING:` payload so Editor F5 (separate game process) no longer drops evidence when the host `--log-file` only covers the editor.
- `tests/run-physical-playthrough.ps1` defaults to `ProjectRun` (game-bound log), archives and clears any stale side-channel before launch, requires a strictly post-launch write, snapshots through one open stream, rejects source identity changes and reparse paths, verifies copied size/hash, and warns when `EditorF5` is used.
- Added `tests/physical-playthrough-evidence-regression.ps1` for isolated stale/fresh/boundary/hash/source-swap/junction coverage without manufacturing release evidence.
- Progression suite asserts the side-channel matches the finalized pacing report.

### Added

#### Public-repo professionalism — 2026-07-18

- `SECURITY.md`, `CONTRIBUTING.md`, and root `.editorconfig` for disclosure, contributor setup, and editor defaults.
- `.github/dependabot.yml` for weekly GitHub Actions and Docker base-image updates.
- `.github/workflows/ci.yml` for packaging-contract verification, professional-doc presence checks, and a lightweight committed-tree secret-pattern scan (does not replace the twelve Godot checks).
- `.github/CODEOWNERS` defaulting to `@JasonTM17`.
- Added a reviewed 1280x640 repository cover under `docs/media/`, placed it at the top of the README, excluded documentation media from Godot import, and recorded the final image prompt, hash, license scope, and evidence boundary.

#### Docker / CI test packaging — 2026-07-18

- Multi-stage non-root `Dockerfile` and compose service image `nguyenson1710/horror-game-suite` (Godot 4.7.1 standard, not .NET).
- POSIX `tests/run-headless-tests.sh` mirroring the twelve host checks; large frame budgets for uncapped Linux headless.
- `tests/verify-docker-packaging.ps1` / `.sh` structural contracts; CI `docker-suite.yml` build + suite + optional Hub publish when secrets exist.
- Container suite proven green on GitHub Actions (including `physical-route` and `ALL_TWELVE_HEADLESS_CHECKS_OK`).

#### Windows x86_64 export verification — 2026-07-18

- Credential-free `export_presets.cfg` for an unsigned Windows Desktop x86_64 release executable with an embedded PCK and repository-local ignored output.
- `tests/verify-windows-export.ps1` binds checks to the selected preset; verifies the official Godot archive and installed release-template hashes; enforces unsigned, credential-free, remote-deploy-disabled settings; uses exclusive locking plus unique staging; and validates export/startup logs, PE x86_64 architecture, and current output size/SHA-256.
- `tests/windows-export-adversarial.ps1` covers Job Object descendant teardown, canonical manifest/hash tampering, rollback recovery, preset parser mutations, configured output-root containment, timeout preservation, and lock rejection without changing the verified active/rollback bundles. It does not claim protection from a hostile same-host reparse swap after path preflight.
- Verified export bundles `LICENSE`, `THIRD_PARTY_NOTICES.md`, and the tag-pinned `GODOT_COPYRIGHT.txt` inventory beside the executable. Generated binaries, logs, templates, staging trees, and isolated profiles remain outside Git.

- Godot 4.7.1 Compatibility-renderer project foundation, boot scene, input map, and project icon.
- One continuous lobby-to-ending gameplay scene with guarded phone, logbook, fuse, memory, radio, Room 407, chase, and ending progression.
- `GameplayDirector` facade with dedicated `StoryProgressionController` and `ChaseSequenceController` collaborators.
- Full-screen blackout transitions that hide memory-hallway reconfiguration without changing gameplay scenes.
- Procedural corridor geometry, a `NavigationRegion3D`, enemy `STALK` and chase states, chase-time corridor-light failure, checkpoint recovery, abandoned-lobby reveal, and credits.
- Scene-local, pause-aware playthrough telemetry that snapshots fresh-Lobby eligibility, records first-occurrence stage order, finalizes at visible credits, and prints one `PLAYTHROUGH_PACING: ` JSON line.
- Boot-menu Continue for process-local checkpoints and pause-menu access to Settings.
- Persisted settings at `user://room407.cfg` for controls, display, audio, and comfort options.
- Twelve-check Windows headless runner with per-check logs under `.artifacts/`, including targeted production-player movement/door collision and isolated two-process settings persistence.
- Physical-playthrough evidence runner that preserves same-session logs, validates one unique 15–20 minute payload, records disk/commit/capture metadata, and keeps analysis-only or mixed-run evidence ineligible for release closure.
- Two-step in-world ending investigation with a condemnation notice, night roster, six manifest-backed voice cues, and credits gated behind completed narration.

### Changed

#### Release-candidate horror polish — 2026-07-18

- Added four authored PNGs—a dark hotel-corridor menu composition, memory photograph, child's drawing, and family-table memory—with runtime import and regression coverage.
- Hardened the floor/rabbit/Room 407 scare anchors for checkpoint restoration, shared the emissive-eye readability threshold, and expanded the progression contract to cover textured clue meshes and both Room 407 eyes.
- Strengthened the input residual contract to require separate physical-only and logical-only bindings for WASD/Shift/E/F/Escape/Tab; OS-delivered key and mouse behavior remains a manual boundary.
- Kept the Voice bus ducking and bounded procedural-audio lifecycle unchanged while documenting that audible balance still needs a target-device listening pass.
- Merged the Dependabot `actions/checkout@v7` update across both CI workflows; the host and container twelve-check suites passed after the branch integration.

#### Completion audit polish — 2026-07-16

- `4287337` reconciled the completion-audit plan and evidence workflow without changing the continuous route.
- `4099a52` added the fourth-floor elevator/door/apparition beat, Room 407 dressing, and the bounded pre-chase manifestation.
- `4be615a` made generated-tone cache identity parameter-complete, loop-aware, LRU-bounded, and safe around live spatial players.
- `f1bc63c` made flashlight flicker a bounded timed pulse that resets cleanly and stops advancing while paused.
- `c38fde9` made boot/pause Settings focus-modal, restored launcher focus, and exposed failed config writes with retry/discard actions.
- Expanded the existing twelve-check suite without adding a thirteenth runner entry, covering progression transactions, rendered scare cleanup, bounded chase search, audio cache/lifetime contracts, pause-safe flicker, and Settings focus/save-failure recovery.
- Replaced the passive three-second ending delay with two ray-reachable gameplay-root interactions while preserving the chase controller as the exactly-once visible-credits pacing boundary.
- Expanded the English story voice set from 70 to 76 reviewed mono 22.05 kHz OGG cues; the six ending lines provide 30.596 seconds of decoded narration.

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

- `ba59df0` changed the physical runner from an automatic “manual gate” claim to a review-required evidence package and rejects engine/script/parse/ObjectDB-leak failures before it can report readiness.
- `05ade4b` binds physical evidence to one clean, unchanged branch/commit and generates the human-review checklist required before release closure.
- `1321971` enforced atomic quest-item consumption, permanent run-local fourth-floor unlock, and the pre-Room `room_entrance` checkpoint invariant.
- `e4b8386` aligned the chase entity body with the floor and bounded lost-target search through deterministic `DESPAWN`/restart behavior.
- Made restored checkpoint inventory, flags, and completed-event collections independent copies so later story state cannot mutate the saved snapshot by aliasing.

- Restored the memory-derived hallway variant when Continue rebuilds a Room 407 or chase checkpoint.
- Preserved radio cooldown across close/reopen attempts and prevented stale feedback timers from clearing a new attempt.
- Added an in-world interactive investigation before the ending credits cover the abandoned-lobby reveal.
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
- The repository now tracks a Windows x86_64 export preset and has automated export/headless-startup evidence, but no executable, signed installer, or store package is committed; rendered target-hardware startup still requires human review.

## References

- [Testing matrix](docs/testing.md)
- [Architecture](docs/architecture.md)
- [Known limitations](docs/limitations.md)
