# Final automated audit — 2026-07-18 (authoritative tip baseline)

## Source identity

- Captured after CK cook finalize re-verification
- Branch: `main`
- Tip revision: see git `HEAD` at capture (expected `821ef26` family after scare/input contracts; re-run suite updates this file's sibling SCRATCH summary)
- Supersedes dirty-tree Phase 4 snapshot in `phase-04-automated-evidence-report-2026-07-18.md`

## Landed commits (source polish + art + contracts)

| Commit | Summary |
|---|---|
| `2ecf78a` | feat: polish horror release candidate |
| `89042b5` | fix(input): dual physical and logical key bindings |
| `9e216eb` | docs(rc): source polish landing; Phase 5/6 open |
| `298467b` | feat(ui): author menu and story-prop still textures |
| `821ef26` | fix(horror): chapter scare fallback and stricter dual-key/eyes contracts |

## Automated proof

Command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\verify-docker-packaging.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1 `
  -Godot D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe
```

- Packaging: `DOCKER_PACKAGING_VERIFY_OK`
- Host suite: **12/12 EXIT=0** with required markers (see session SCRATCH `headless-suite-summary.txt` with matching `HEAD=`)

## Open gates (unchanged)

- Phase 5 / PDR-07 physical F5 + same-run pacing: **Open**
- Phase 6 Windows export smoke: **Open**
- Parent plan status remains `in-progress`

## Non-claims

Not release-certified. Headless telemetry is not physical playthrough evidence.
