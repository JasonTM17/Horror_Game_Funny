---
title: "Final horror release candidate"
description: >-
  Turn Room 407 into the strongest practical horror release candidate through
  authored scare, audio, readability, QA, physical-window, and Windows-export work.
status: in-progress
priority: P1
branch: "main"
tags: [horror, release-candidate, windows]
blockedBy: []
blocks: []
created: "2026-07-18T13:19:00+07:00"
createdBy: "ck:cook"
source: skill
---

# Final horror release candidate

## Outcome

Deliver a coherent, scary, enjoyable psychological-horror release candidate while
preserving the continuous Godot 4.7.1 Compatibility scene, story, checkpoints, and
public runtime contracts. Green tests alone are not completion.

## Requirements Contract

- **Output:** polished source; stronger deterministic scares and atmosphere;
  monitor-safe clue/chase readability; voice-safe audio; current automated evidence;
  a real-window F5 traversal package; and a smoke-tested Windows x86_64 build from a
  committed export preset.
- **Acceptance:** no current regression, new fuse/scare contracts covered, 12/12 clean,
  no known main-path crash/soft-lock, production window reaches credits with same-run
  telemetry, evidence claims remain honest, and exported build launches to the menu.
- **Out of scope:** new levels, combat, paid packs, random jumpscare spam, engine rewrite,
  persistent save redesign, or changes to the main story/continuous-scene architecture.
- **Constraints:** Godot 4.7.1 standard/Compatibility, project-authored/procedural assets,
  stable flags/checkpoints/settings/audio APIs, no force push, no fake physical evidence.
- **Touchpoints:** horror director/factory/sequence, audio/voice routing, world/chase
  presentation, visual effects/settings UI, progression/layout/visual/audio tests,
  export config, evidence runner, and release docs.

## Direction Rules

1. Fear comes from anticipation, reveal, aftermath, and silence—not raw volume.
2. Critical props and escape lanes remain readable on ordinary SDR displays.
3. Story scares are deterministic, one-shot, pause-safe, and teardown-safe.
4. Voice remains intelligible during overlapping spatial SFX.
5. Each claim is limited to what its current artifact actually proves.

## Phases

| Phase | Name | Status |
|---|---|---|
| 1 | [Recover green baseline and scare contracts](./phase-01-recover-green-baseline-and-scare-contracts.md) | Completed |
| 2 | [Experiential horror and audio polish](./phase-02-experiential-horror-and-audio-polish.md) | Completed |
| 3 | [Chase readability and settings UX polish](./phase-03-chase-readability-and-settings-ux-polish.md) | Completed |
| 4 | [Regression coverage and automated evidence](./phase-04-regression-coverage-and-automated-evidence.md) | Completed |
| 5 | [Physical F5 review and pacing validation](./phase-05-physical-f5-review-and-pacing-validation.md) | In progress |
| 6 | [Windows export, docs, and completion audit](./phase-06-windows-export-docs-and-completion-audit.md) | Completed |

## Dependencies

- Phase 1 gates all later work. Phases 2 and 3 both precede Phase 4.
- Phase 4 must be green before physical traversal or export is accepted.
- Phase 5 findings route back to their owning source phase and repeat Phase 4.
- Phase 6 uses the exact source revision proven by Phases 4-5.

## Evidence Map

| Requirement | Authoritative evidence |
|---|---|
| Scare staging/lifecycle | Focused progression contracts plus real-window observation |
| Voice-safe audio | Settings/audio regression plus recorded listening notes |
| Chase/clue readability | Staged comparison plus production-window review matrix |
| No regressions | 12/12 host suite, log scan, mandatory review, diff check |
| Main route/pacing | Same-run production-window capture/log/pacing payload |
| Windows delivery | Export preset/log, build hash, headless startup smoke |
| Truthful docs | Documentation review against current artifacts and limitations |

## Risk Controls

- Keep scare cue rollback values; never solve fear by near-0 dB layering.
- Prefer local task/guide contrast before raising global exposure.
- Use fixed corridor anchors for story-described distance and bounded relative anchors
  only where interaction positions are controlled.
- Keep templates/builds on drive D and binaries out of Git.
- Label agent-driven OS input separately from a human blind playtest.

## Completion Boundary

Every evidence-map row must have current proof, the exported build must launch, all
open perceptual limits must be explicit, docs/plans must match reality, and final Git
delivery must be intentional before the parent goal can close.

## Source polish landing (2026-07-18)

Source-level RC polish landed on `main` through:
`2ecf78a` (scare/audio/chase polish), `89042b5` (dual-key InputMap),
`298467b` (menu + story stills), `821ef26` (chapter scare fallback + dual-key/eyes
contracts), `129ae35` (room-drawing facing/fallback coverage), `3f9761a`
(tracked credential-free export preset), and `4684f29` (Windows export verifier
and third-party notices). Multi-agent re-verify reports live under `reports/`
(tester/reviewer/scout/docs/export-readiness/export-verified).

Phases 1–4 stay **Completed**. Phase 5 (physical F5 / PDR-07) remains open by
policy. Phase 6 (Windows export/docs/completion audit) is now **Completed**. Details:
[source-polish-landing-2026-07-18.md](./reports/source-polish-landing-2026-07-18.md),
[windows-export-verified-2026-07-18.md](./reports/windows-export-verified-2026-07-18.md),
[final-automated-audit-2026-07-18.md](./reports/final-automated-audit-2026-07-18.md).
