# Release v0.9.0

## Overview

`v0.9.0` defines the first public Windows distribution for **ROOM 407: THE LAST SHIFT**.
The official release page is
[GitHub Releases / v0.9.0](https://github.com/JasonTM17/Horror_Game_Funny/releases/tag/v0.9.0).
Assets are available only after that page lists them; until then, these names are the
release contract rather than evidence of an upload.

This release is intentionally marked as a GitHub **pre-release**. The automated export
and headless checks passed the repository contract, but no human physical or perceptual
playtest is recorded; the owner accepted that remaining risk rather than claiming manual
QA that did not happen.

| Item | Value |
|---|---|
| Platform | Windows x86_64 |
| Delivery format | Portable ZIP; not an installer |
| Archive | [`room-407-the-last-shift-windows-x86_64-v0.9.0.zip`](https://github.com/JasonTM17/Horror_Game_Funny/releases/download/v0.9.0/room-407-the-last-shift-windows-x86_64-v0.9.0.zip) |
| Checksum record | [`room-407-the-last-shift-windows-x86_64-v0.9.0-SHA256SUMS.txt`](https://github.com/JasonTM17/Horror_Game_Funny/releases/download/v0.9.0/room-407-the-last-shift-windows-x86_64-v0.9.0-SHA256SUMS.txt) |
| Executable | `ROOM_407_THE_LAST_SHIFT.exe` inside the extracted archive |
| Archive root | `ROOM-407-THE-LAST-SHIFT-v0.9.0/` |
| Signing | Unsigned; Windows SmartScreen may warn |
| Engine | Godot 4.7.1 standard, Compatibility renderer |
| License | [MIT](https://github.com/JasonTM17/Horror_Game_Funny/blob/v0.9.0/LICENSE), with Godot notices retained in the archive |

## Install and Verify

1. Download the ZIP and its `SHA256SUMS.txt` from the same official release page.
2. Verify the archive before extracting it:

```powershell
$zip = '.\room-407-the-last-shift-windows-x86_64-v0.9.0.zip'
$sums = '.\room-407-the-last-shift-windows-x86_64-v0.9.0-SHA256SUMS.txt'
$name = [IO.Path]::GetFileName($zip)
$records = @(Get-Content -LiteralPath $sums | Where-Object { $_ -match '\S' })
$pattern = '^(?<hash>[A-Fa-f0-9]{64}) \*' + [regex]::Escape($name) + '$'
if ($records.Count -ne 1) { throw 'Expected exactly one checksum record.' }
$match = [regex]::Match($records[0], $pattern)
if (-not $match.Success) { throw 'Checksum record is malformed or names another file.' }
$expected = $match.Groups['hash'].Value.ToUpperInvariant()
$actual = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToUpperInvariant()
if ($actual -ne $expected) { throw 'Checksum mismatch. Do not extract or run this archive.' }
Write-Host "SHA-256 verified: $actual"
```

3. Extract the entire archive, then start the contained executable:

```powershell
$destination = Join-Path (Get-Location) 'ROOM-407-v0.9.0'
if (Test-Path -LiteralPath $destination) { throw "Refusing to reuse existing extraction directory: $destination" }
Expand-Archive -LiteralPath $zip -DestinationPath $destination -ErrorAction Stop
$exe = Join-Path $destination 'ROOM-407-THE-LAST-SHIFT-v0.9.0\ROOM_407_THE_LAST_SHIFT.exe'
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'Expected executable was not found at the archive-relative path.' }
& $exe
```

Do not run the executable from within the ZIP. Keep `LICENSE`, `THIRD_PARTY_NOTICES.md`,
and `GODOT_COPYRIGHT.txt` with any redistributed copy.

## Unsigned Build and SmartScreen

This portable build is deliberately unsigned. A SmartScreen warning can appear because
Windows does not recognize a code-signing publisher. Verify the SHA-256 checksum and
confirm that the download came from the repository's official release page before making
any trust decision. If either check fails or you are unsure, do not run the executable.

For a file you have independently verified and chosen to trust, Windows may require
**More info** then **Run anyway**. That is a Windows trust decision, not a security
guarantee and never replaces checksum verification.

## Controls and Runtime Notes

| Action | Input |
|---|---|
| Move | W, A, S, D |
| Look | Mouse |
| Sprint | Shift |
| Interact | E |
| Flashlight | F |
| Review objective | Tab |
| Pause / settings | Escape |

The game is an English-language first-person psychological horror experience. It uses
dark scenes, flashing effects, sudden audio, and a pursuit sequence. Settings expose
mouse, field-of-view, audio, fullscreen, and comfort controls. Gameplay checkpoints are
process-local; settings can persist to `user://room407.cfg`.

## What This Release Does and Does Not Verify

- The Windows archive is a portable game package, not an installer or signed build.
- The repository's automated export verifier checks the selected unsigned x64 preset,
  notices, PE architecture, and a headless process startup. It does not verify a rendered
  menu, physical input, audio output, fullscreen behavior, or target-hardware performance.
- No human physical or perceptual playtest is recorded. The owner waived PDR-07 as an
  accepted risk; see [Limitations](https://github.com/JasonTM17/Horror_Game_Funny/blob/v0.9.0/docs/limitations.md)
  and [Testing](https://github.com/JasonTM17/Horror_Game_Funny/blob/v0.9.0/docs/testing.md).
- Documentation screenshots and GIF are staged visual references, not a gameplay recording
  or a substitute for manual QA.

## Source, Containers, and Support

- Build from source with Godot 4.7.1: [Deployment guide](https://github.com/JasonTM17/Horror_Game_Funny/blob/v0.9.0/docs/deployment-guide.md).
- Report reproducible defects: [GitHub Issues](https://github.com/JasonTM17/Horror_Game_Funny/issues).
- Report security concerns privately: [Security policy](https://github.com/JasonTM17/Horror_Game_Funny/blob/v0.9.0/SECURITY.md).
- Vietnamese player/release guide: [Hướng dẫn tiếng Việt](https://github.com/JasonTM17/Horror_Game_Funny/blob/v0.9.0/docs/vi/README.md).

The public `ghcr.io/jasontm17/horror-game-suite` package is **only** the headless
CI/test suite. It is not the Windows game download and must not be used as one. See the
[container section](https://github.com/JasonTM17/Horror_Game_Funny/blob/v0.9.0/docs/deployment-guide.md#ghcr-test-package)
for its commands and limits.
