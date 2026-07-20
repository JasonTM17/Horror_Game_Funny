# ROOM 407: THE LAST SHIFT — Project Overview and Product Development Requirements

## Product Summary

ROOM 407: THE LAST SHIFT is a single-scene first-person horror experience set in one continuous hotel corridor. A fresh run moves from the lobby, through the blackout floor and distorted memory loop, into Room 407, across a physical chase route, and into an interactive abandoned-lobby epilogue. The intended first-playthrough length is 15–20 minutes of authored exploration, interaction, narration, and chase tension—not a collection of separate levels or empty loading sections.

The current implementation uses Godot 4.7.1 with the Compatibility renderer, procedural low-poly geometry, scene-local controllers, manifest-backed English voice, and process-local checkpoints.

## Requirements

| ID | Requirement | Current evidence | Status |
|---|---|---|---|
| PDR-01 | One continuous `gameplay.tscn` run from lobby to credits | Scene construction, progression and checkpoint tests | Implemented |
| PDR-02 | Guarded lobby, blackout, memory, radio, Room 407 and final-clue progression | `progression-test.tscn`, exact flags/objectives | Implemented |
| PDR-03 | Voice-backed narrative with exact subtitle contracts | 76 cues, 22 groups, `settings-audio` regression | Implemented |
| PDR-04 | Physical chase route with alternating obstructions and connected navigation | Layout, physical-route and live-LOS tests; no human fairness review occurred | Implemented; fairness unverified and accepted risk |
| PDR-05 | Ending wins over capture recovery and gates credits behind two in-world reveals | Phase 3 progression/checkpoint tests | Implemented |
| PDR-06 | Settings, pause, comfort and process-local checkpoint behavior | Input, visual, audio and persistence tests | Implemented |
| PDR-07 | 15–20 minute pacing verified by a human physical production-window run; `ProjectRun` preferred, `EditorF5` optional | No human run, same-run eligible payload, or traversal/perception review was produced | Owner-waived; accepted risk |
| PDR-08 | Final documentation includes reviewed in-engine screenshots and an optimized visual-reference GIF | Four 960×540 deterministic display-grade PNG derivatives and one finite 640×360 GIF under `docs/screenshots/`, with links and provenance | Complete |
| PDR-09 | Fixed story-aligned scares use anticipation → reveal → aftermath with one-shot, pause-safe, teardown-safe spatial audio/light/actor ownership | `horror-event-director.gd`, `horror-scare-sequence.gd`, apparition factory/turn-away actor, focused progression/settings-audio, final 12-check run | Implemented; perceptual quality unverified and accepted risk |
| PDR-10 | Reproducible, credential-free Windows Desktop x86_64 release export with redistribution notices | `export_presets.cfg`, `tests/verify-windows-export.ps1`, PE x86_64 and headless-startup verification | Implemented; rendered target-hardware review waived as accepted risk |

## Player Experience

The player should understand each immediate goal through an objective, a readable prop, a short authored voice beat, or a visible environmental change. The memory loop changes the same corridor behind an opaque blackout transition. The chase uses readable red bypass cues and capsule-safe lanes. The ending keeps movement and look available while the player investigates the condemnation notice and night roster; only visible credits lock input.

## Technical Boundaries

- Runtime: Godot 4.7.1 Compatibility renderer.
- World: one gameplay scene; no level-loading split for the main route.
- Audio: project-authored procedural SFX plus Piper-generated English OGG voice; voice streams use an internal pause-aware Voice bus, mirror the SFX user level, and sidechain-duck SFX.
- State: `GameState` is process-local; restored inventory, flags and completed-event collections are copied so live state cannot mutate a saved checkpoint.
- Delivery: Windows headless test runner, public Linux/Docker twelve-check suite image, packaging/docs CI, and a credential-free unsigned Windows x86_64 release preset whose ignored output is verified for PE architecture and headless startup. The public container is test infrastructure, not the player game. The export preset's `0.9.0.0` version fields are unreleased release-candidate metadata, not a tag or release claim. Export templates and binaries are not committed.

## Acceptance Criteria

Project closure was approved by the owner on 2026-07-19 with the following acceptance-criteria disposition:

1. The canonical twelve-check suite exits zero with all required markers and no scanned engine, script, parse or assertion failures. Known ObjectDB warning noise is intentionally outside runner failure policy; a dated zero-line scan is an additional closure audit.
2. A human physical production-window run (`ProjectRun` preferred, `EditorF5` optional) reaches visible credits with no manual method calls or Continue checkpoint. **Owner-waived; not performed.**
3. That same run emits one eligible, complete and order-valid `PLAYTHROUGH_PACING` payload with active total between 900 and 1200 seconds and chapter durations in range. **Owner-waived; no same-run payload exists.**
4. A human review on the target build records rendered startup/menu behavior, chase fairness, prop readability, audible voice/effects balance, Settings behavior and comfort toggles. **Owner-waived; no perceptual pass occurred.**
5. Reviewed in-engine screenshots and an optimized finite derived GIF are committed under `docs/screenshots/`, linked from the documentation without README autoplay, and render correctly. **Complete for PDR-08; staged media is not physical-playthrough evidence.**
6. The tracked Windows x86_64 preset exports with Godot 4.7.1, stages `LICENSE`, `THIRD_PARTY_NOTICES.md`, and the tag-pinned `GODOT_COPYRIGHT.txt` inventory, passes archive/template/hash/preset/PE/log/headless-startup verification, and leaves binaries/templates outside Git. **Complete for PDR-10 at the automated level; criterion 4 was waived rather than verified.**

## Current Verification Snapshot — 2026-07-19

The latest source-completable run passed the Windows host suite (12/12, exit 0), the
focused physical-evidence regression, both Docker packaging contract verifiers, and the
Windows export/adversarial checks. Docker compose config, local image build, and the
Linux-container suite passed 12/12; registry publication was not performed. The workflow
has no separate publish approval: a passing `main` push publishes automatically only
when both Hub secrets are configured, and no digest means publication is unverified.

Stable recorded export identities are the `117920376`-byte executable SHA-256
`74ef9d12288a4f687f9d5a7de29cfc684737d2af98da97c90e80e77024099190`, official archive
SHA-256 `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72`, and installed
release-template SHA-256
`76269a403bb832599edeee4432a5b7a7e88c018eb5c9c798dfd8289359b0ec07`. Per-run bundle
identities belong in the ignored manifests and dated operator handoff. The docs-only
cover is `1280×640`, SHA-256
`58d5893ef611bfa8b5657c40483073c0ba67c086c0fd2577d4538502d2283980`.

Current command-level evidence is indexed by the
[final source-closure verification and review](../plans/260719-0746-repository-evidence-closure/reports/pm-260719-1501-source-closure.md)
and [final source-consistency hardening report](../plans/260719-2235-final-source-consistency-hardening/reports/pm-260719-2338-source-consistency-final.md).
This is automated/repository evidence only.

## Public Docker Hub Verification — 2026-07-20

The CI/test image is publicly available at
[`nguyenson1710/horror-game-suite`](https://hub.docker.com/r/nguyenson1710/horror-game-suite).
Public API responses verified that `latest` and
`001068f6defa1a7d5bd2e68c43b26fcfe732cf63` both resolve to
`sha256:dabae8950d8cc8b27b88aaecde69b3573dc79d26156f0c0e09fe3b8ee93cc46d`, with UTC
update times `2026-07-19T22:27:08.669248Z` and `2026-07-19T22:27:17.684309Z`.
`DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` are configured GitHub secret names; no secret
value is documented. Local `docker compose run --rm suite` also exited 0 with all twelve
named `OK` lines and `ALL_TWELVE_HEADLESS_CHECKS_OK`.

This is verified publication of the test-suite image at those two tags, not a claim
about a future SHA-named CI publication, playable release, Git tag, GitHub release,
signed executable, or installer. Full command and response-category evidence is in the
[Docker Hub publication report](../plans/260718-1319-final-horror-release-candidate/reports/260720-docker-hub-publication-evidence.md).

## Current Release Decision

Recorded source implementation and automated contracts are green for the available gates. Both the current Windows host suite and local Linux-container suite passed 12/12. The Windows x86_64 export path has a tracked credential-free preset, redistribution notices, and an automated export/headless-startup verifier. Docker Hub publication is verified separately for the CI/test-suite image and recorded tags. These verify source lifecycle, test-container publication, and packaging/startup contracts, not a playable release, audible mix, rendered scare timing/quality, normal-window behavior, or physical play.

PDR-08's documentation-media requirement is complete through a reviewed staged Godot capture, deterministic display-grade PNG derivatives, and a finite GIF deliverable. **PDR-07 is owner-waived / accepted risk:** no reviewed human physical production-window run (`ProjectRun` preferred, `EditorF5` optional), same-run telemetry, player-driven chase-fairness review, live audio/visual review, physical input review, or Settings/fullscreen check is recorded. The staged tour is not a gameplay recording or substitute evidence.

PDR-10's automated export requirement is complete. Project closure rests on the owner's explicit waiver of the remaining human observations, not on manufactured physical or perceptual evidence. The physical runner and review matrix remain optional recommended future QA. This closure does not create a Git tag, GitHub release, signed binary, installer, or store package. The later Docker Hub publication verifies only the CI/test-suite image at the recorded tags and digest.

## References

- [Game design](./game-design.md)
- [Architecture](./architecture.md)
- [Testing matrix](./testing.md)
- [Deployment guide](./deployment-guide.md)
- [Known limitations](./limitations.md)
- [Project roadmap](./project-roadmap.md)
- [`horror-scare-sequence.gd`](../scripts/world/horror-scare-sequence.gd)
- [`horror-apparition-factory.gd`](../scripts/world/horror-apparition-factory.gd)
- [Visual-capture tour contract](./testing.md#reproducible-visual-capture-tour)
- [`export_presets.cfg`](../export_presets.cfg)
- [`verify-windows-export.ps1`](../tests/verify-windows-export.ps1)
- [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md)
- [`GODOT_COPYRIGHT.txt`](../GODOT_COPYRIGHT.txt)
- [Docker Hub publication evidence](../plans/260718-1319-final-horror-release-candidate/reports/260720-docker-hub-publication-evidence.md)
- [Optional physical operator handoff](../plans/260718-1319-final-horror-release-candidate/reports/phase-05-operator-handoff-2026-07-18.md)
- [Phase 3 evidence](../plans/260716-2113-chase-reliability-and-climax-polish/reports/phase-03-voiced-interactive-epilogue-20260716.md)
