# Phase 5 operator handoff — source-completable closure (2026-07-19)

## Current source boundary

The repository-side evidence wrapper, export checks, documentation, and automated
regressions have been re-verified on the current dirty worktree. The clean delivery
commit is intentionally recorded only after the final Git step. Parent Phase 5/PDR-07
is still **open** because no authorized human physical keyboard/mouse run has supplied
same-run capture, telemetry, and perception review.

## Automated gates (current worktree)

- Canonical Godot host suite: exit `0`, exactly `12/12` checks.
- Focused physical-evidence regression: exit `0`, markers
  `PHYSICAL_EVIDENCE_REPARSE_REGRESSION_OK` and
  `PHYSICAL_EVIDENCE_SIDECHANNEL_REGRESSION_OK`.
- Docker packaging contract checks: PowerShell and Bash verifiers exit `0`.
- Windows export and adversarial rollback checks: pass; active and previous bundle
  identities remain unchanged after negative cases.
- Secret scan, YAML/link/media/cover checks, and `git diff --check`: pass.
- Docker live compose/registry publication: **unverified** because the local Linux
  Docker daemon endpoint is unavailable; CI remains the conditional publisher after an
  authorized push with configured registry secrets.

Detailed current evidence:

- [tester re-verification](../../../260719-0746-repository-evidence-closure/reports/tester-review-fix-cycle-1-2026-07-19.md)
- [cycle-2 code review](../../../260719-0746-repository-evidence-closure/reports/code-review-cycle-2-2026-07-19.md)
- [child-plan audit](../../../260719-0746-repository-evidence-closure/reports/phase-01-audit-2026-07-19.md)

## Verified export identities

- Active executable SHA-256: `420c085640d54e49765362e830b5f6a4ee8b70d18dc1303079485e59e034c771`
- Active bundle SHA-256: `2111b6f55d318ec257bc6baa4a43117f5ee4d27ccc7c48452a57e6bfc7dcec4d`
- Previous executable SHA-256: `8384735b0906e243c198f4b2203a96aa53c910819327edfa30fb4035da6c71c2`
- Previous bundle SHA-256: `3c4890f2b1d6f99329727d0bd008a043d60a462d807e1c811e337b965f2e7701`

These are local ignored build artifacts, not tracked release binaries.

## Human operator command (required for PDR-07)

Run only from the eventual clean commit with Godot 4.7.1 available:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-physical-playthrough.ps1 `
  -LaunchMode ProjectRun `
  -ConfirmPhysicalInput `
  -CaptureReference "D:\Captures\room407-full-run.mp4"
```

The operator must start a fresh production run with **START SHIFT** (not Continue), use
real keyboard/mouse input, fail/recover once in the chase, exercise pause/settings/
fullscreen/comfort/focus behavior, and reach visible credits. Keep one same-run capture,
raw log, side-channel file, and one eligible `PLAYTHROUGH_PACING` payload with complete
actual-order telemetry and active time in the 900–1200 second target.

Reject analysis-only, mixed-run, stale, baseline-identical, incomplete, wrong-order,
or out-of-target packages. A human must watch the capture and judge chase fairness,
clue/guide-light readability, voice/SFX balance, scare comfort, display, focus, and
physical input. Agent-driven or headless evidence is not a substitute.

## Do not claim

- Do not mark Phase 5, PDR-07, or the overall release complete yet.
- Do not call the local Docker exception a successful image build or Docker Hub push.
- Do not describe the staged cover, export smoke, or automation as human perceptual proof.
