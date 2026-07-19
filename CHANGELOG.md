# Changelog

All notable changes to this project are documented here.

## [Unreleased]

### Changed

#### Professional Docker Hub + repository docs polish — 2026-07-19

- Dockerfile now verifies the official Godot 4.7.1 Linux zip with pinned SHA-256 `c7ff14fd28472c8d4f193043de30278dcf7e5241a1dcf7566b02e27addaa33ba` before install.
- `.gitignore` / `.dockerignore` exclude dotenv and common key material; secret-pattern scan covers workflows and markdown; CI workflows set `permissions: contents: read`.
- Docker Hub publish documents required secrets, enforces username `nguyenson1710`, and tags `latest` + full `GITHUB_SHA`. After the suite passes, a `main` push with both secrets publishes automatically; no separate workflow approval exists. The user authorized the Git push for this 2026-07-19 landing, but publication still requires a resulting registry digest before it is claimed.
- README gallery presents cover, staged stills, and GIF with explicit evidence boundaries; historical 2026-07-18 export hashes are demoted in testing/roadmap handoff language.
- Phase 5 uses the standard handoff boundary: human physical production-window run; `ProjectRun` preferred, `EditorF5` optional.
- Physical-evidence regression pins a strictly post-launch write timestamp so the fresh-harvest case is non-flaky under coarse wall-clock resolution.
- Physical evidence now uses strict JSON types and exact chapter/target maps, recomputes pacing verdicts, requires exactly one payload in every hash-verified side-channel, caps side-channels at 1 MiB, contains output below `.artifacts`, and atomically quarantines stale sources without deleting a concurrently replaced path.
- Physical launch now uses a bounded Windows Job Object: timeout defaults to 7200 seconds (60–14400), combined output defaults to 16 MiB (1–64 MiB), timeout/overflow kills the descendant tree, and the Godot `--version` preflight uses the same boundary with a fixed 30-second/65536-byte budget. Evidence retains raw version/main stdout/stderr plus the combined console log. The focused regression adds process-boundary, pacing-schema, destination-containment, and side-channel completion markers.
- Export timeout/lock adversarial coverage self-seeds verified active/rollback bundles only inside unique disposable namespaces, so it runs on a fresh checkout without touching canonical bundles.
- Packaging verifiers structurally enforce the exact case-sensitive twelve active checks. `python tests/verify-repository-docs.py` reads stage-0 regular blobs by Git-index object ID, rejects worktree/index and symlink-mode drift plus every unapproved public-media extension, validates media hashes/PNG-GIF structure and malformed-cover negatives, and checks indexed local Markdown links including explicit/collapsed references. It emits `REPOSITORY_MEDIA_OK`, `MARKDOWN_LOCAL_LINKS_OK`, `MARKDOWN_INDEXED_LOCAL_LINKS_OK`, and `PRO_DOCS_OK`.
- Added `docs/deployment-guide.md` as the canonical source-launch, QA, docs-verification, Windows-export, CI/Hub, physical-handoff, rollback, and troubleshooting path.

#### Repository evidence closure snapshot — 2026-07-19

- The hardening slice landed on `main` as `ad514cba881270d43fa532d324224618dd48d364` followed by report-containing closure commit `c28beeed7a4bafd871e09225152f329beac09e9a`; real-index media/link validation, remote parity, `ci`, and `docker-suite` passed. The Hub step skipped because Actions secrets are absent, so no registry tag or digest is claimed.
- Fresh Windows host verification passed all 12 canonical Godot checks (exit 0); the focused physical-evidence regression and Windows export adversarial harness also passed.
- PowerShell/Bash packaging contracts and a local Docker compose image build plus 12/12 container run passed. Docker Hub publication was not performed; the absence of a digest remains the authoritative unverified boundary.
- A fresh Windows export reproduced the executable at `117920024` bytes with SHA-256 `420c085640d54e49765362e830b5f6a4ee8b70d18dc1303079485e59e034c771`.
- V1 bundle IDs are intentionally per-run because their manifests bind a fresh `RUN_ID`; current active/rollback IDs live in the ignored `VERIFY_COMPLETE.txt` files and prior IDs are dated evidence, not durable release constants.
- The documentation-only cover contract is `1280×640`, SHA-256 `58d5893ef611bfa8b5657c40483073c0ba67c086c0fd2577d4538502d2283980`.
- [Final source-closure verification and review](plans/260719-0746-repository-evidence-closure/reports/pm-260719-1501-source-closure.md) is the current reference; PDR-07/parent Phase 5 remains open for a human physical production-window run (`ProjectRun` preferred, `EditorF5` optional) and perception review.

#### Story jumpscare staging polish — 2026-07-18

- Apparitions use elongated humanoid silhouettes (shoulders/arms), face the player on reveal, and Room 407 flashes emission eyes.
- Scare sequences jolt camera shake (comfort-gated) and pulse monitor-safe fear vignette without random spam.
- Cassette turn-away silhouette matches factory language; look-back snap faces the player with layered cues.

### Fixed

#### Physical playthrough evidence capture — 2026-07-18

- Credits now overwrite one last-run `user://playthrough_pacing_last.txt` line with the same `PLAYTHROUGH_PACING:` payload so Editor F5 (separate game process) no longer drops evidence when the host `--log-file` only covers the editor.
- `tests/run-physical-playthrough.ps1` defaults to `ProjectRun` (game-bound log), atomically quarantines any stale side-channel before launch, requires a strictly post-launch write, snapshots through one open stream, rejects source identity changes and reparse paths, verifies copied size/hash, and warns when `EditorF5` is used.
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
- `tests/verify-docker-packaging.ps1` / `.sh` structural contracts; CI `docker-suite.yml` build + suite + automatic main-push Hub publish when secrets exist.
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

- `ba59df0` changed the physical runner from an automatic “manual gate” claim to a review-required evidence package and rejects engine/script/parse/ObjectDB-leak failures before it can report readiness. Canonical headless runners now intentionally ignore known ObjectDB warning noise; a dated zero-line ObjectDB scan is a separate closure audit, not their failure policy.
- `05ade4b` binds physical evidence to one clean, unchanged branch/commit and generates the human-review checklist required before release closure.
- `1321971` enforced atomic quest-item consumption, permanent run-local fourth-floor unlock, and the pre-Room `room_entrance` checkpoint invariant.
- `e4b8386` aligned the chase entity body with the floor and bounded lost-target search through deterministic `DESPAWN`/restart behavior.
- Made restored checkpoint inventory, flags, and completed-event collections independent copies so later story state cannot mutate the saved snapshot by aliasing.

- Restored the memory-derived hallway variant when Continue rebuilds a Room 407 or chase checkpoint.
- Preserved radio cooldown across close/reopen attempts and prevented stale feedback timers from clearing a new attempt.
- Added an in-world interactive investigation before the ending credits cover the abandoned-lobby reveal.
- Converted chase retreat beyond the authored route into checkpoint recovery instead of silently disabling the entity.
- Isolated headless test settings from the real Godot user profile; canonical runners retain error/assert scans while intentionally ignoring known ObjectDB warning noise at process exit.
- Released procedural audio players synchronously and added a short audio-server drain in the regression fixture so WAV playback objects do not leak during shutdown.
- Captured both Godot log files and console stderr in the headless runner so engine leak warnings cannot be hidden by a clean log file.
- Enforced observation and Room 407 prerequisites inside action handlers, preventing direct interaction spam from bypassing prompt-level story gates.
- Raised the finite checkpoint-layout frame cap from 600 to 1200 so its authored door and recovery timers finish before the runner evaluates the success marker.
- Added guaranteed repository-local test-profile cleanup so repeated runner invocations do not accumulate isolated Godot user data.

### Known Validation Gaps

- The telemetry contract and twelve-check suite pass, but a human physical production-window run (`ProjectRun` preferred, `EditorF5` optional) with a same-run boot-to-credits capture and JSON payload is still required before claiming the 15–20 minute pacing target.
- Full physical input traversal, capture behavior, chase/presentation quality, visual readability, audio balance and audible device output, and physical Settings behavior still require manual evidence.
- Settings persistence is verified across two isolated Godot processes; the physical Settings-panel save/relaunch workflow on target hardware remains manual evidence.
- The repository now tracks a Windows x86_64 export preset and has automated export/headless-startup evidence, but no executable, signed installer, or store package is committed; rendered target-hardware startup still requires human review.

## References

- [Testing matrix](docs/testing.md)
- [Deployment guide](docs/deployment-guide.md)
- [Architecture](docs/architecture.md)
- [Known limitations](docs/limitations.md)
