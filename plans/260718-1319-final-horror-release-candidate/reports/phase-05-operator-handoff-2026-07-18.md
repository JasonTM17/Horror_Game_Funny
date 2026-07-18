# Phase 5 operator handoff — tip `9a72940e9203080b6249aeb6f917e94a0cc0fb2c`

## Automated gates (this tip)
- Packaging: DOCKER_PACKAGING_VERIFY_OK (pre-commit verify; re-check after push)
- Host twelve-check suite: EXIT=0, CHECKS_OK_COUNT=12 (pre-commit on dirty tree with this slice)
- Windows export: use `tests/verify-windows-export.ps1` when templates present (headless process smoke only)

## Phase 5 / PDR-07 status
**Open.** Headless suite and export smoke do not satisfy physical F5 or 15–20 minute pacing.

## Evidence capture (landed)
Editor F5 spawns a **separate game process**. Host `--log-file` alone dropped `PLAYTHROUGH_PACING`. Runtime overwrites `user://playthrough_pacing_last.txt` with the same one-line payload; the physical runner harvests it into the evidence folder. Default launch mode is **`ProjectRun`** so `--log-file` attaches to the game process.

## Operator command (human only)
From repo root, clean tree on this tip, Godot 4.7.1 available:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-physical-playthrough.ps1 `
  -LaunchMode ProjectRun `
  -ConfirmPhysicalInput `
  -CaptureReference "D:\Captures\room407-full-run.mp4"
```

Then: fresh production start (**START SHIFT**, not Continue), physical keyboard/mouse, fail/recover once in chase if scripted, reach visible credits, keep same-run capture + log/side-channel + single eligible `PLAYTHROUGH_PACING` payload.

## Do not claim
- Not release-certified
- Not physical playthrough complete
- Not rendered-menu export certification from headless smoke alone
