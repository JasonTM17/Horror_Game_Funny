# Final automated audit — 2026-07-18 (authoritative automated baseline)

This report supersedes the earlier Phase 4, readiness, scout, reviewer, and PM
snapshots in this report directory wherever their pre-fix or pre-export state differs.

## Source identity

- Branch: `main`
- Verification base: `11737d237906c1570b8ea0f7dc9b1a3cd36d8fb8` on `main`.
- This delivery additionally preserves the Room 407 drawing's source aspect ratio,
  covers all three story textures against stretching, hardens the selected export
  preset/template/staging contracts, and adds the exact Godot 4.7.1 component
  inventory. The final verification runs include those changes.
- Remote audit after `git fetch --prune origin`: no unmerged remote branch remained;
  the already-merged Dependabot `actions/checkout@v7` branch was pruned remotely.

## Windows host proof

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1 `
  -Godot D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\verify-docker-packaging.ps1
bash tests/scan-secret-patterns.sh
```

- Canonical Godot suite: **12/12**, exit `0`, about `77.5` seconds.
- Exact canonical log count: `12`; current log scan found no engine, script,
  assertion, parser, ObjectDB-leak, or null-tree failure marker.
- Repository-local `godot-user-*` profiles after both concurrent runs settled: `0`.
- Packaging verifier: `DOCKER_PACKAGING_VERIFY_OK`.
- Committed-tree secret-pattern scan: `SECRET_PATTERN_SCAN_OK`.

## Linux-container proof

```powershell
docker build --progress=plain -t horror-game-suite:final-audit-20260718 .
docker run --rm --name room407-final-audit horror-game-suite:final-audit-20260718
```

- Image ID: `sha256:d42cdfb5fced603acb26e672d088520be57a0a52a2c98aed236957d8de4459fa`.
- Runtime user: `65532:65532` (non-root).
- Canonical suite: **12/12**, `ALL_TWELVE_HEADLESS_CHECKS_OK`, exit `0`,
  about `82.9` seconds.
- Named container count after `--rm`: `0`.

## Windows x86_64 export proof

```powershell
& .\tests\verify-windows-export.ps1 `
  -Godot D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe
```

- Official Godot archive:
  `D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_export_templates.tpz`.
- Archive SHA-256:
  `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72`.
- Installed release template: `4.7.1.stable/windows_release_x86_64.exe`.
- Archive member and installed-template SHA-256:
  `76269a403bb832599edeee4432a5b7a7e88c018eb5c9c798dfd8289359b0ec07`.
- Tag-pinned `GODOT_COPYRIGHT.txt` SHA-256:
  `cb1980c88089573bcacd7221d777c689bb8bbd778799f24c27fca0fe5f774d6d`.
- Output: `.artifacts/builds/room407-windows-x86_64/ROOM_407_THE_LAST_SHIFT.exe`.
- Size: `117914600` bytes.
- SHA-256:
  `e783cfa076d1bf4c9bbf7da7301b233fcded9235fa52ba6bbe595018688ff30e`.
- PE machine: `0x8664` (`x86_64`); PCK embedded; code signing and remote
  deployment disabled; preset credential scan passed.
- The verifier binds those checks to the selected preset, verifies the official
  archive/member/installed-template chain, rejects encryption and unexpected
  filters, and uses an exclusive lock plus unique staging before fresh publish.
- Export and exported-process smoke logs contain no failure marker.
- Export log contains all four authored PNGs and all `76` voice imports, while the
  preset-excluded test/docs/plans/artifact directories have no packed entry.
- Root `LICENSE`, `THIRD_PARTY_NOTICES.md`, and the full tag-pinned
  `GODOT_COPYRIGHT.txt` inventory are copied beside the ignored build.

## Audio/source audit

- `76` OGG voice cues, `76` import sidecars, and `76` manifest entries match.
- All audited cues are mono Vorbis at `22050 Hz`; decoded duration totals about
  `264.59` seconds, with no source-file peak/loudness outlier found.
- `SETTINGS_AUDIO_TEST_OK` verifies buses, Voice/SFX ducking contracts, limiting,
  cue manifest/routing, pause/resume, replacement, teardown, and cache bounds.

## Open gate and non-claims

- Phase 6 automated export/docs/audit gate: **Completed**.
- Phase 5 / PDR-07 physical F5, same-run 15–20-minute pacing, rendered
  readability, audible mix, physical controls, chase feel, comfort, and visible
  credits: **Open** under the user's no-desktop-control instruction.
- Headless startup is not evidence that a human saw the menu or heard the mix.
  The parent RC plan therefore remains `in-progress`, not release-certified.
