# ROOM 407: THE LAST SHIFT

[![CI](https://github.com/JasonTM17/Horror_Game_Funny/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/JasonTM17/Horror_Game_Funny/actions/workflows/ci.yml) [![Docker suite](https://github.com/JasonTM17/Horror_Game_Funny/actions/workflows/docker-suite.yml/badge.svg?branch=main)](https://github.com/JasonTM17/Horror_Game_Funny/actions/workflows/docker-suite.yml)

[![ROOM 407: THE LAST SHIFT repository cover (opens full-size PNG)](docs/media/room-407-cover.png)](docs/media/room-407-cover.png)

A short first-person psychological horror game made with Godot 4.7.1 and GDScript. A
student covering a night shift enters a condemned apartment block after a call points to
a floor that should have been sealed for years.

[English](README.md) | [Tiếng Việt - player and release guide](docs/vi/README.md) | [Documentation hub](docs/README.md)

## Release and Download

The intended public player package is the Windows x64 portable ZIP on
[GitHub Release v0.9.0](https://github.com/JasonTM17/Horror_Game_Funny/releases/tag/v0.9.0).
The release contract is:

| Item | Link or value |
|---|---|
| Windows x64 portable ZIP | [`room-407-the-last-shift-windows-x86_64-v0.9.0.zip`](https://github.com/JasonTM17/Horror_Game_Funny/releases/download/v0.9.0/room-407-the-last-shift-windows-x86_64-v0.9.0.zip) |
| SHA-256 record | [`room-407-the-last-shift-windows-x86_64-v0.9.0-SHA256SUMS.txt`](https://github.com/JasonTM17/Horror_Game_Funny/releases/download/v0.9.0/room-407-the-last-shift-windows-x86_64-v0.9.0-SHA256SUMS.txt) |
| Format | Extract-first portable ZIP; not an installer |
| Signing | Unsigned; Windows SmartScreen may warn |

Only treat the assets as available when they appear on the release page. Download both
files from that page, verify the ZIP checksum, extract the whole archive, then launch
`ROOM_407_THE_LAST_SHIFT.exe`. Do not run it inside the ZIP. The complete PowerShell
verification, SmartScreen, control, and support guidance is in
[Release v0.9.0](docs/release-v0.9.0.md).

**Important boundary:** the export verifier checks x64 architecture, notices, and a
headless startup. No human physical or perceptual playtest is recorded; input feel,
rendered brightness, audio mix, fullscreen, chase fairness, and target-hardware behavior
remain owner-accepted risks. The game, UI, subtitles, and voice are English; the
[Vietnamese guide](docs/vi/README.md) is documentation only. See
[PDR-07](docs/project-overview-pdr.md) and [Limitations](docs/limitations.md) for the
accepted-risk disposition.

## Quick Start from Source

Requirements: Godot Engine 4.7.1 **standard** (not .NET), a Compatibility/OpenGL-capable
renderer, and PowerShell on Windows or Docker Engine for the headless suite.

```powershell
git clone https://github.com/JasonTM17/Horror_Game_Funny.git
Set-Location .\Horror_Game_Funny
godot --headless --path . --editor --quit
godot --path .
```

For the GUI path, import `project.godot` in the Godot Project Manager and press **F5**.
F6 runs the current editor scene and can bypass the boot menu. See the
[deployment guide](docs/deployment-guide.md) for explicit Godot, export, and QA commands.

## Controls

| Action | Input |
|---|---|
| Move | W, A, S, D |
| Look | Mouse |
| Sprint | Shift |
| Interact | E |
| Flashlight | F |
| Review objective | Tab |
| Pause / settings | Escape |

Settings cover mouse sensitivity, field of view, audio, fullscreen, and comfort effects.
Checkpoints are process-local; settings can be saved to `user://room407.cfg`.

## Gameplay

- One continuous lobby-to-credits route: blackout floor, memory loop, Room 407, chase,
  abandoned-lobby reveal, and credits.
- Guarded phone, logbook, fuse, memory, radio, Room 407, chase, and ending progression.
- A `NavigationRegion3D` chase with `APPEAR`, `STALK`, `CHASE`, bounded `SEARCH`, and
  recovery behavior. Player walk is 2.0, enemy chase is 3.0, and sprint is 3.1 units/s.
- Fixed, pause-safe scare sequences with temporary actor, light, and audio ownership.
- English manifest-backed narration, procedural SFX, a pause-aware Voice bus, and
  in-game Settings/comfort controls.

The intended first-run duration is 15-20 minutes, but no recorded physical playthrough
or same-run pacing payload verifies that target. See [Limitations](docs/limitations.md).

## Visual Reference Tour

The following material is a staged documentation tour, not a player-driven recording. It
shows selected rendered states only and is not evidence for traversal, pacing, fairness,
audio, Settings, fullscreen, pixel determinism, or behavior on other hardware.

[Open the 7.38-second visual-reference tour (GIF; plays once)](docs/screenshots/room-407-gameplay-tour.gif)

| Lobby | Room 407 approach |
|---|---|
| [![Staged lobby view](docs/screenshots/room-407-lobby.png)](docs/screenshots/room-407-lobby.png) | [![Staged Room 407 approach](docs/screenshots/room-407-bedroom.png)](docs/screenshots/room-407-bedroom.png) |

| Chase entity | Ending reveal |
|---|---|
| [![Staged chase entity view](docs/screenshots/room-407-chase-entity.png)](docs/screenshots/room-407-chase-entity.png) | [![Staged ending reveal](docs/screenshots/room-407-ending-reveal.png)](docs/screenshots/room-407-ending-reveal.png) |

The PNGs are deterministic display derivatives of reviewed staged captures; ImageMagick
lifts RGB midtones/shadows with `-channel RGB -evaluate Pow 0.55 +channel -strip` without
adding or removing scene content. The GIF is a finite derived montage. Capture procedure,
limits, and provenance are documented in [Testing](docs/testing.md) and
[Asset credits](docs/asset-credits.md).

## Automated Verification

Run all twelve headless Godot checks on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1
```

Or run the same suite in the container:

```powershell
docker compose build suite
docker compose run --rm suite
```

Structural packaging and documentation checks do not require Docker:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\verify-docker-packaging.ps1
python tests/verify-repository-docs.py
```

The suite has exactly twelve named checks: `editor-import`, `menu`, `gameplay`,
`game-state`, `progression`, `checkpoint-layout`, `physical-route`, `player-input`,
`visual-effects`, `settings-audio`, `settings-persistence-write`, and
`settings-persistence-read`. It tests contracts and selected production paths, not a
human playthrough or perceptual quality. Assertion-level coverage and evidence boundaries
are in [Testing](docs/testing.md).

## Container Packages

`ghcr.io/jasontm17/horror-game-suite` is the public **headless CI/test** package. It is
not a player build and must never be used as the Windows game download.

```powershell
docker pull ghcr.io/jasontm17/horror-game-suite:v0.9.0
docker run --rm ghcr.io/jasontm17/horror-game-suite:v0.9.0
```

The Docker Hub repository `nguyenson1710/horror-game-suite` is a dated legacy CI mirror;
its `latest` tag is mutable and should not be used as durable release evidence. Use the
GHCR tag/digest recorded by the corresponding CI publication when reproducibility matters.

## Repository Guide

| Document | Purpose |
|---|---|
| [Documentation hub](docs/README.md) | All docs and language navigation |
| [Release v0.9.0](docs/release-v0.9.0.md) | Download, checksum, launch, and unsigned-build guidance |
| [Vietnamese guide](docs/vi/README.md) | Curated Vietnamese player/release guide |
| [Deployment guide](docs/deployment-guide.md) | Source launch, QA, export, CI, and containers |
| [Testing](docs/testing.md) | Twelve-check matrix and evidence limits |
| [Project overview and PDR](docs/project-overview-pdr.md) | Requirements and accepted risk |
| [Architecture](docs/architecture.md) | Runtime ownership and data flow |
| [Limitations](docs/limitations.md) | Distribution and verification boundaries |
| [Asset credits](docs/asset-credits.md) | Media, license, and provenance |
| [Contributing](CONTRIBUTING.md) | Local setup, checks, commit and PR expectations |
| [Security](SECURITY.md) | Private vulnerability reporting |
| [Changelog](CHANGELOG.md) | Notable changes by version |

## Project Layout

| Path | Contents |
|---|---|
| `scenes/` + `scripts/` | Boot, gameplay, UI, autoload, world, player, and interaction code |
| `assets/` + `shaders/` | Voice, project-authored runtime art, and Compatibility shader |
| `tests/` | Godot checks, runners, docs/packaging contracts, export and evidence tooling |
| `docs/` | Release, Vietnamese guide, technical docs, limitations, and provenance |
| `plans/` | Historical plans and dated verification reports |
| `Dockerfile` / `docker-compose.yml` | Headless suite container definitions |

Keep changes focused. Do not commit `.godot/`, `.artifacts/`, local tools, exports, or
credentials. Project code and project-authored assets are under the [MIT License](LICENSE);
this does not relicense Godot Engine or its third-party components.
