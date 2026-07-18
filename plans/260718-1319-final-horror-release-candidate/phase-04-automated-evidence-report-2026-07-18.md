# Phase 4 automated evidence report — 2026-07-18

> **Historical snapshot — superseded.** This report records the earlier dirty-tree
> source-polish gate and is retained for provenance only. The authoritative
> automated baseline is the post-merge final audit in
> [`reports/final-automated-audit-2026-07-18.md`](./reports/final-automated-audit-2026-07-18.md);
> do not use the source identity below as proof for the current tip.

## Source identity

- Captured: `2026-07-18T14:26:20+07:00`
- Branch: `main`
- Base revision: `afe9a62c9dad724db1ffc37b6fc80f1fc933f643`
- Tracked working-diff hash: `19f4430b0b25fd603d4fff852b20fff157ef69da`
- New chase visual builder blob: `54350b4d1e9ae70ea3c3d6373ae243a323130fd0`
- New chase visual builder UID blob: `374c8c7a5f297baf43d293101b9b0bd4fdf2f3c2`

The source was intentionally still uncommitted during this gate. Phase 6 must include
both new chase-builder files when landing the final revision.

## Windows canonical suite

Command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1 `
  -Godot D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe
```

Independent tester result: **12/12 pass in 66.3 seconds**. The tester scanned all
twelve canonical logs for engine, script, parse, and assertion failures and found
none. No `.tmp/godot-user-*` profile remained.

| Check | Current log timestamp | Required marker/result |
|---|---|---|
| editor-import | 14:17:23 | `PROJECT_SETTINGS_STABILITY_OK` |
| menu | 14:17:25 | clean exit |
| gameplay | 14:17:29 | clean exit |
| game-state | 14:17:29 | `GAME_STATE_TEST_OK` |
| progression | 14:17:40 | `PROGRESSION_TEST_OK` |
| checkpoint-layout | 14:17:53 | `CHECKPOINT_LAYOUT_TEST_OK` |
| physical-route | 14:18:09 | `PHYSICAL_ROUTE_SMOKE_TEST_OK` |
| player-input | 14:18:13 | `PLAYER_INPUT_INTEGRATION_TEST_OK` |
| visual-effects | 14:18:14 | `VISUAL_EFFECTS_TEST_OK` |
| settings-audio | 14:18:18 | `SETTINGS_AUDIO_TEST_OK` |
| settings-persistence-write | 14:18:18 | `SETTINGS_PERSISTENCE_WRITE_OK` |
| settings-persistence-read | 14:18:19 | `SETTINGS_PERSISTENCE_READ_OK` |

The canonical inventory is the twelve named `.artifacts/test-<name>.log` files
above. Older focused logs remain noncanonical ignored artifacts.

## Flake correction

The first independent run found a High test-timing defect: fuse cleanup used a
fixed delay that could race the authored scaled sequence. The regression now waits
for the answering light/cue and bounded sequence removal before asserting exact
light/audio restoration. `progression` then passed five consecutive focused runs
and the fresh full Windows suite.

## Linux/container evidence

Commands:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\verify-docker-packaging.ps1
docker compose --progress plain build suite
docker compose run --rm suite
```

- Packaging: `DOCKER_PACKAGING_VERIFY_OK`
- Final image: `sha256:dc11beafe9f10a8745162eab0505507a5a3a2f5fe4e0193abc441c9cfd236bdf`
- Runtime user: `65532:65532`
- Entrypoint: `/app/tests/run-headless-tests.sh`
- Result: all twelve checks plus `ALL_TWELVE_HEADLESS_CHECKS_OK`
- Teardown: no `horror_game-suite-run-*` container remained

Docker Desktop was started for this verification. Its own restart policy also
started the user's pre-existing containers; they were not modified or stopped.

## Additional hygiene

- `git diff --check`: pass
- `tests/scan-secret-patterns.sh`: `SECRET_PATTERN_SCAN_OK`
- `docker compose config --quiet`: pass
- UTF-8 mojibake scan across source/docs/plans: pass
- Windowed staged tour: eight PNG frames plus `VISUAL_CAPTURE_TOUR_OK`
- Headless staged-tour negative contract: exit code 2 with
  `VISUAL_CAPTURE_REQUIRES_RENDERED_DISPLAY`, and no false success marker

## Independent review

The adversarial reviewer examined runtime callers, tests, and documentation.
Final result: **no unresolved Critical, High, or Medium findings; 95% confidence**.

Resolved review findings:

1. Capture documentation said seven frames after the harness gained a dedicated
   final-clue view. All current inventory/provenance references now say eight,
   while preserving the historical seven-frame source note.
2. Documentation still described voice as SFX-routed. It now matches the internal
   Voice bus, Master send, mirrored SFX setting, Voice-keyed SFX compressor, and
   Master limiter contracts.

Low landing note: include `chase-entity-visual-builder.gd` and its `.gd.uid`.

## Evidence boundary

This phase proves automated logic, lifecycle, layout, settings, import, and
cross-platform headless contracts. It does **not** prove audible quality,
human-perceived fear, OS-delivered keyboard/mouse behavior, player-driven chase
fairness, physical Settings/fullscreen behavior, or 15–20 minute pacing. Those
remain Phase 5 gates. Windows export/install behavior remains a Phase 6 gate.
