# A-to-Z polish verification — 2026-07-19

## Scope completed (source-completable)

| Track | Result |
|---|---|
| Docker supply-chain pin | Dockerfile verifies Godot Linux zip SHA-256 `c7ff14fd28472c8d4f193043de30278dcf7e5241a1dcf7566b02e27addaa33ba` |
| Docker Hub CI contract | `permissions: contents: read`; username must be `nguyenson1710`; tags `latest` + `GITHUB_SHA`; skip when secrets absent |
| Secret hygiene | `.gitignore` / `.dockerignore` exclude dotenv/keys; secret scan includes workflows + markdown |
| Repo docs + media | README cover, staged stills gallery, GIF tour, asset boundaries; dual-hash demotion |
| Phase 5 handoff honesty | Prefer ProjectRun; EditorF5 side-channel caveats |
| Flaky regression fix | Fresh side-channel harvest pins LWT strictly after launch |

## Automated gates re-run

| Gate | Exit | Marker |
|---|---|---|
| `tests/run-headless-tests.ps1` | 0 | 12/12 OK |
| `tests/physical-playthrough-evidence-regression.ps1` ×3 | 0 | `PHYSICAL_EVIDENCE_*_OK` |
| `tests/windows-export-adversarial.ps1` | 0 | `WINDOWS_EXPORT_ADVERSARIAL_OK` |
| `tests/verify-docker-packaging.ps1` | 0 | `DOCKER_PACKAGING_VERIFY_OK` |
| `bash tests/scan-secret-patterns.sh` | 0 | `SECRET_PATTERN_SCAN_OK` |
| Docker LIVE build/run | n/a | **UNVERIFIED** — Docker Desktop engine pipe unavailable after start attempt |
| Docker Hub push | n/a | **Pending** authorized main push + `DOCKERHUB_*` secrets |

## Explicit non-claims

- Does **not** close PDR-07 / parent Phase 5.
- Does **not** claim live container suite or Hub publication from this host.
- Staged screenshots and GIF remain documentation media only.

## Delivery remaining

1. User-authorized `git commit` of the intentional dirty surface + `git push origin main`.
2. Confirm GitHub Actions secrets named `DOCKERHUB_USERNAME` (value `nguyenson1710`) and `DOCKERHUB_TOKEN` (token value only in the secret store; never inline in docs).
3. Observe `docker-suite` CI: build + suite + conditional Hub publish.
4. Human physical F5 via ProjectRun handoff to close PDR-07.
