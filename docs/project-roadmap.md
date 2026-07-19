# ROOM 407: THE LAST SHIFT — Project Roadmap

## Delivery State

The delivery roadmap preserves one continuous gameplay scene. Automated packaging can finish independently while the user-controlled physical review remains open.

The parent release-candidate plan calls the same human-only gate **Phase 5** (PDR-07);
the older roadmap numbering below calls it Phase 4. They are one open gate, not two
separate delivery requirements.

| Phase | Scope | Evidence | Status |
|---|---|---|---|
| 1 | Terminal ending and capture-recovery race | `30199b7`, `5aea891`, focused progression | Complete |
| 2 | Navigation-safe right-left-right chase route | `0a1ba94`, layout/physical-route checks | Complete |
| 3 | Voiced two-step interactive epilogue and checkpoint isolation | `a4a3173`, `aaae49a`, 12-check suite | Complete |
| 4 | Physical release evidence, media capture and final handoff | Human physical production-window run (`ProjectRun` preferred, `EditorF5` optional), telemetry, reviewed media | In progress |
| 5 | Windows x86_64 export automation and redistribution notices | Tracked preset, export verifier, PE/headless-startup contracts | Complete at automated level |

## Phase 4 Worklist

- [ ] Receive a same-run physical gameplay recording and telemetry from the user or a human reviewer. Per the current instruction, automation must not control the user's desktop or substitute synthetic input for this evidence.
- [ ] Run a fresh `START SHIFT`-to-credits production-window session with physical keyboard/mouse input; use `ProjectRun` preferably (`EditorF5` is optional), then fail and recover once during the chase.
- [ ] Preserve the session's single `PLAYTHROUGH_PACING` payload and inspect chapter/total timing against the 900–1200 second target.
- [ ] Review chase clearance/fairness, red-guide readability, darkness/flicker/grain comfort, six ending voice lines, audio balance, pause/Settings, fullscreen, and relaunch behavior during the live run.
- [x] Run the reproducible staged Godot capture tour; visually review and commit four optimized PNGs plus a derived visual-reference GIF under `docs/screenshots/`. This media subtask does not satisfy the physical-run or perceptual gates.
- [x] Add repository-relative gallery links, capture instructions, evidence limits, and media provenance to project documentation.
- [ ] Complete the physical evidence package, rerun release checks, review the final diff/secrets/worktree state, and push the final evidence commit.

The current source-level route/timing audit is recorded in [`phase-04-pacing-audit-20260716.md`](../plans/260716-2113-chase-reliability-and-climax-polish/reports/phase-04-pacing-audit-20260716.md). It is planning evidence only; it does not replace the physical capture gate.

## Current verification snapshot — 2026-07-19

The repository-evidence-closure child plan is complete for all source-completable checks.
The Windows host runner exited 0 with all twelve canonical checks passing; the focused
physical-evidence regression and Windows adversarial harness also passed. Docker
packaging contracts, compose config, local image build, and the Linux-container 12/12
suite passed. Registry publication was not performed and is not claimed.

Stable recorded Windows export identities are:

| Artifact | Role | Identity |
|---|---|---|
| `ROOM_407_THE_LAST_SHIFT.exe` | reproducible active payload (`117920376` bytes) | SHA-256 `74ef9d12288a4f687f9d5a7de29cfc684737d2af98da97c90e80e77024099190` |
| Official export-template archive | local export input | SHA-256 `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72` |
| Installed `windows_release_x86_64.exe` template | local export input | SHA-256 `76269a403bb832599edeee4432a5b7a7e88c018eb5c9c798dfd8289359b0ec07` |

Per-run bundle identities rotate because their manifests bind fresh `RUN_ID` values.
Read the ignored manifests and dated operator handoff instead of copying those values into
evergreen docs.

The documentation-only cover is `1280×640` with SHA-256
`58d5893ef611bfa8b5657c40483073c0ba67c086c0fd2577d4538502d2283980`.
The current evidence index is the
[`final source-closure verification and review`](../plans/260719-0746-repository-evidence-closure/reports/pm-260719-1501-source-closure.md).
PDR-07/parent Phase 5 remains **open** until a human physical production-window run
(`ProjectRun` preferred, `EditorF5` optional) records the same-run pacing payload,
capture, and perception review.

The final source-consistency child plan also hardened boolean settings delivery,
cycle-aligned procedural drone loops, and spatial-player parent-exit cleanup. Its focused
and full host gates passed, the final review scored 10/10, and the current Windows export
identity is the `117920376`-byte / `74ef9d12…` artifact above. This closes source-level
hardening only; it does not substitute for the open human PDR-07 review.

## Completed Scare Lifecycle Slice

The focused [horror scare and spatial-audio plan](../plans/260717-2152-horror-scare-and-spatial-audio-polish/plan.md) is complete. The fixed floor-arrival, photograph, cassette turn-away, and rabbit buildup beats now lead into a separate Room 407 climax with authored anticipation, reveal, and aftermath; low/moderate procedural spatial layers; local light response where available; and non-colliding temporary actors. Shared sequence/factory ownership handles unique cue IDs, pause-safe waits, exact light restoration, actor/audio teardown, cassette cleanup at `memory_cassette_recalled`, and scene-exit cleanup without replacing voice-over.

Focused `progression` and `settings-audio` passed. Host and container twelve-check suites remain the automated source of truth. This closes only that focused source slice; it does not change Phase 4 or PDR-07.

## Completed packaging and public-repo hygiene (source-level)

- Docker multi-stage suite image and compose service; POSIX twelve-check runner; packaging verify scripts; `docker-suite` CI (including Linux `physical-route` frame-budget fix).
- Godot 4.7.1 Linux zip download is SHA-256-pinned in the Dockerfile; Hub image namespace is `nguyenson1710/horror-game-suite` with `latest` + git-SHA tags. A passing `main` push auto-publishes when both secrets are configured; there is no separate workflow approval, and no digest means publication is unverified.
- `SECURITY.md`, `CONTRIBUTING.md`, `.editorconfig`, Dependabot, lightweight `ci.yml` packaging/secret-pattern jobs, and CODEOWNERS.
- Repository cover (`docs/media/room-407-cover.png`), staged stills, and visual-reference GIF under `docs/screenshots/` with provenance in `docs/asset-credits.md`.
- These items improve professional maintainability. They **do not** close Phase 4 or PDR-07.

## Completed Windows Export Track

- The Dependabot `actions/checkout@v7` branch is merged into `main`; both host and container twelve-check suites passed after that integration and again after export-path finalization.
- The repository tracks a credential-free `Windows Desktop x86_64` preset with embedded PCK, unsigned release output, project icon/metadata, and ignored build paths. Version `0.9.0.0` is unreleased release-candidate metadata, not a tag or shipped release.
- `tests/verify-windows-export.ps1` verifies the official Godot 4.7.1 archive/member/installed-template hashes, selected-preset security contracts, fresh staged export logs, PE x86_64 architecture, and direct headless startup; it publishes under an exclusive lock and stages `LICENSE`, `THIRD_PARTY_NOTICES.md`, and `GODOT_COPYRIGHT.txt` beside the ignored build.
- The official archive, installed template, and reproducible executable hashes are retained in the snapshot table above. Templates and generated executables are not committed; later handoffs must record their own verifier output.
- This completes the automated export path only. A rendered normal-window launch, physical menu/input check, audible-output review, signing, and installer/store packaging remain outside this evidence.

## Guardrails

- Do not add loading screens or split the route into levels to manufacture duration.
- Do not treat compressed headless timing, checkpoint-start sessions, screenshots of editor views, concept art, or AI-generated images as physical gameplay evidence.
- Do not treat a successful headless exported-executable startup as a rendered menu, input, audio, pacing, or perceptual pass.
- Do not treat scare lifecycle assertions as audible-mix, spatial-perception, rendered timing/quality, or physical-input evidence.
- Keep media files small and readable; preserve the original capture outside Git.
- Monitor C:/D: before and after recording, voice processing or media encoding.
- Commit small focused clusters and verify `HEAD == origin/main` after every push.

## Release Exit

The parent goal can close only after Phase 4 has real same-run physical evidence, human review notes, retained reviewed documentation media, clean tests, clean secrets scan, clean worktree and exact remote parity. The completed staged-media subtask does not close Phase 4.

## References

- [Project overview and PDR](./project-overview-pdr.md)
- [Testing matrix](./testing.md)
- [Deployment guide](./deployment-guide.md)
- [Staged visual-capture tour](./testing.md#reproducible-visual-capture-tour)
- [Phase 4 plan](../plans/260716-2113-chase-reliability-and-climax-polish/phase-04-qa-review-and-delivery.md)
- [Final source-closure verification and review](../plans/260719-0746-repository-evidence-closure/reports/pm-260719-1501-source-closure.md)
- [Dated physical operator handoff](../plans/260718-1319-final-horror-release-candidate/reports/phase-05-operator-handoff-2026-07-18.md)
