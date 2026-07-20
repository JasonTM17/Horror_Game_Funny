# Deployment Guide

This guide separates four different delivery paths:

1. source launch with Godot;
2. automated host/container verification;
3. the playable unsigned Windows x64 ZIP release; and
4. the GHCR headless CI/test package.

They are not interchangeable. In particular, the container does not contain a player
distribution, and automated checks do not replace a human physical/perceptual playtest.

## Prerequisites

- Git and Python 3.
- Godot 4.7.1 **standard** build, not .NET, for source launch and Windows export.
- PowerShell 5.1+ for the Windows suite and export tooling.
- Docker Engine/Desktop only for the Linux container suite.
- For an export: the official Godot 4.7.1 standard export-template archive and installed
  `windows_release_x86_64.exe` template.

Generated profiles, logs, exports, and captures belong under ignored `.tmp/` and
`.artifacts/` paths. Do not commit credentials, templates, generated binaries, or capture
material.

## Run from Source

```powershell
git clone https://github.com/JasonTM17/Horror_Game_Funny.git
Set-Location .\Horror_Game_Funny
godot --headless --path . --editor --quit
godot --path .
```

For the GUI path, import `project.godot` in Godot 4.7.1 and press **F5**. F6 runs the
editor's current scene and can skip the boot menu.

## Automated Verification

### Windows host suite

```powershell
$godot = (Get-Command godot -ErrorAction Stop).Source
powershell -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1 -Godot $godot
```

The suite has exactly twelve Godot checks. It fails on non-zero exits, missing markers,
and scanned engine/script/parse/assert failures. Known ObjectDB shutdown-warning noise is
intentionally outside the runner failure policy; it is not a general warning exemption.

### Container suite

```powershell
docker compose build suite
docker compose run --rm suite
```

The image uses Godot 4.7.1 standard, a pinned upstream download hash, non-root UID
`65532`, and the same twelve checks. Validate packaging without a Docker daemon:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\verify-docker-packaging.ps1
python tests/verify-repository-docs.py
```

The documentation verifier reads staged Git-index blobs, so stage any new Markdown or
local media links before expecting it to pass.

### Focused Windows harnesses

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\physical-playthrough-evidence-regression.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\windows-export-adversarial.ps1
```

These are separate hardening checks. They do not add a thirteenth Godot check and do not
create human-playthrough evidence.

## Build the Windows x64 Archive

Run the existing export verifier with explicit portable paths:

```powershell
$godot = (Get-Command godot -ErrorAction Stop).Source
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\verify-windows-export.ps1 `
  -Godot $godot `
  -TemplateArchive 'C:\path\to\Godot_v4.7.1-stable_export_templates.tpz'
```

It validates the selected credential-free unsigned preset, Godot/template hashes, PE x64
architecture, staged notices, logs, and a headless startup before it publishes an ignored
local build. That proof is deliberately limited: it does not inspect rendered pixels,
exercise physical controls, hear audio, evaluate SmartScreen, or certify target hardware.

For `v0.9.0`, package the verified output as exactly:

| Release file | Purpose |
|---|---|
| `room-407-the-last-shift-windows-x86_64-v0.9.0.zip` | Portable Windows x64 game archive |
| `room-407-the-last-shift-windows-x86_64-v0.9.0-SHA256SUMS.txt` | SHA-256 record for that ZIP |

The ZIP must contain exactly those four files under a
`ROOM-407-THE-LAST-SHIFT-v0.9.0/` root. Generate its checksum only after the final ZIP
bytes are fixed. Do not substitute a prior local export hash for the release ZIP checksum.

Use the checked-in preparer immediately after a successful export verification; it rejects
missing inputs and a non-empty output directory that could retain stale assets, writes the
fixed archive layout and one exact SHA-256 record, then reopens the ZIP to verify its
inventory:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\prepare-windows-release.ps1 `
  -Version v0.9.0
```

It writes the two uploadable assets under `.artifacts/release-v0.9.0/` and never modifies
tracked source files. Do not handcraft a replacement archive or checksum record.

Run the focused regression immediately before upload. It verifies the exact ZIP inventory
and checksum, rejects reuse of a populated output directory, and proves that a payload
change no longer bound by `VERIFY_COMPLETE.txt` is refused:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\verify-windows-release-packaging.ps1
```

## Publish the GitHub Release

The public page is
[GitHub Releases / v0.9.0](https://github.com/JasonTM17/Horror_Game_Funny/releases/tag/v0.9.0).
Until it lists both assets, the names above are an intended release contract rather than
evidence that a package exists.

After validation and tag creation, a maintainer can publish the release notes and assets:

```powershell
gh release create v0.9.0 `
  --repo JasonTM17/Horror_Game_Funny `
  --title 'ROOM 407: THE LAST SHIFT v0.9.0' `
  --verify-tag `
  --prerelease `
  --latest=false `
  --notes-file .\docs\release-v0.9.0.md `
  .\.artifacts\release-v0.9.0\room-407-the-last-shift-windows-x86_64-v0.9.0.zip `
  .\.artifacts\release-v0.9.0\room-407-the-last-shift-windows-x86_64-v0.9.0-SHA256SUMS.txt
```

Publish only a tag whose source and artifacts have passed the intended checks. Verify the
uploaded filenames and the released ZIP checksum from a clean download. The player-facing
instructions, checksum command, and unsigned SmartScreen boundary are in
[Release v0.9.0](release-v0.9.0.md).

## GHCR Test Package

The public GHCR package is the CI/headless suite, never the playable Windows game:

```powershell
docker pull ghcr.io/jasontm17/horror-game-suite:v0.9.0
docker image inspect ghcr.io/jasontm17/horror-game-suite:v0.9.0
docker run --rm ghcr.io/jasontm17/horror-game-suite:v0.9.0
```

Use a release tag or recorded immutable digest for reproducibility. `latest`, if offered,
is mutable and unsuitable as durable evidence. A successful container run reports suite
contracts only; it does not prove gameplay behavior or provide a game download.

## Docker Hub Legacy Mirror

`nguyenson1710/horror-game-suite` is retained as a dated CI/test mirror. Its public API
snapshot from 2026-07-20 belongs to historical records, not the current release contract.
Do not use its mutable `latest` tag as a release identity or player-distribution source.

## Optional Human QA

The owner waived PDR-07 as an accepted project-closure risk. No physical boot-to-credits
recording, same-run eligible pacing payload, chase-fairness review, audio/visual review,
input review, or Settings/fullscreen review is claimed. If a future reviewer performs
that work, use the physical runner and the manual matrix in [Testing](testing.md):

```powershell
$godot = (Get-Command godot -ErrorAction Stop).Source
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-physical-playthrough.ps1 `
  -Godot $godot `
  -LaunchMode ProjectRun `
  -ConfirmPhysicalInput `
  -CaptureReference 'D:\Captures\room407-full-run.mp4'
```

This runner preserves bounded logs and one verified pacing side channel, but its generated
summary still requires human review of the recording. It cannot manufacture visual,
audible, physical-input, or fairness evidence.

## Troubleshooting

| Symptom | Action |
|---|---|
| Godot command is missing | Put Godot 4.7.1 standard on `PATH` or pass an absolute `-Godot` path. |
| Export template/hash mismatch | Reinstall the official 4.7.1 standard templates and use the matching archive. |
| Docs verifier reports an unindexed link | Stage the target file, then rerun the verifier. |
| Download checksum differs | Delete the file and download both release assets again from the official release page. Do not extract or run it. |
| SmartScreen warns | Confirm source and SHA-256 first; if either is uncertain, do not run the file. |
| GHCR pull fails | Confirm the tag is published and the package is public; the GHCR image is not required to play the game. |

## References

- [Release v0.9.0](release-v0.9.0.md)
- [Vietnamese guide](vi/README.md)
- [Testing](testing.md)
- [Limitations](limitations.md)
- [Project overview and PDR](project-overview-pdr.md)
- [Asset credits](asset-credits.md)
- [`verify-windows-export.ps1`](../tests/verify-windows-export.ps1)
- [`verify-repository-docs.py`](../tests/verify-repository-docs.py)
