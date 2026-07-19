# Contributing

Thank you for helping improve **ROOM 407: THE LAST SHIFT**.

## Requirements

- [Godot Engine 4.7.1](https://godotengine.org/download) **standard** build (not .NET)
- PowerShell 5+ on Windows for the host test runner
- Optional: Docker Engine for the Linux container suite

## Play locally

1. Open `project.godot` in Godot 4.7.1.
2. Press **F5** (main scene). Prefer F5 over F6 so the boot menu is not skipped.

## Automated checks

### Host (Windows)

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1
```

Override Godot path if needed:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1 `
  -Godot "C:\path\to\Godot_v4.7.1-stable_win64_console.exe"
```

### Packaging contracts (no Godot required)

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\verify-docker-packaging.ps1
```

On Linux: `bash tests/verify-docker-packaging.sh`

### Focused PowerShell hardening checks

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\physical-playthrough-evidence-regression.ps1
```

After a successful Windows export verifier run has produced verified active and
rollback bundles, also run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\windows-export-adversarial.ps1
```

These focused harnesses do not add a thirteenth Godot check or create human
physical-playthrough evidence. That QA was owner-waived for project closure and remains
optional recommended future work. See [Testing](docs/testing.md) for prerequisites and
evidence boundaries.

### Docker suite

```powershell
docker compose build suite
docker compose run --rm suite
```

Public image: [`nguyenson1710/horror-game-suite`](https://hub.docker.com/r/nguyenson1710/horror-game-suite).
As verified through the public registry API on 2026-07-20, `latest` and
`001068f6defa1a7d5bd2e68c43b26fcfe732cf63` resolve to
`sha256:dabae8950d8cc8b27b88aaecde69b3573dc79d26156f0c0e09fe3b8ee93cc46d`.
Treat `latest` as mutable and use the digest when reproducibility matters. This image is
for CI/headless testing only, not gameplay distribution.

CI (`.github/workflows/docker-suite.yml`) builds and runs the suite on every PR/push to
`main`. Hub publish happens only on main when repository secrets named
`DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` are configured; both names were configured as
of 2026-07-20. Never place their values in source, documentation, logs, or pull requests.
The Dockerfile pins the Godot 4.7.1 Linux download SHA-256. A local Docker build/run on
2026-07-20 emitted `ALL_TWELVE_HEADLESS_CHECKS_OK`; this does not claim that the next CI
run passed.

The suite must stay at **exactly twelve** Godot headless checks. Do not add a
thirteenth runner entry without an explicit project decision.

## Commit style

Use [Conventional Commits](https://www.conventionalcommits.org/):

```text
feat(scope): short imperative summary
fix(scope): short imperative summary
docs(scope): short imperative summary
ci(scope): short imperative summary
```

- Subject ≤ 72 characters, imperative mood, no trailing period.
- **Do not** add AI co-author trailers or “generated with …” footers.
- Keep commits focused; separate docs from gameplay fixes when practical.

## Pull requests

1. Branch from an up-to-date `main`.
2. Keep the worktree free of secrets (`.env`, tokens, private keys).
3. Run packaging verify and, when possible, the twelve-check suite.
4. Describe **what** changed and **why**; link issues when relevant.
5. Do not claim physical F5 / 15–20 minute pacing certification without a
   same-run evidence package (see [Testing](docs/testing.md)).

## Documentation

- Design and architecture: `docs/`
- Known limits and open gates: `docs/limitations.md`, `docs/project-overview-pdr.md`
- Changelog: `CHANGELOG.md` (Keep a Changelog style under `[Unreleased]`)

## Code of conduct

Be respectful. Harassment, spam, or malicious PRs are not accepted. The
maintainer may close contributions that ignore these norms.
