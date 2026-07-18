# Windows export verified — 2026-07-18

## Scope

Verify the tracked Windows x86_64 export preset, official 4.7.1 release template, and
headless startup smoke on the current `main` tip.

## Evidence

- Verification base: `11737d2`, plus the reviewed verifier, preset, image-aspect, test, and license-inventory changes in this delivery
- Preset: `export_presets.cfg` tracked at repo root
- Template root: `D:\Tools\Godot-4.7.1\editor_data\export_templates\4.7.1.stable`
- Verified release template: `windows_release_x86_64.exe`
- Verifier: `tests/verify-windows-export.ps1`
- Output root: `D:\Horror_Game\.artifacts\builds\room407-windows-x86_64`
- Official template archive:
  `D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_export_templates.tpz`
- Archive SHA-256:
  `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72`
- Verified archive member and installed-template SHA-256:
  `76269a403bb832599edeee4432a5b7a7e88c018eb5c9c798dfd8289359b0ec07`
- Bundled `GODOT_COPYRIGHT.txt` SHA-256:
  `cb1980c88089573bcacd7221d777c689bb8bbd778799f24c27fca0fe5f774d6d`

## Result

| Check | Result |
|---|---|
| Selected export-preset contract | PASS |
| Official archive/member/installed-template identity | PASS |
| Signing, remote-deploy, encryption, filter, and credential contracts | PASS |
| Exclusive lock, unique staging, fresh publish, and cleanup | PASS |
| Release export | PASS |
| Exported exe headless process smoke | PASS |
| PE architecture | PASS (`x86_64`) |

## Export metadata

- Size: `117914600` bytes
- SHA-256: `e783cfa076d1bf4c9bbf7da7301b233fcded9235fa52ba6bbe595018688ff30e`
- Logs:
  - `.artifacts/builds/room407-windows-x86_64/export.log`
  - `.artifacts/builds/room407-windows-x86_64/export-console.log`
  - `.artifacts/builds/room407-windows-x86_64/smoke-engine.log`
  - `.artifacts/builds/room407-windows-x86_64/smoke-console.log`

## Boundaries

- This proves release export and process startup only.
- The published directory also contains `LICENSE`, `THIRD_PARTY_NOTICES.md`, and
  the full tag-pinned `GODOT_COPYRIGHT.txt` component inventory.
- It does not prove a rendered menu, physical input, audible output, installer/signing
  behavior, or PDR-07.

## Status

Windows export gate: completed. Physical F5 / PDR-07: still open.
