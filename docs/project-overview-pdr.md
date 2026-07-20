# ROOM 407: THE LAST SHIFT - Project Overview and Product Development Requirements

## Product Summary

ROOM 407: THE LAST SHIFT is a single-scene first-person psychological-horror experience.
A fresh run moves from the lobby through the blackout floor and memory loop into Room 407,
a physical chase, an abandoned-lobby investigation, and credits. The intended first-run
duration is 15-20 minutes of authored exploration, narration, interaction, and tension.

The project uses Godot 4.7.1 Compatibility rendering, procedural low-poly geometry,
scene-local controllers, manifest-backed English voice, and process-local checkpoints.

## Requirements

| ID | Requirement | Current evidence | Status |
|---|---|---|---|
| PDR-01 | One continuous `gameplay.tscn` run from lobby to credits | Scene construction, progression, and checkpoint tests | Implemented |
| PDR-02 | Guarded lobby, blackout, memory, radio, Room 407, and final-clue progression | `progression-test.tscn` and exact flags/objectives | Implemented |
| PDR-03 | Voice-backed narrative with exact subtitle contracts | 76 cues, 22 groups, `settings-audio` regression | Implemented |
| PDR-04 | Physical chase route with alternate obstructions and connected navigation | Layout, physical-route, and line-of-sight tests | Implemented; fairness unverified and accepted risk |
| PDR-05 | Ending wins over capture recovery and gates credits behind two reveals | Progression and checkpoint tests | Implemented |
| PDR-06 | Settings, pause, comfort, and process-local checkpoint behavior | Input, visual, audio, and persistence tests | Implemented |
| PDR-07 | 15-20 minute pacing verified by a human production-window run | No human run, same-run payload, or perception review | Owner-waived; accepted risk |
| PDR-08 | Reviewed in-engine screenshots and optimized visual-reference GIF | Four deterministic PNG derivatives and one finite GIF under `docs/screenshots/` | Complete |
| PDR-09 | Fixed scares with pause-safe spatial audio/light/actor ownership | Horror controllers and focused/full suites | Implemented; perceptual quality unverified and accepted risk |
| PDR-10 | Credential-free Windows Desktop x86_64 export with notices | Preset, export verifier, PE x64, and headless-startup contract | Complete at automated level |

## Player Experience

Each immediate goal is communicated through an objective, readable prop, voice beat, or
visible environmental change. The memory loop rearranges the same corridor behind an
opaque blackout transition. The chase uses readable red bypass cues and capsule-safe
lanes. Only the visible credits lock input during the ending investigation.

## Delivery Model

- **Playable distribution:** the `v0.9.0` release contract is an unsigned Windows x64
  portable ZIP plus its SHA-256 record on the GitHub Release page. The package exists only
  when that page lists both assets; it is not an installer or a signing claim.
- **Source and export:** `export_presets.cfg` and `tests/verify-windows-export.ps1` check
  a credential-free x64 export, notices, PE architecture, and headless process startup.
  Export templates and generated artifacts are not committed.
- **Test container:** `ghcr.io/jasontm17/horror-game-suite` is the public headless CI/test
  package. It is never a player download or gameplay distribution.
- **Historical mirror:** Docker Hub records are dated legacy CI evidence. Its mutable
  `latest` tag is not a durable player-release or reproducibility identity.

## Acceptance Criteria and Evidence Boundary

Project closure was approved by the owner on 2026-07-19. The canonical twelve-check suite
and source/export contracts are the available automated evidence. The staged documentation
media requirement is complete, but staged media is not gameplay recording evidence.

PDR-07 remains explicitly owner-waived: there is no reviewed human production-window run,
same-run eligible pacing payload, player-driven chase review, live audio/visual review,
physical-input review, or Settings/fullscreen review. A later GitHub Release can distribute
the verified portable archive without changing that waiver or manufacturing manual proof.

The automated export path proves neither a rendered menu, normal-window startup, physical
input, audible output, SmartScreen behavior, target-hardware performance, nor code signing.
The physical runner and review matrix remain optional recommended future QA.

## Historical Evidence

The 2026-07-19 source-closure snapshot recorded Windows host 12/12, focused hardening,
Docker packaging, and Windows export/adversarial checks. Its Docker publication language
and Docker Hub lookup are time-bound historical observations, not current release claims.
The durable release mechanics are maintained in [Release v0.9.0](release-v0.9.0.md) and
the [Deployment guide](deployment-guide.md).

## References

- [Documentation hub](README.md)
- [Release v0.9.0](release-v0.9.0.md)
- [Vietnamese guide](vi/README.md)
- [Architecture](architecture.md)
- [Testing matrix](testing.md)
- [Deployment guide](deployment-guide.md)
- [Known limitations](limitations.md)
- [Project roadmap](project-roadmap.md)
- [Asset credits](asset-credits.md)
- [`export_presets.cfg`](../export_presets.cfg)
- [`verify-windows-export.ps1`](../tests/verify-windows-export.ps1)
- [Final source-closure verification and review](../plans/260719-0746-repository-evidence-closure/reports/pm-260719-1501-source-closure.md)
- [Final source-consistency hardening report](../plans/260719-2235-final-source-consistency-hardening/reports/pm-260719-2338-source-consistency-final.md)
