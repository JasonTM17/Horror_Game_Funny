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

### Docker suite

```powershell
docker compose build suite
docker compose run --rm suite
```

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
