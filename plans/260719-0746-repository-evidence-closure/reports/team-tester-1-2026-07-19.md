# Team Tester-1 — Automated Verification Report

Date: 2026-07-19  
Role: tester-1 (Room 407 release-readiness strike team)  
Work dir: `D:\Horror_Game`  
Branch: `main`  
HEAD: `3b02b51d4d39b2f3d638cb222d438f8f1155fc33`  
Plan: `plans/260719-0746-repository-evidence-closure/`  
Constraint: no product source edits, no commit/push, no desktop/physical F5

---

## Environment

| Item | Value |
|---|---|
| OS | Microsoft Windows 11 Pro |
| Version | 10.0.26200 (64-bit) |
| Shell | PowerShell (`powershell -NoProfile -ExecutionPolicy Bypass`) |
| Godot | `D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe` |
| Godot version (engine banner) | `v4.7.1.stable.official.a13da4feb` |
| Godot console binary size | 198152 bytes; LastWriteTime 2026-07-14 |
| Docker client | 29.5.3 (windows/amd64, context `desktop-linux`) |
| Docker daemon | **UNAVAILABLE** — `npipe:////./pipe/dockerDesktopLinuxEngine` not found |
| Git | `main...origin/main` (dirty tree present; not committed by tester) |
| bash | available (used for secret scan) |

Working tree note: many modified/untracked files from the closure plan were present at run time. Suite ran against that dirty tree (authoritative current host state), not a clean checkout.

---

## Checks table

| # | Name | Command | Exit | Key marker(s) | Status |
|---|---|---|---|---|---|
| 1 | Canonical host suite (12 Godot checks) | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/run-headless-tests.ps1` | `0` | 12× `* OK`; markers below | **PASS** |
| 2 | Physical evidence regression | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/physical-playthrough-evidence-regression.ps1` | `0` | `PHYSICAL_EVIDENCE_REPARSE_REGRESSION_OK`; `PHYSICAL_EVIDENCE_SIDECHANNEL_REGRESSION_OK` | **PASS** |
| 3 | Windows export adversarial | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/windows-export-adversarial.ps1` | `0` | `WINDOWS_EXPORT_ADVERSARIAL_OK` (+ sub-markers below) | **PASS** |
| 4 | Docker packaging verify (static) | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/verify-docker-packaging.ps1` | `0` | `DOCKER_PACKAGING_VERIFY_OK` | **PASS** |
| 5 | Secret pattern scan | `bash tests/scan-secret-patterns.sh` | `0` | `SECRET_PATTERN_SCAN_OK` | **PASS** |
| 6 | Docker LIVE (daemon / image boot) | `docker version` / `docker info` | client OK; daemon exit `1` | `failed to connect to the docker API ... dockerDesktopLinuxEngine` | **UNVERIFIED** (not fail) |

### Check 1 detail — 12/12 host suite

Default Godot path used by runner: `D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe` (present).

| Check name | Observed marker / OK line |
|---|---|
| editor-import | `PROJECT_SETTINGS_STABILITY_OK` → `editor-import OK` |
| menu | `menu OK` |
| gameplay | `gameplay OK` |
| game-state | `GAME_STATE_TEST_OK` → `game-state OK` |
| progression | `PROGRESSION_TEST_OK` → `progression OK` |
| checkpoint-layout | `CHECKPOINT_LAYOUT_TEST_OK` → `checkpoint-layout OK` |
| physical-route | `PHYSICAL_ROUTE_SMOKE_TEST_OK` → `physical-route OK` |
| player-input | `PLAYER_INPUT_INTEGRATION_TEST_OK` → `player-input OK` |
| visual-effects | `VISUAL_EFFECTS_TEST_OK` → `visual-effects OK` |
| settings-audio | `SETTINGS_AUDIO_TEST_OK` → `settings-audio OK` |
| settings-persistence-write | `SETTINGS_PERSISTENCE_WRITE_OK` → `settings-persistence-write OK` |
| settings-persistence-read | `SETTINGS_PERSISTENCE_READ_OK` → `settings-persistence-read OK` |

**Summary: 12/12 PASS, suite exit 0.**

Progression also emitted `PLAYTHROUGH_PACING: {... "eligible_full_run":true ... "within_target":false ...}` — automation-eligible pacing payload only; not human physical proof.

### Check 3 detail — Windows export adversarial sub-markers

All observed before final OK:

- `WINDOWS_JOB_ROOT_EXIT_GRANDCHILD_OK`
- `WINDOWS_EXPORT_RECOVERED_PREVIOUS_OK` (×2)
- `WINDOWS_EXPORT_MANIFEST_AND_RECOVERY_ADVERSARIAL_OK`
- `WINDOWS_EXPORT_PARSER_ADVERSARIAL_OK`
- `WINDOWS_EXPORT_TIMEOUT_LOCK_PRESERVATION_OK`
- `WINDOWS_EXPORT_ADVERSARIAL_OK`

### Check 4 detail — packaging

Static file/pattern contract only (Dockerfile, compose, CI publish wiring, runner 12-check parity). Marker `DOCKER_PACKAGING_VERIFY_OK`. Does **not** prove a live container boot.

### Check 6 detail — Docker LIVE

```
docker version  → exit 1 (client prints; server unreachable)
docker info     → exit 1
error: failed to connect to the docker API at
  npipe:////./pipe/dockerDesktopLinuxEngine
  The system cannot find the file specified.
```

**Label: UNVERIFIED** — daemon not running on this host. Not recorded as FAIL (per task instruction).

---

## What was NOT run / why

| Item | Why not run |
|---|---|
| Physical human F5 playthrough (`START SHIFT` → credits, keyboard/mouse, same-run capture) | Explicitly out of scope for tester-1; no desktop control |
| Live Docker image build/boot (`docker compose up`, HEALTHCHECK against running container) | Docker Desktop engine pipe missing; LIVE left UNVERIFIED |
| `tests/verify-windows-export.ps1` (full export smoke) | Not in required ordered list; adversarial harness (#3) was the required export check |
| `tests/run-physical-playthrough.ps1` | Operator/physical path; not automated host suite |
| CI remote workflows / GitHub Actions re-run | Host-local verification only |
| Commit / push / product source edits | Forbidden by task |

---

## Explicit gate statement

**These results do NOT close PDR-07 or the physical human gate.**

Automated host suite, focused evidence regression, export adversarial, static packaging verify, and secret scan all passed on this Windows host. That is repository/automation evidence only. Parent Phase 5 / PDR-07 still require a human-observed physical keyboard/mouse run from `START SHIFT` to visible credits with same-run capture and eligible pacing evidence. Automation markers (including progression `eligible_full_run` and physical-route smoke) must not be labeled as physical human playthrough proof.

---

## Result overview

| Metric | Value |
|---|---|
| Required ordered checks executed | 5 runnable + 1 Docker LIVE probe |
| Runnable automated checks passed | 5/5 |
| Runnable automated checks failed | 0 |
| Docker LIVE | UNVERIFIED |
| Product source edited by tester | no |
| Commits by tester | none |

---

## Concerns

1. Docker Desktop daemon down — packaging static OK, LIVE image path unproven on this host.
2. Working tree dirty at test time — results reflect current dirty tree, not a clean post-commit SHA alone.
3. Progression automated pacing shows `within_target:false` (short headless timers) while `eligible_full_run:true` — expected for automation; must not be sold as human pacing proof.
4. Full Windows export verifier (`verify-windows-export.ps1`) not re-run this session; only adversarial harness per ordered list.

## Unresolved questions

- None blocking automated report. Human operator still owns physical F5 / PDR-07.

---

## Status

**Status:** DONE  
**Summary:** Host 12/12, physical-evidence regression, Windows export adversarial, packaging static verify, and secret scan all exit 0 with expected markers. Docker LIVE UNVERIFIED (daemon down). PDR-07/physical human gate remains open.  
**Concerns/Blockers:** Docker daemon unavailable; no product/commit actions taken.
