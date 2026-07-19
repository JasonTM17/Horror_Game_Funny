---
title: Phase 5 optional human physical production-window operator handoff
type: operator-handoff
status: owner-waived
created: 2026-07-18
updated: 2026-07-19
source_closure_base: 4ec7eddaf4aaeadfc2cb2be613f7303cc8058b60
delivery_commit: c28beeed7a4bafd871e09225152f329beac09e9a
parent_plan: ../plan.md
---

# Phase 5 Operator Handoff

## Owner waiver and authority boundary

The owner closed parent Phase 5/PDR-07 on 2026-07-19 as **owner-waived / accepted risk**.
No human physical production-window run occurred. No pacing, chase, audio, visual, input,
Settings, fullscreen, or other perceptual pass is claimed. Headless checks, a Windows
export smoke, Docker, screenshots, a derived GIF, agent-driven input, and telemetry
without a matching capture remain non-physical and non-perceptual evidence.

Optional future QA procedure: the 30-path source slice passed its real-index gate and landed in
`c28beeed7a4bafd871e09225152f329beac09e9a`; matching `ci` and `docker-suite` runs passed.
Run only from the current clean, pushed `main` commit that the reviewer intends to
approve. Record that exact SHA at run time; the delivery SHA above is provenance, not a
substitute when later documentation-only commits are present. The runner records process
start time and exact Git state,
caps combined console output, terminates the whole Job Object on timeout/overflow, and
routes the Godot `--version` preflight through the same Job boundary with a fixed
30-second/65536-byte budget. It rejects stale, mixed, missing, duplicated, or changed
side-channel evidence. Integrity controls do not replace watching the run.

Pre-run automated authority: the current
[source-consistency QA addendum](../../260719-2235-final-source-consistency-hardening/reports/260719-2321-qa-verification-addendum.md),
the [final source-consistency hardening report](../../260719-2235-final-source-consistency-hardening/reports/pm-260719-2338-source-consistency-final.md),
plus the earlier [final tester](../../260719-0746-repository-evidence-closure/reports/tester-final-2026-07-19.md)
and [final reviewer](../../260719-0746-repository-evidence-closure/reports/code-review-final-2026-07-19.md).
Reviewer verdict: Pass for staging, followed by successful real-index landing and CI.
Docker Hub has no listed Actions secrets; its workflow step skipped, so no publication or
digest is claimed. Registry publication is separate from this optional human QA path.

## Recommended clean-tip preflight

From the repository root on Windows:

```powershell
git switch main
git fetch origin
git pull --ff-only
$dirty = @(git status --porcelain)
if ($dirty.Count -ne 0) { throw "Physical review requires a clean worktree." }
$physicalCommit = (git rev-parse HEAD).Trim()
$remoteCommit = (git rev-parse origin/main).Trim()
if ($physicalCommit -ne $remoteCommit) { throw "Physical review requires HEAD == origin/main." }
Write-Host "PHYSICAL_REVIEW_COMMIT=$physicalCommit"

$godot = "D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe"
if (-not (Test-Path -LiteralPath $godot -PathType Leaf)) { throw "Godot 4.7.1 console executable is missing." }
New-Item -ItemType Directory -Force "D:\Captures" | Out-Null
```

The runner performs the bounded version probe and requires Godot identity
`4.7.1.stable.official.a13da4feb`. The `D:\Tools` and `D:\Captures` paths are
maintainer-local examples; pass another exact Godot/capture path when needed.

If performing this optional QA, before launching rerun the commands in
[`docs/deployment-guide.md`](../../../docs/deployment-guide.md#release-candidate-verification):

- Windows host suite: exactly 12 named checks and `ALL_TWELVE_HEADLESS_CHECKS_OK`.
- Physical evidence regression: process-boundary, pacing-schema, destination-containment,
  reparse, and side-channel markers.
- Both packaging verifiers: `DOCKER_PACKAGING_VERIFY_OK`.
- Repository docs/media verifier: `PRO_DOCS_OK`.
- Windows export verifier and adversarial suite: export/process smoke plus deterministic
  timeout/rollback preservation.
- Container suite when Docker is available: exactly 12 checks and
  `ALL_TWELVE_HEADLESS_CHECKS_OK`.

Do not continue with the optional run if any gate is red or if the test/export run changes the reviewed source
commit.

## Preferred ProjectRun command

Choose **START SHIFT**, not Continue. Use real keyboard and mouse from boot menu to visible
credits, while recording the entire run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-physical-playthrough.ps1 `
  -Godot $godot `
  -LaunchMode ProjectRun `
  -LaunchTimeoutSeconds 7200 `
  -MaxCombinedOutputBytes 16777216 `
  -ConfirmPhysicalInput `
  -CaptureReference "D:\Captures\room407-full-run.mp4"
```

`ProjectRun` binds `--log-file` to the game process and is the authoritative default.

## Optional EditorF5 command

Use this only when the editor itself must remain open:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-physical-playthrough.ps1 `
  -Godot $godot `
  -LaunchMode EditorF5 `
  -LaunchTimeoutSeconds 7200 `
  -MaxCombinedOutputBytes 16777216 `
  -ConfirmPhysicalInput `
  -CaptureReference "D:\Captures\room407-full-run.mp4"
```

EditorF5 does not attach the editor's `--log-file` to its spawned game process. Its pacing
provenance therefore depends on a strictly post-launch
`user://playthrough_pacing_last.txt`; that verified side-channel must contain exactly one
canonical `PLAYTHROUGH_PACING` payload.

## Recommended route and interaction matrix

For a future verification claim, the same uninterrupted run should:

- start from **START SHIFT** at the boot menu with no Continue/checkpoint shortcut;
- use physical keyboard/mouse and no manual method calls, remote-control automation, or
  test scenes;
- traverse lobby, floor 4 dark/powered, memory loop, Room 407, chase, ending, and visible
  credits in the authored order;
- fail the chase once, recover from the checkpoint, then finish without a soft-lock;
- exercise pause/resume, mouse recapture, Settings save, fullscreen, comfort toggles,
  focus loss/return, and relaunch behavior;
- retain one eligible and complete same-run payload with 900-1200 active seconds and all
  five chapter verdicts in range.

## Optional evidence package

If run, the runner creates one new directory below `.artifacts/manual-playthrough/` containing:

- bounded `godot-version-stdout.log`, `godot-version-stderr.log`,
  `console-stdout.log`, and `console-stderr.log`, plus `engine.log` and combined
  `console.log`;
- accepted/rejected side-channel records and any prelaunch stale archive/quarantine;
- `summary.json` and `summary.md` with the exact commit, branch, process boundary, timeout,
  output cap, hashes, pacing verdict, and readiness gates;
- the separately stored capture referenced by the summary.

Every hash-bound side-channel must exist, remain byte-identical, and contain exactly one
valid payload. Engine/console duplication of one identical runtime payload is allowed;
distinct payloads or a missing/empty/duplicate verified side-channel are rejected.

## Human perception review

If a future perceptual claim is desired, the reviewer should watch the entire capture and
record name, date, commit, timestamps, and notes for:

- route completeness, collision/door behavior, soft-locks, and checkpoint recovery;
- chase distance, line-of-sight readability, fairness, capture feedback, and recovery;
- clue, objective, guide-light, darkness, flashlight, blackout, grain/flicker, and ending
  readability/comfort;
- phone, ambience, footsteps, radio, chase, failure, ending, voice/SFX balance, and audible
  defects;
- pause, focus, mouse capture, fullscreen, Settings save/retry, comfort controls, and
  relaunch behavior.

Reject analysis-only, mixed-run, stale, baseline-identical, incomplete, wrong-order,
out-of-target, timed-out, output-overflowed, dirty-tree, or unwatched packages.

## Stable export inputs

- Exported executable reference: `117920376` bytes, SHA-256
  `74ef9d12288a4f687f9d5a7de29cfc684737d2af98da97c90e80e77024099190`.
- Official export-template archive SHA-256:
  `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72`.
- Installed Windows release-template SHA-256:
  `76269a403bb832599edeee4432a5b7a7e88c018eb5c9c798dfd8289359b0ec07`.

V1 bundle IDs rotate because they bind a fresh run ID. Read the ignored active/rollback
`VERIFY_COMPLETE.txt` manifests produced for the reviewed commit; do not copy an older
bundle ID into release authority docs.

## Closure decision

Parent Phase 5/PDR-07 is closed by the owner's 2026-07-19 waiver, not by an evidence
package or human pass. The unperformed physical/perceptual observations are accepted risk.
This handoff remains optional recommended future QA; completing it would support only the
specific claims actually observed. Project closure does not claim Docker Hub publication,
a registry digest, Git release/tag, signing, installer, or store package.
