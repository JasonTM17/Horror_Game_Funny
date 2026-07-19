---
title: Docker Hub publication evidence
date: 2026-07-20
status: verified
scope: public CI/test-suite image publication
---

# Docker Hub Publication Evidence

## Summary

Public, unauthenticated Docker Hub API responses verified the CI/test-suite repository
[`nguyenson1710/horror-game-suite`](https://hub.docker.com/r/nguyenson1710/horror-game-suite)
and its `latest` and SHA-named tags. Both tags resolve to the same digest. A local
compose execution independently passed the canonical twelve-check headless suite.

This is test-infrastructure publication evidence. It preserves the owner-approved waiver
of human physical/perceptual QA and does not claim a playable release, Git tag, GitHub
release, signed binary, or installer.

## Evidence Commands and Categories

The following PowerShell commands were used locally on 2026-07-20. The API calls are
unauthenticated and therefore exercise the public repository surface.

```powershell
docker compose build suite
docker tag nguyenson1710/horror-game-suite:latest nguyenson1710/horror-game-suite:001068f6defa1a7d5bd2e68c43b26fcfe732cf63
docker push nguyenson1710/horror-game-suite:latest
docker push nguyenson1710/horror-game-suite:001068f6defa1a7d5bd2e68c43b26fcfe732cf63

docker buildx imagetools inspect nguyenson1710/horror-game-suite:latest --raw
docker buildx imagetools inspect nguyenson1710/horror-game-suite:001068f6defa1a7d5bd2e68c43b26fcfe732cf63 --raw

$repository = Invoke-RestMethod -Uri 'https://hub.docker.com/v2/repositories/nguyenson1710/horror-game-suite/'
$latest = Invoke-RestMethod -Uri 'https://hub.docker.com/v2/repositories/nguyenson1710/horror-game-suite/tags/latest/'
$sourceSha = Invoke-RestMethod -Uri 'https://hub.docker.com/v2/repositories/nguyenson1710/horror-game-suite/tags/001068f6defa1a7d5bd2e68c43b26fcfe732cf63/'

$repository | Select-Object namespace, name, is_private
$latest | Select-Object name, digest, last_updated
$sourceSha | Select-Object name, digest, last_updated

docker compose run --rm suite
```

| Category | Evidence |
|---|---|
| Local image build | `docker compose build suite` completed before publication |
| Tag creation | The locally built `latest` image was given the SHA-named tag recorded below; tag naming alone is not source attestation |
| Registry upload | Separate pushes completed for `latest` and the SHA-named tag |
| Raw registry manifests | `docker buildx imagetools inspect ... --raw` inspected both published tags |
| Public repository | Unauthenticated repository API request succeeded for `nguyenson1710/horror-game-suite`; selected output included `is_private` |
| Mutable tag | Unauthenticated `latest` tag API request returned its tag metadata |
| SHA-named tag mapping | Unauthenticated tag API request returned its metadata; the tag remains mutable, while the recorded digest is immutable |
| Digest convergence | Both tag responses returned the same digest |
| Local runnable contract | Compose command exited 0, printed all twelve named `OK` lines, and ended with the exact suite marker |
| CI credentials | The current GitHub listing confirms both secret names. Setup transferred the credential through stdin; this report contains no secret value and makes no historical log-audit claim |

## Tag and Digest Mapping

| Tag | Digest | Docker Hub `last_updated` (UTC) |
|---|---|---|
| `latest` | `sha256:dabae8950d8cc8b27b88aaecde69b3573dc79d26156f0c0e09fe3b8ee93cc46d` | `2026-07-19T22:27:08.669248Z` |
| `001068f6defa1a7d5bd2e68c43b26fcfe732cf63` | `sha256:dabae8950d8cc8b27b88aaecde69b3573dc79d26156f0c0e09fe3b8ee93cc46d` | `2026-07-19T22:27:17.684309Z` |

## Local Twelve-Check Result

`docker compose run --rm suite` exited 0. Its output contained all twelve named `OK`
lines and the exact terminal marker:

```text
ALL_TWELVE_HEADLESS_CHECKS_OK
```

This confirms that the compose-defined suite ran successfully from the locally resolved
image. It is automated, headless evidence only and does not establish human play,
rendered presentation, physical input, audible balance, chase fairness, pacing, Settings,
or fullscreen behavior.

## GitHub Secret Names

The configured GitHub Actions secret names are:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

Only the names are recorded. Setup read the Docker credential into process memory and
transferred it through stdin to `gh secret set`; this report contains no secret value.
The current secret-name listing does not prove the absence of past exposure in every
external process or log.

## Claim Boundary

The evidence supports public availability of the CI/test-suite image at the two recorded
tags and shared digest. The SHA-named tag is a registry locator, not verified source
attestation: no OCI revision-label or provenance-to-commit check is recorded here. This
report also does not pre-claim publication of a SHA-named tag for a future commit.

The image is not the Windows player build. This report does not claim a player release,
Git tag, GitHub release, signed executable, installer, store package, or completion of
the owner-waived human QA. The optional physical runner and perceptual review matrix
remain available for future confidence-building.

## Automated Main-Push Confirmation

Commit `9b14293ee03bfa7c5cfcf145b16df4de80cd2c90` subsequently proved the configured
GitHub Actions path end to end:

| Evidence | Result |
|---|---|
| [`ci` run 29707431394](https://github.com/JasonTM17/Horror_Game_Funny/actions/runs/29707431394) | `success` for the exact commit |
| [`docker-suite` run 29707431393](https://github.com/JasonTM17/Horror_Game_Funny/actions/runs/29707431393) | `success`; container emitted `ALL_TWELVE_HEADLESS_CHECKS_OK` |
| Publish step | Docker login succeeded and pushed `latest` plus SHA-named tag `9b14293ee03bfa7c5cfcf145b16df4de80cd2c90` |
| Published digest | Both tags resolved to `sha256:5e76442b13c33980da6f62ab14e98776ac47cc0cf151fd298efa65364632c4d0` |
| Docker Hub API times (UTC) | `latest`: `2026-07-19T23:10:15.490229Z`; SHA-named tag: `2026-07-19T23:10:17.125199Z` |

Unauthenticated Docker Hub API requests and `docker buildx imagetools inspect` confirmed
both remote tags after the workflow completed. The earlier digest in this report remains
the immutable identity of the initial manual publication; `latest` moved to the automated
workflow digest. The SHA-shaped tag is still only a mutable registry locator and is not
source attestation.

## Unresolved Questions

- Future `main` publications require fresh tag-and-digest verification after the
  corresponding workflow completes.
- Human physical/perceptual QA remains unperformed and accepted by owner waiver.
