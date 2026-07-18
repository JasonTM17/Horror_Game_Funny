# Windows export verified — 2026-07-18

## Scope

Verify the tracked Windows x86_64 export preset, official 4.7.1 release template, and
headless startup smoke on the current `main` tip.

## Evidence

- Commit tip at verification: `4684f29` (`feat(export): add Windows export verify helper and third-party notices`)
- Preset: `export_presets.cfg` tracked at repo root
- Template root: `D:\Tools\Godot-4.7.1\editor_data\export_templates\4.7.1.stable`
- Verified release template: `windows_release_x86_64.exe`
- Verifier: `tests/verify-windows-export.ps1`
- Output root: `D:\Horror_Game\.artifacts\builds\room407-windows-x86_64`

## Result

| Check | Result |
|---|---|
| Export preset contract | PASS |
| Godot version/template contract | PASS |
| Credential scan of preset | PASS |
| Release export | PASS |
| Exported exe headless smoke | PASS |
| PE architecture | PASS (`x86_64`) |

## Export metadata

- Size: `117914600` bytes
- SHA-256: `3bc3d2e4ade3c2147cd3b6efc320802c7db51391570334c7bada65bf3f5ff2c8`
- Logs:
  - `.artifacts/builds/room407-windows-x86_64/export.log`
  - `.artifacts/builds/room407-windows-x86_64/export-console.log`
  - `.artifacts/builds/room407-windows-x86_64/smoke-engine.log`
  - `.artifacts/builds/room407-windows-x86_64/smoke-console.log`

## Boundaries

- This proves release export and process startup only.
- It does not prove a rendered menu, physical input, audible output, installer/signing
  behavior, or PDR-07.

## Status

Windows export gate: completed. Physical F5 / PDR-07: still open.
