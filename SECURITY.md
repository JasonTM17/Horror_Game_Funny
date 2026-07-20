# Security Policy

## Supported versions

This repository contains a Godot 4.7.1 source project and an unsigned Windows x64
portable-release channel defined by [Release v0.9.0](docs/release-v0.9.0.md). A release
asset is supported only when it is listed on the official GitHub Release page. Security
fixes apply to the current `main` branch; there is no long-term support matrix.

## What this project stores

- Gameplay checkpoints and most runtime state are **process-local** (not written
  to disk).
- Settings may be written to the Godot user profile as `user://room407.cfg`
  (local machine only).
- The repository must not contain secrets, API tokens, passwords, or private
  keys. Never open a PR that adds `.env` values, Docker Hub tokens, or personal
  capture paths with credentials.

## Reporting a vulnerability

If you believe you have found a security issue in this repository (for example
unsafe file I/O, unexpected code execution via project files, or secret
exposure):

1. **Do not** open a public GitHub issue that describes an exploitable path in
   detail before a fix is available.
2. Contact the maintainer privately via GitHub:
   [JasonTM17](https://github.com/JasonTM17) — open a private security advisory
   on this repository when available, or use the account contact channel.
3. Include: affected revision (commit SHA), reproduction steps, impact, and
   whether the issue is present in source play (Godot editor / F5), the official released
   Windows archive, or only in a local unpublished export.

Please allow a reasonable time for assessment before public disclosure.

## Scope notes

- Third-party engines (Godot) and local Piper voice generation tooling are
  outside this project's direct control; report engine issues upstream when
  appropriate.
- `ghcr.io/jasontm17/horror-game-suite` is a **CI/test image**, not a game server or
  player download. Treat registry credentials as GitHub Actions secrets only. Docker Hub
  is a dated legacy mirror and its mutable `latest` tag is not a security release identity.
