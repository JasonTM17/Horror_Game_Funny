# Headless QA audit - 2026-07-18

Current working-tree audit for the Room 407 release candidate. This report
records what is true now in the repository and what remains unproven.

## Scope checked

- Repo inventory for image/audio assets.
- Canonical headless runtime checks.
- Packaging contract verification.
- Current exported artifact cache under `.artifacts/builds/`.
- Secret-pattern scan.

## Asset inventory

- Image assets found under `assets/images/`: 4 PNGs.
  - `assets/images/menu-hotel-corridor.png`
  - `assets/images/family-table-memory.png`
  - `assets/images/memory-photo-rabbit.png`
  - `assets/images/room-drawing-rabbit.png`
- Voice-over folder inventory: 153 files total, including 76 `.ogg` cues and
  their `.import` sidecars plus the manifest JSON.

## Test and validation results

Commands run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\verify-docker-packaging.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\verify-windows-export.ps1
bash tests/scan-secret-patterns.sh
```

- Canonical Godot suite: **PASS**, 12/12 checks, exit `0`.
- Docker packaging contract verifier: **PASS**, `DOCKER_PACKAGING_VERIFY_OK`.
- Windows export verifier: **PASS**, `WINDOWS_EXPORT_VERIFY_OK`.
- Secret-pattern scan: **PASS**, `SECRET_PATTERN_SCAN_OK`.

## Docker runtime note

- `docker compose run --rm suite` could not execute in this environment because
  the Docker Desktop Linux daemon socket was unavailable:
  `npipe:////./pipe/dockerDesktopLinuxEngine`.
- Structural packaging checks still pass, but the live container run remains
  unverified in this session.

## Export artifact cache

Current cached Windows export bundle:

- Path: `.artifacts/builds/room407-windows-x86_64/ROOM_407_THE_LAST_SHIFT.exe`
- Size: `117920024` bytes
- SHA-256: `8384735b0906e243c198f4b2203a96aa53c910819327edfa30fb4035da6c71c2`
- Bundle marker: `WINDOWS_EXPORT_VERIFY_OK`

Supporting files are present beside the executable:

- `LICENSE`
- `THIRD_PARTY_NOTICES.md`
- `GODOT_COPYRIGHT.txt`
- `export.log`
- `export-console.log`
- `smoke-engine.log`
- `smoke-console.log`

## Open gate

- PDR-07 physical F5 boot-to-credits playthrough, same-run 15-20 minute pacing,
  audible mix, rendered menu readability, and human comfort review remain open.
  Headless startup and cached export evidence do not close that gate.
