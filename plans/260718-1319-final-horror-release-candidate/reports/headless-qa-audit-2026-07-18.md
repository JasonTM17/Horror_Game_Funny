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
- Documentation cover: `docs/media/room-407-cover.png` (1280x640 PNG,
  999,431 bytes; excluded from Godot import and the game export).
- Voice-over folder inventory: 153 files total, including 76 `.ogg` cues and
  their `.import` sidecars plus the manifest JSON.

## Test and validation results

Commands run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\verify-docker-packaging.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\verify-windows-export.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\physical-playthrough-evidence-regression.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\windows-export-adversarial.ps1
bash tests/scan-secret-patterns.sh
```

- Canonical Godot suite: **PASS**, 12/12 checks, exit `0`.
- Docker packaging contract verifier: **PASS**, `DOCKER_PACKAGING_VERIFY_OK`.
- Windows export verifier: **PASS**, `WINDOWS_EXPORT_VERIFY_OK`.
- Physical evidence side-channel regression: **PASS**,
  `PHYSICAL_EVIDENCE_SIDECHANNEL_REGRESSION_OK`.
- Windows export adversarial harness: **PASS**,
  `WINDOWS_EXPORT_ADVERSARIAL_OK`; active and rollback bundle identities were
  unchanged.
- Secret-pattern scan: **PASS**, `SECRET_PATTERN_SCAN_OK`.

## Docker runtime note

- `docker compose run --rm suite` could not execute in this environment because
  the Docker Desktop Linux daemon socket was unavailable:
  `npipe:////./pipe/dockerDesktopLinuxEngine`.
- Structural packaging checks still pass, but the live container run remains
  unverified in this session.

## Export artifact cache

Refreshed active Windows export bundle (2026-07-19):

- Path: `.artifacts/builds/room407-windows-x86_64/ROOM_407_THE_LAST_SHIFT.exe`
- Active executable size: `117920024` bytes
- Active executable SHA-256: `420c085640d54e49765362e830b5f6a4ee8b70d18dc1303079485e59e034c771`
- Bundle marker: `WINDOWS_EXPORT_VERIFY_OK`
- Active bundle SHA-256: `2111b6f55d318ec257bc6baa4a43117f5ee4d27ccc7c48452a57e6bfc7dcec4d`
- Rollback bundle SHA-256: `3c4890f2b1d6f99329727d0bd008a043d60a462d807e1c811e337b965f2e7701`

Current export verification details: [tester report (2026-07-19)](../../260719-0746-repository-evidence-closure/reports/tester-2026-07-19.md).

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
