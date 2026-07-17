# Horror Game Funny - Project Overview and Product Development Requirements

## Product Summary

Horror Game Funny is a single-scene first-person horror experience set in one continuous hotel corridor. A fresh run moves from the lobby, through the blackout floor and distorted memory loop, into Room 407, across a physical chase route, and into an interactive abandoned-lobby epilogue. The intended first-playthrough length is 15–20 minutes of authored exploration, interaction, narration, and chase tension—not a collection of separate levels or empty loading sections.

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

## Player Experience

The player should understand each immediate goal through an objective, a readable prop, a short authored voice beat, or a visible environmental change. The memory loop changes the same corridor behind an opaque blackout transition. The chase uses readable red bypass cues and capsule-safe lanes. The ending keeps movement and look available while the player investigates the condemnation notice and night roster; only visible credits lock input.

## Technical Boundaries

- Runtime: Godot 4.7.1 Compatibility renderer.
- World: one gameplay scene; no level-loading split for the main route.
- Audio: project-authored procedural SFX plus Piper-generated English OGG voice; voice streams are SFX-routed and pause-aware.
- State: `GameState` is process-local; restored inventory, flags and completed-event collections are copied so live state cannot mutate a saved checkpoint.
- Delivery: Windows headless test runner, focused regression checks, conventional commits, non-force pushes to `main`.

## Acceptance Criteria

The implementation is release-ready only when all of the following are true:

1. The canonical twelve-check suite exits zero with all required markers and no scanned engine, script, parse or leak failures.
2. A fresh physical F5 run reaches visible credits with no manual method calls or Continue checkpoint.
3. That same run emits one eligible, complete and order-valid `PLAYTHROUGH_PACING` payload with active total between 900 and 1200 seconds and chapter durations in range.
4. A human review records chase fairness, prop readability, audible voice/effects balance, Settings behavior and comfort toggles.
5. Reviewed in-engine screenshots and an optimized derived GIF are committed under `docs/screenshots/`, linked from the documentation, and render correctly. **Complete for PDR-08; staged media is not physical-playthrough evidence.**

## Current Release Decision

Source implementation and automated contracts are green. The fixed scare slice passed focused `progression`/`settings-audio` plus the final 2026-07-17 canonical 12/12 run in 63.5 seconds, with exactly 12 logs, zero scanned current failure lines including lambda/leak patterns, and zero remaining runner profiles. Its final review had zero Critical, High, or Medium findings after two Medium lifecycle defects were fixed. This verifies source lifecycle contracts, not audible mix, rendered scare timing/quality, or physical play.

PDR-08's documentation-media requirement is complete through a reviewed staged Godot capture and curated PNG/GIF deliverables. PDR-07 and the parent physical/perceptual release gates remain open: no fresh 15–20-minute F5 boot-to-credits run, same-run telemetry, player-driven chase-fairness review, live audio/visual review, or physical Settings/fullscreen check is recorded. The staged tour is not a gameplay recording or substitute for those gates.

## References

- [Game design](./game-design.md)
- [Architecture](./architecture.md)
- [Testing matrix](./testing.md)
- [Known limitations](./limitations.md)
- [Project roadmap](./project-roadmap.md)
- [`horror-scare-sequence.gd`](../scripts/world/horror-scare-sequence.gd)
- [`horror-apparition-factory.gd`](../scripts/world/horror-apparition-factory.gd)
- [Visual-capture tour contract](./testing.md#reproducible-visual-capture-tour)
- [Phase 3 evidence](../plans/260716-2113-chase-reliability-and-climax-polish/reports/phase-03-voiced-interactive-epilogue-20260716.md)
