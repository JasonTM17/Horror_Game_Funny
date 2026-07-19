---
title: Final horror release candidate
description: >-
  Turn Room 407 into the strongest practical horror release candidate through
  authored scare, audio, readability, QA, physical-window, and Windows-export
  work.
status: completed
priority: P1
branch: main
tags:
  - horror
  - release-candidate
  - windows
blockedBy:
  - 260719-2235-final-source-consistency-hardening
blocks: []
created: '2026-07-18T13:19:00+07:00'
createdBy: 'ck:cook'
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
  an explicitly resolved physical-review disposition; and a smoke-tested Windows x86_64
  build from a committed export preset.
- **Acceptance:** no current regression, new fuse/scare contracts covered, 12/12 clean,
  no known main-path crash/soft-lock, physical/perceptual evidence is either reviewed or
  explicitly waived with residual risk recorded, evidence claims remain honest, and the
  exported build passes its defined startup smoke.
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
| 5 | [Physical F5 review and pacing validation](./phase-05-physical-f5-review-and-pacing-validation.md) | Completed |
| 6 | [Windows export, docs, and completion audit](./phase-06-windows-export-docs-and-completion-audit.md) | Completed |

## Dependencies

- Phase 1 gates all later work. Phases 2 and 3 both precede Phase 4.
- Phase 4 must be green before physical traversal or export is accepted.
- Phase 5 findings route back to their owning source phase and repeat Phase 4.
- Phase 6 may complete independently after a green Phase 4. Any later Phase 5 finding that changes source must route back to its owning phase, repeat Phase 4, and regenerate the export evidence.

## Evidence Map

| Requirement | Authoritative evidence |
|---|---|
| Scare staging/lifecycle | Focused progression contracts; perceptual quality owner-waived |
| Voice-safe audio | Settings/audio regression; listening quality owner-waived |
| Chase/clue readability | Staged comparison; physical fairness/readability owner-waived |
| No regressions | 12/12 host suite, log scan, mandatory review, diff check |
| Main route/pacing | Instrumentation contracts plus explicit owner waiver of human pacing evidence |
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

Every evidence-map row must have current proof or an explicit owner-approved risk waiver,
the exported build must pass its defined startup smoke, all unverified perceptual limits
must remain explicit, docs/plans must match reality, and final Git delivery must be
intentional before the parent goal can close.

## Source polish landing (2026-07-18)

Source-level RC polish landed on `main` through:
`2ecf78a` (scare/audio/chase polish), `89042b5` (dual-key InputMap),
`298467b` (menu + story stills), `821ef26` (chapter scare fallback + dual-key/eyes
contracts), `129ae35` (room-drawing facing/fallback coverage), `3f9761a`
(tracked credential-free export preset), and `4684f29` (Windows export verifier
and third-party notices). Multi-agent re-verify reports live under `reports/`
(tester/reviewer/scout/docs/export-readiness/export-verified).

At that source-polish checkpoint, Phases 1–4 were **Completed**. Phase 5 (human physical
production-window run; ProjectRun preferred, EditorF5 optional / PDR-07) remained open
by policy, and Phase 6 (Windows export/docs/completion audit) was **Completed**. Details:
[source-polish-landing-2026-07-18.md](./reports/source-polish-landing-2026-07-18.md),
[windows-export-verified-2026-07-18.md](./reports/windows-export-verified-2026-07-18.md),
[final-automated-audit-2026-07-18.md](./reports/final-automated-audit-2026-07-18.md).

## Repository evidence closure — 2026-07-19

The [repository evidence closure child plan](../260719-0746-repository-evidence-closure/plan.md)
is source-complete: 4/4 phases and 21/21 criteria. Current authority:
[PM reconciliation](../260719-0746-repository-evidence-closure/reports/pm-260719-1501-source-closure.md),
[final tester](../260719-0746-repository-evidence-closure/reports/tester-final-2026-07-19.md),
and [final reviewer](../260719-0746-repository-evidence-closure/reports/code-review-final-2026-07-19.md).
Reviewer verdict is **Pass for staging** with 0 Critical/High/Medium and one informational
Low. Delivery then completed as QA commit `ad514cba881270d43fa532d324224618dd48d364`
and report-containing closure commit `c28beeed7a4bafd871e09225152f329beac09e9a`.
The real-index verifier emitted all four success markers; local, `origin/main`, and remote
main reached 0/0 parity. [`ci`](https://github.com/JasonTM17/Horror_Game_Funny/actions/runs/29688458245)
and [`docker-suite`](https://github.com/JasonTM17/Horror_Game_Funny/actions/runs/29688458242)
both passed. The Hub step skipped because Actions secrets are absent; no tag or digest is
claimed. This post-delivery reconciliation changes documentation only.

At this snapshot the parent stayed **in progress**: 5/6 phases completed; Phase 5
checklist 4/10 and human success criteria 0/5. That historical state is superseded by
the 2026-07-19 owner waiver below. Docker build/container 12/12 were green. No Actions
secrets were listed, so Docker Hub publication/digest was not claimed.

## Final source consistency hardening — 2026-07-19

The [source-consistency child plan](../260719-2235-final-source-consistency-hardening/plan.md)
is complete: 3/3 phases and 13/13 criteria. It corrected settings-signal type
compatibility, cycle-aligned procedural loop PCM, spatial parent-exit cleanup, repository
line-ending/security/history wording, and current export/operator-handoff fingerprints.
The final host suite passed 12/12; evidence/export/repository gates passed; final review
scored 10/10 with zero unresolved Critical/High/Medium. This satisfies the temporary
source-hardening dependency. Human physical/perceptual validation remained absent at
that point and is resolved only by the explicit owner waiver below.

## Owner-approved closure — 2026-07-19

The project owner explicitly waived the human physical production-window and perceptual
review requirement for PDR-07 and accepted the residual uncertainty. No human run or
perceptual pass is claimed. Unverified areas remain full-duration pacing, player-driven
chase fairness, rendered readability/comfort, audible balance, physical input, Settings,
and fullscreen behavior. The optional runner and review matrix remain available for
future confidence-building, but they no longer block project closure. The
[final owner-waiver closure review](./reports/260720-owner-waiver-closure-review.md)
records the three-stage verdict and automated evidence boundary.

## Post-closure Docker Hub publication evidence — 2026-07-20

The public CI/test-suite image publication was verified after project closure. Both
`latest` and SHA-named tag `001068f6defa1a7d5bd2e68c43b26fcfe732cf63` resolve to
the recorded shared digest, and a local compose run passed the canonical 12/12 suite.
This follow-up does not revise the owner-waived human QA boundary or make player-release,
Git-tag, GitHub-release, signing, or installer claims. It also does not pre-claim a
future SHA-named CI publication. See the
[Docker Hub publication evidence](./reports/260720-docker-hub-publication-evidence.md).
