# ROOM 407: THE LAST SHIFT - Project Roadmap

## Delivery State

The game preserves one continuous gameplay route. Project closure was approved by the
owner on 2026-07-19. The remaining human physical/perceptual review is an accepted risk,
not a completed validation gate.

| Phase | Scope | Status |
|---|---|---|
| 1 | Terminal ending and capture-recovery race | Complete |
| 2 | Navigation-safe right-left-right chase route | Complete |
| 3 | Voiced two-step interactive epilogue and checkpoint isolation | Complete |
| 4 | Staged documentation media and physical release-evidence handoff | Staged media complete; human review owner-waived |
| 5 | Windows x86_64 export automation and redistribution notices | Complete at automated level |
| 6 | Public release documentation and package contract | `v0.9.0` release specification complete; asset availability is confirmed only on the release page |

## Release Track

The playable release contract is documented in [Release v0.9.0](release-v0.9.0.md):

- an unsigned Windows x64 portable ZIP;
- a separately published SHA-256 checksum record;
- extract-first, SmartScreen, controls, and support guidance; and
- retained license and Godot notice files beside the executable.

The package is a player download only when the
[GitHub Release v0.9.0](https://github.com/JasonTM17/Horror_Game_Funny/releases/tag/v0.9.0)
lists the two named assets. The release does not convert PDR-07 into a pass and does not
claim code signing, installer delivery, or human perceptual testing.

`ghcr.io/jasontm17/horror-game-suite` is a separate public CI/headless test package. It
is never the player game. Docker Hub records from 2026-07-20 are historical legacy-mirror
evidence; mutable `latest` is not a release identity.

## Phase 4 / PDR-07 Disposition

- [x] Owner waived the human production-window phase as a project-closure requirement and
  accepted the resulting risk.
- [x] Captured and documented four deterministic staged stills plus one finite
  visual-reference GIF. This does not substitute for a player-driven recording.
- [ ] Optional future QA: record a fresh **START SHIFT**-to-credits production-window run
  with physical keyboard/mouse input and one same-run pacing payload.
- [ ] Optional future QA: review chase fairness, darkness/flicker/grain comfort, audio,
  Settings, fullscreen, input, and target-hardware behavior while watching that capture.

## Guardrails

- Do not treat compressed headless timing, checkpoint-start sessions, staged screenshots,
  concept art, or AI-generated material as physical gameplay evidence.
- Do not treat exported-executable headless startup as a rendered menu, physical input,
  audio, pacing, or perceptual pass.
- Do not present a container image as a playable game package.
- Do not treat a mutable registry tag as an immutable release identity.
- Preserve dated plans and journals as historical evidence rather than editing them to
  describe later publication state.

## Historical Evidence

The 2026-07-19 source-closure reports remain the authoritative record for source-level
verification at that time. Their Docker Hub statements are dated observations. Current
release instructions live in [Release v0.9.0](release-v0.9.0.md) and the
[Deployment guide](deployment-guide.md).

## References

- [Project overview and PDR](project-overview-pdr.md)
- [Release v0.9.0](release-v0.9.0.md)
- [Deployment guide](deployment-guide.md)
- [Testing](testing.md)
- [Limitations](limitations.md)
- [Staged visual-capture tour](testing.md#reproducible-visual-capture-tour)
- [Final source-closure verification and review](../plans/260719-0746-repository-evidence-closure/reports/pm-260719-1501-source-closure.md)
- [Final source-consistency hardening report](../plans/260719-2235-final-source-consistency-hardening/reports/pm-260719-2338-source-consistency-final.md)
