# Phase 5 operator handoff — tip (pending commit; re-verify after land)

## Automated gates baseline
- Packaging: re-run after land
- Host twelve-check suite: re-run after land (must stay 12/12)
- Windows export: re-run after land when templates present

## Phase 5 / PDR-07 status
**Open.** Headless suite and export smoke do not satisfy physical F5 or 15–20 minute pacing.

## Evidence capture fix (this slice)
Editor F5 spawns a **separate game process**. Binding `--log-file` only to the editor host previously dropped `PLAYTHROUGH_PACING` lines. Runtime now also overwrites `user://playthrough_pacing_last.txt` with the same one-line payload; the physical runner harvests it into the evidence folder. Default launch mode is **`ProjectRun`** so `--log-file` attaches to the game process.

## Operator command (human F5 / ProjectRun)
From repo root, clean tree on the tip under test, with Godot 4.7.1 available:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-physical-playthrough.ps1 `
  -LaunchMode ProjectRun `
  -ConfirmPhysicalInput `
  -CaptureReference "D:\Captures\room407-full-run.mp4"
```

Optional editor host:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-physical-playthrough.ps1 `
  -LaunchMode EditorF5 `
  -ConfirmPhysicalInput `
  -CaptureReference "D:\Captures\room407-full-run.mp4"
```

Then: fresh production start (**START SHIFT**, not Continue), physical keyboard/mouse, fail/recover once in chase if scripted, reach visible credits, keep same-run capture + log + single eligible `PLAYTHROUGH_PACING` payload (engine/console and/or harvested side-channel).

## Do not claim
- Not release-certified
- Not physical playthrough complete
- Not rendered-menu export certification from headless smoke alone
