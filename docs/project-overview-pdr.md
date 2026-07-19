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
| PDR-04 | Physical chase route with alternating obstructions and connected navigation | Layout, physical-route and live-LOS tests; human fairness review remains open | Implemented; fairness unverified |
| PDR-05 | Ending wins over capture recovery and gates credits behind two in-world reveals | Phase 3 progression/checkpoint tests | Implemented |
| PDR-06 | Settings, pause, comfort and process-local checkpoint behavior | Input, visual, audio and persistence tests | Implemented |
| PDR-07 | 15–20 minute pacing verified from one fresh physical run | Same-run eligible telemetry plus human traversal review | Open |
| PDR-08 | Final documentation includes reviewed in-engine screenshots and an optimized visual-reference GIF | Four 960×540 PNGs and one 640×360 derived GIF under `docs/screenshots/`, with links and provenance | Complete |
| PDR-09 | Fixed story-aligned scares use anticipation → reveal → aftermath with one-shot, pause-safe, teardown-safe spatial audio/light/actor ownership | `horror-event-director.gd`, `horror-scare-sequence.gd`, apparition factory/turn-away actor, focused progression/settings-audio, final 12-check run | Implemented; perceptual quality unverified |
| PDR-10 | Reproducible, credential-free Windows Desktop x86_64 release export with redistribution notices | `export_presets.cfg`, `tests/verify-windows-export.ps1`, PE x86_64 and headless-startup verification | Implemented; rendered target-hardware review open |

## Player Experience

The player should understand each immediate goal through an objective, a readable prop, a short authored voice beat, or a visible environmental change. The memory loop changes the same corridor behind an opaque blackout transition. The chase uses readable red bypass cues and capsule-safe lanes. The ending keeps movement and look available while the player investigates the condemnation notice and night roster; only visible credits lock input.

## Technical Boundaries

- Runtime: Godot 4.7.1 Compatibility renderer.
- World: one gameplay scene; no level-loading split for the main route.
- Audio: project-authored procedural SFX plus Piper-generated English OGG voice; voice streams use an internal pause-aware Voice bus, mirror the SFX user level, and sidechain-duck SFX.
- State: `GameState` is process-local; restored inventory, flags and completed-event collections are copied so live state cannot mutate a saved checkpoint.
- Delivery: Windows headless test runner, Linux/Docker twelve-check suite image, packaging-contract CI, and a credential-free unsigned Windows x86_64 release preset whose ignored output is verified for PE architecture and headless startup. Export templates and binaries are not committed.

## Acceptance Criteria

The implementation is release-ready only when all of the following are true:

1. The canonical twelve-check suite exits zero with all required markers and no scanned engine, script, parse or leak failures.
2. A fresh physical F5 run reaches visible credits with no manual method calls or Continue checkpoint.
3. That same run emits one eligible, complete and order-valid `PLAYTHROUGH_PACING` payload with active total between 900 and 1200 seconds and chapter durations in range.
4. A human review on the target build records rendered startup/menu behavior, chase fairness, prop readability, audible voice/effects balance, Settings behavior and comfort toggles.
5. Reviewed in-engine screenshots and an optimized derived GIF are committed under `docs/screenshots/`, linked from the documentation, and render correctly. **Complete for PDR-08; staged media is not physical-playthrough evidence.**
6. The tracked Windows x86_64 preset exports with Godot 4.7.1, stages `LICENSE`, `THIRD_PARTY_NOTICES.md`, and the tag-pinned `GODOT_COPYRIGHT.txt` inventory, passes archive/template/hash/preset/PE/log/headless-startup verification, and leaves binaries/templates outside Git. **Complete for PDR-10 at the automated level; normal-window review remains part of criterion 4.**

## Current Verification Snapshot — 2026-07-19

The latest source-completable run passed the Windows host suite (12/12, exit 0), the
focused physical-evidence regression, both Docker packaging contract verifiers, and the
Windows export/adversarial checks. The local Docker daemon was unavailable, so live image
build/run and registry publication remain unverified. The active Windows executable is
`117920024` bytes with SHA-256
`420c085640d54e49765362e830b5f6a4ee8b70d18dc1303079485e59e034c771`; the active bundle is
`2111b6f55d318ec257bc6baa4a43117f5ee4d27ccc7c48452a57e6bfc7dcec4d`; the rollback bundle
is `3c4890f2b1d6f99329727d0bd008a043d60a462d807e1c811e337b965f2e7701`. The docs-only
cover is `1280×640`, SHA-256
`58d5893ef611bfa8b5657c40483073c0ba67c086c0fd2577d4538502d2283980`.

Current command-level evidence is indexed by the [tester report](../plans/260719-0746-repository-evidence-closure/reports/tester-2026-07-19.md),
[tester re-verification](../plans/260719-0746-repository-evidence-closure/reports/tester-review-fix-cycle-1-2026-07-19.md),
and [cycle-2 reviewer report](../plans/260719-0746-repository-evidence-closure/reports/code-review-cycle-2-2026-07-19.md)
(9/10, zero critical findings). These reports are automated/repository evidence only.

## Current Release Decision

Recorded source implementation and automated contracts are green for the available gates. Historical GitHub Actions evidence also records a passing container suite; the latest local Docker packaging checks are contract-only because the daemon was unavailable. The Windows x86_64 export path has a tracked credential-free preset, redistribution notices, and an automated export/headless-startup verifier. These verify source lifecycle and packaging/startup contracts, not audible mix, rendered scare timing/quality, normal-window behavior, or physical play.

PDR-08's documentation-media requirement is complete through a reviewed staged Godot capture and curated PNG/GIF deliverables. **PDR-07 remains open:** no fresh 15–20-minute F5 boot-to-credits run, same-run telemetry, player-driven chase-fairness review, live audio/visual review, or physical Settings/fullscreen check is recorded. The staged tour is not a gameplay recording or substitute for those gates.

PDR-10's automated export requirement is complete, but it does not close PDR-07. Per the current testing boundary, no automation controls the user's desktop to manufacture physical or perceptual evidence.

## References

- [Game design](./game-design.md)
- [Architecture](./architecture.md)
- [Testing matrix](./testing.md)
- [Known limitations](./limitations.md)
- [Project roadmap](./project-roadmap.md)
- [`horror-scare-sequence.gd`](../scripts/world/horror-scare-sequence.gd)
- [`horror-apparition-factory.gd`](../scripts/world/horror-apparition-factory.gd)
- [Visual-capture tour contract](./testing.md#reproducible-visual-capture-tour)
- [`export_presets.cfg`](../export_presets.cfg)
- [`verify-windows-export.ps1`](../tests/verify-windows-export.ps1)
- [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md)
- [`GODOT_COPYRIGHT.txt`](../GODOT_COPYRIGHT.txt)
- [Phase 3 evidence](../plans/260716-2113-chase-reliability-and-climax-polish/reports/phase-03-voiced-interactive-epilogue-20260716.md)
