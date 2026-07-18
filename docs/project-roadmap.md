# Horror Game Funny - Project Roadmap

## Delivery State

The delivery roadmap preserves one continuous gameplay scene. Automated packaging can finish independently while the user-controlled physical review remains open.

| Phase | Scope | Evidence | Status |
|---|---|---|---|
| 1 | Terminal ending and capture-recovery race | `30199b7`, `5aea891`, focused progression | Complete |
| 2 | Navigation-safe right-left-right chase route | `0a1ba94`, layout/physical-route checks | Complete |
| 3 | Voiced two-step interactive epilogue and checkpoint isolation | `a4a3173`, `aaae49a`, 12-check suite | Complete |
| 4 | Physical release evidence, media capture and final handoff | Fresh F5 run, telemetry, screenshots, GIF | In progress |
| 5 | Windows x86_64 export automation and redistribution notices | Tracked preset, export verifier, PE/headless-startup contracts | Complete at automated level |

## Phase 4 Worklist

- [ ] Receive a same-run physical gameplay recording and telemetry from the user or a human reviewer. Per the current instruction, automation must not control the user's desktop or substitute synthetic input for this evidence.
- [ ] Run a fresh boot-to-credits session with physical keyboard/mouse input; fail and recover once during the chase.
- [ ] Preserve the session's single `PLAYTHROUGH_PACING` payload and inspect chapter/total timing against the 900–1200 second target.
- [ ] Review chase clearance/fairness, red-guide readability, darkness/flicker/grain comfort, six ending voice lines, audio balance, pause/Settings, fullscreen, and relaunch behavior during the live run.
- [x] Run the reproducible staged Godot capture tour; visually review and commit four optimized PNGs plus a derived visual-reference GIF under `docs/screenshots/`. This media subtask does not satisfy the physical-run or perceptual gates.
- [x] Add repository-relative gallery links, capture instructions, evidence limits, and media provenance to project documentation.
- [ ] Complete the physical evidence package, rerun release checks, review the final diff/secrets/worktree state, and push the final evidence commit.

The current source-level route/timing audit is recorded in [`phase-04-pacing-audit-20260716.md`](../plans/260716-2113-chase-reliability-and-climax-polish/reports/phase-04-pacing-audit-20260716.md). It is planning evidence only; it does not replace the physical capture gate.

## Completed Scare Lifecycle Slice

The focused [horror scare and spatial-audio plan](../plans/260717-2152-horror-scare-and-spatial-audio-polish/plan.md) is complete. The fixed floor-arrival, photograph, cassette turn-away, and rabbit buildup beats now lead into a separate Room 407 climax with authored anticipation, reveal, and aftermath; low/moderate procedural spatial layers; local light response where available; and non-colliding temporary actors. Shared sequence/factory ownership handles unique cue IDs, pause-safe waits, exact light restoration, actor/audio teardown, cassette cleanup at `memory_cassette_recalled`, and scene-exit cleanup without replacing voice-over.

Focused `progression` and `settings-audio` passed. Host and container twelve-check suites remain the automated source of truth. This closes only that focused source slice; it does not change Phase 4 or PDR-07.

## Completed packaging and public-repo hygiene (source-level)

- Docker multi-stage suite image and compose service; POSIX twelve-check runner; packaging verify scripts; `docker-suite` CI (including Linux `physical-route` frame-budget fix).
- `SECURITY.md`, `CONTRIBUTING.md`, `.editorconfig`, Dependabot, lightweight `ci.yml` packaging/secret-pattern jobs, and CODEOWNERS.
- These items improve professional maintainability. They **do not** close Phase 4 or PDR-07.

## Completed Windows Export Track

- The Dependabot `actions/checkout@v7` branch is merged into `main`, and both host and container twelve-check suites passed after that integration.
- The repository tracks a credential-free `Windows Desktop x86_64` preset with embedded PCK, unsigned release output, project icon/metadata, and ignored build paths.
- `tests/verify-windows-export.ps1` validates the official Godot 4.7.1 standard release template, preset security contracts, export logs, PE x86_64 architecture, and direct headless startup; it stages `LICENSE` and `THIRD_PARTY_NOTICES.md` beside the ignored build.
- The official 4.7.1 standard export-template archive used for this work has SHA-256 `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72` and is installed outside the repository. Templates and generated executables are not committed.
- The verified 2026-07-18 artifact at commit `4684f29` was `117914600` bytes with SHA-256 `3bc3d2e4ade3c2147cd3b6efc320802c7db51391570334c7bada65bf3f5ff2c8`; later handoffs must record their own verifier output.
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
- [Staged visual-capture tour](./testing.md#reproducible-visual-capture-tour)
- [Phase 4 plan](../plans/260716-2113-chase-reliability-and-climax-polish/phase-04-qa-review-and-delivery.md)
