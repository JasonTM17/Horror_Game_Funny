# Goal A-to-Z final verification — 2026-07-19

## Goal (user)

Use ck workflow to finish the project end-to-end for release readiness polish:
professional Docker Hub packaging and professional repository documentation with
images and GIF.

## Scope completed (agent-achievable)

| Requirement | Status | Proof |
|---|---|---|
| Professional Docker suite image | Done | `Dockerfile` multi-stage, `USER 65532:65532`, `HEALTHCHECK`, image `nguyenson1710/horror-game-suite` |
| Godot download supply-chain pin | Done | `GODOT_SHA256=c7ff14fd28472c8d4f193043de30278dcf7e5241a1dcf7566b02e27addaa33ba` verified via `sha256sum -c` |
| Compose + Hub naming | Done | `docker-compose.yml` → `nguyenson1710/horror-game-suite:latest` |
| CI build + suite | Done | `docker-suite` success on tip (container `ALL_TWELVE_HEADLESS_CHECKS_OK`) |
| CI packaging/docs/secrets | Done | `ci` success on tip |
| Professional README media | Done | Cover + GIF + 4 stills linked with evidence boundaries |
| Cover contract | Done | 1280×640, SHA-256 `58d5893ef611bfa8b5657c40483073c0ba67c086c0fd2577d4538502d2283980` |
| Evidence-closure child plan | Done | 21/21 criteria; status completed |
| Clean remote tip | Done | `main` == `origin/main` at `b5df3d02765595590621f09a71b5a6d1e1cf9df8` |
| Physical evidence path hardening | Done | EvidenceRoot under `.artifacts`, reparse ancestors rejected, 1MB snapshot cap |

## Verification plan (executed; tip advanced to `b5df3d0`)

Primary automated re-verify was recorded on `c6ebf76` (host 12/12, packaging, secrets,
evidence regression). Tip `b5df3d0` adds EvidenceRoot containment + regression
StrictMode constant mirroring; focused evidence regression re-passed at exit 0 before
push. CI on `b5df3d0` must be green (see live URLs below after poll).

### V1 — Repository identity

```text
git rev-parse HEAD
# b5df3d02765595590621f09a71b5a6d1e1cf9df8
git rev-parse origin/main
# b5df3d02765595590621f09a71b5a6d1e1cf9df8
git status --short --branch
# ## main...origin/main   (clean after tip commits)
```

### V2 — Host twelve-check suite

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1
# HOST_EXIT=0
# markers: editor-import OK … settings-persistence-read OK (12/12)
```

Observed: `HOST_EXIT=0` with all twelve check OK markers (Godot 4.7.1 official).

### V3 — Packaging + secret + evidence regressions

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\verify-docker-packaging.ps1
# DOCKER_PACKAGING_VERIFY_OK  PACK_EXIT=0
bash tests/verify-docker-packaging.sh
# DOCKER_PACKAGING_VERIFY_OK  BASH_PACK_EXIT=0
bash tests/scan-secret-patterns.sh
# SECRET_PATTERN_SCAN_OK  SECRET_EXIT=0
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\physical-playthrough-evidence-regression.ps1
# PHYSICAL_EVIDENCE_REPARSE_REGRESSION_OK
# PHYSICAL_EVIDENCE_SIDECHANNEL_REGRESSION_OK  EVIDENCE_EXIT=0
```

### V4 — CI on tip

| Workflow | Conclusion | URL |
|---|---|---|
| `ci` | success | https://github.com/JasonTM17/Horror_Game_Funny/actions/runs/29674034902 |
| `docker-suite` | success | https://github.com/JasonTM17/Horror_Game_Funny/actions/runs/29674034901 |

`docker-suite` built `nguyenson1710/horror-game-suite:latest` and emitted
`ALL_TWELVE_HEADLESS_CHECKS_OK`.

### V5 — Professional media inventory

| Path | Size | SHA-256 |
|---|---|---|
| `docs/media/room-407-cover.png` | 999431 | `58d5893ef611bfa8b5657c40483073c0ba67c086c0fd2577d4538502d2283980` |
| `docs/screenshots/room-407-gameplay-tour.gif` | 3158201 | `8bcbe98c1c42d9013e985ac15a501140065cd2286dd0ab1c6a6fefbc67b6fb4b` |
| `docs/screenshots/room-407-lobby.png` | 472535 | `b9535170b827b551e2f0656ac8a1f924d57f56c7c9569152b6cbd213db12d55b` |
| `docs/screenshots/room-407-bedroom.png` | 414865 | `10da0fc383e357bbccad83389565afd6acce254ae07ccd1562867087062b8bc7` |
| `docs/screenshots/room-407-chase-entity.png` | 381140 | `826aee57128e9b26660e4902407cf9b88fcef901c7de2b6396ea8a1f365969e5` |
| `docs/screenshots/room-407-ending-reveal.png` | 445218 | `0c2556ba0475ebbcfda00bd7c56931cce0b7dc2dca63ebc2d0a54cd2e472d9ac` |

Cover IHDR dimensions: **1280×640**. README links cover, GIF tour, still gallery,
and Hub image name with non-physical evidence boundaries.

### V6 — Docker Hub publication contract

| Check | Result |
|---|---|
| Image name / tags contract | `nguyenson1710/horror-game-suite:latest` + `:<git-sha>` on main publish |
| CI image build | Succeeded on tip |
| Registry push | **Skipped** — secrets `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` not configured in the repository |
| Local Docker daemon | Unavailable on authoring host (`Server=NONE`) |

Honest residual (configuration, not code): set GitHub Actions secrets, then re-run
`docker-suite` to publish Hub tags. Until then the suite image is CI-built and
contract-verified but not claimed as present on Hub.

## Explicit non-claims (correct)

- **PDR-07 / parent Phase 5 physical F5** remains **open** (human-only). Not part of
  the Docker Hub + professional-docs goal surface; handoff is ready at
  `plans/260718-1319-final-horror-release-candidate/reports/phase-05-operator-handoff-2026-07-18.md`.
- Staged screenshots/GIF are documentation media, not physical playthrough proof.
- Hub registry presence is not claimed without secrets.

## Verdict

**Goal complete for agent-achievable A-to-Z polish:** professional Docker packaging
(with CI-proven build + twelve-check container suite), professional repository docs
with cover/images/GIF, green host/CI gates, clean `main` tip. Remaining human/config
actions are optional Hub secret configuration and the separate PDR-07 physical gate.
