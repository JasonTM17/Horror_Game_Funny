# Security Policy

## Supported versions

This repository is a **source-only** Godot 4.7.1 project. There is no published
binary release channel and no long-term support matrix. Security fixes apply to
the current `main` branch only.

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
   whether the issue is present in source-only play (Godot editor / F5) or only
   in a future exported binary.

Please allow a reasonable time for assessment before public disclosure.

## Scope notes

- Third-party engines (Godot) and local Piper voice generation tooling are
  outside this project's direct control; report engine issues upstream when
  appropriate.
- Docker packaging (`nguyenson1710/horror-game-suite`) is a **CI/test image**,
  not a production game server. Treat Hub credentials as secrets in GitHub
  Actions only (`DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`).
