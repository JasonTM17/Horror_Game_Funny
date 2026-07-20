# Known Limitations

## Distribution and Trust

- The player-facing delivery is an **unsigned Windows x64 portable ZIP**, not an installer.
  It is available only when the GitHub release page lists both the ZIP and its SHA-256
  record. See [Release v0.9.0](release-v0.9.0.md).
- The build is not code-signed. Windows SmartScreen may warn because no publisher identity
  is attached. Verify the official release source and ZIP checksum before deciding whether
  to run it; if either is uncertain, do not run the executable.
- `tests/verify-windows-export.ps1` validates the selected credential-free export preset,
  official Godot/template hashes, logs, PE x64 architecture, notices, and a headless
  startup. It does not verify a rendered menu, physical controls, audio output,
  fullscreen, SmartScreen behavior, target-GPU performance, or code signing.
- The public GHCR package `ghcr.io/jasontm17/horror-game-suite` is a **CI/headless test
  package**, not a player build. Docker Hub entries are historical legacy mirrors; do not
  use mutable `latest` as a player-release or reproducibility identity.
- The project uses the MIT license for project code and project-authored assets. Godot and
  third-party notices remain subject to their own terms and must travel with distribution.

## Human-QA Boundary

PDR-07 was waived by the owner as an accepted project-closure risk on 2026-07-19. No
recorded human production-window run reached credits with physical keyboard/mouse input,
and no same-run eligible pacing payload, capture review, or perceptual review exists.

The following are not verified by the automated suite or release package:

- 15-20 minute blind-run pacing and chapter timing;
- physical keyboard/mouse input, mouse capture, and input latency;
- chase fairness, collision/door feel, and live navigation under player control;
- darkness readability, flicker/grain comfort, monitor gamma, and GPU performance;
- audible narration, SFX, spatial cues, and mix balance;
- normal-window startup, Settings interaction, fullscreen transition, and persisted
  settings behavior on a target machine; and
- SmartScreen/reputation behavior or destination-specific distribution requirements.

Staged documentation screenshots and the finite GIF are reviewed visual references. They
are not a player-driven recording, physical-playthrough evidence, or a substitute for any
of the observations above.

## Persistence and Runtime Scope

- Gameplay checkpoints exist only in the process-local `GameState` autoload. Restarting
  the application starts a fresh shift.
- The boot **CONTINUE SHIFT** option appears only when an in-memory checkpoint exists.
- Settings apply immediately and can save to `user://room407.cfg`. Automated persistence
  checks use isolated profiles; they do not prove the physical settings-panel workflow.
- The game, UI, subtitles, and voice are English. The [Vietnamese guide](vi/README.md) is
  documentation only, not a runtime localization.

## Automated Test Scope

The canonical host and container runners have exactly twelve headless checks. They cover
resource loading, selected source/layout invariants, targeted production-player paths,
pacing-telemetry contracts, visual-effect contracts, audio/settings behavior, and settings
persistence across two isolated processes. They are intentionally not a human playthrough.

The physical-evidence runner can preserve bounded logs and one verified pacing side
channel for a future reviewer. It cannot prove the recording's contents, distinguish a
declared input source from actual hardware input, or judge presentation quality. Its
generated review matrix must be completed by a person before such claims are made.

## Historical Records

The 2026-07-19 source-closure reports and the 2026-07-20 Docker Hub lookup remain dated
historical evidence. They should not be rewritten to imply later GitHub Release or GHCR
publication state. Current release mechanics live in [Release v0.9.0](release-v0.9.0.md)
and the [Deployment guide](deployment-guide.md).

## References

- [Release v0.9.0](release-v0.9.0.md)
- [Vietnamese guide](vi/README.md)
- [Testing](testing.md)
- [Project overview and PDR](project-overview-pdr.md)
- [Deployment guide](deployment-guide.md)
- [Asset credits](asset-credits.md)
- [`run-physical-playthrough.ps1`](../tests/run-physical-playthrough.ps1)
- [`verify-windows-export.ps1`](../tests/verify-windows-export.ps1)
