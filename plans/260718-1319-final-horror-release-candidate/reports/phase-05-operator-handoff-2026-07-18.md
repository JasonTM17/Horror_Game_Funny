# Phase 5 operator handoff — tip a755b85d6f6f96e2d2c4676cf9d89f484f011102

## Automated gates (this tip)
- Packaging: DOCKER_PACKAGING_VERIFY_OK
- Host twelve-check suite: EXIT=0, CHECKS_OK_COUNT=12
- Windows export: WINDOWS_EXPORT_VERIFY_OK (headless process smoke only)

## Phase 5 / PDR-07 status
**Open.** Headless suite and export smoke do not satisfy physical F5 or 15–20 minute pacing.

## Operator command (human F5)
From repo root, with Godot 4.7.1 available:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-physical-playthrough.ps1
```

Then: fresh production F5 (not F6), physical keyboard/mouse, START SHIFT (not Continue), fail/recover once in chase if scripted, reach visible credits, keep same-run capture + log + single eligible PLAYTHROUGH_PACING payload.

## Do not claim
- Not release-certified
- Not physical playthrough complete
- Not rendered-menu export certification from headless smoke alone