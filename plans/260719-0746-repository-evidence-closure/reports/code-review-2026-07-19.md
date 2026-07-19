# Code Review Summary

> **Superseded for landing:** this is the cycle-1 pre-fix review. Its C1/W1/W2 findings
> were addressed and re-reviewed in [cycle 2](./code-review-cycle-2-2026-07-19.md),
> which reports zero critical findings. Retain this file as the audit trail, not as the
> final verdict.

## Scope

- Score: **8/10**.
- Focus: complete current tracked + untracked repository-evidence-closure slice.
- Files: 20 implementation/documentation/plan paths: 9 modified tracked, 11 untracked,
  including one PNG. This report is the only review-created path.
- Size: 417 tracked additions, 25 tracked deletions, 1,087 untracked text lines,
  plus the 999,431-byte cover (1,529 changed text lines reviewed).
- Scout focus: side-channel discovery/preparation/snapshot/harvest, multiple candidates,
  destination cleanup, `AnalyzeLog`, `EditorF5`, `ProjectRun`, summary/readiness contracts,
  Windows recovery/timeout/lock paths, docs, CI, and all named stable callers.

## Overall Assessment

The implementation closes the two recorded side-channel blockers for the covered threat
model: the former minus-two-second window is gone, and snapshots use one open read stream
with pre/open/post checks plus destination size/hash verification and rejected-copy cleanup.
Focused and canonical verification evidence is green. No gameplay/runtime business logic is
changed.

Stage 1 spec compliance still **fails** because an edited QA report labels stale Windows
export hashes current. That is the only critical/blocking finding. The hostile same-host
reparse swap after preflight remains a documented low-severity threat-model limitation, not
a falsely claimed closure.

Pre-Landing Review: **3 issues: 1 critical, 2 informational.**

## Critical Issues

### C1 - Edited QA audit mislabels stale export identities as current

- `plans/260718-1319-final-horror-release-candidate/reports/headless-qa-audit-2026-07-18.md:59-65`
  says "Current cached Windows export bundle" and records executable SHA-256 `8384735b...`
  plus bundle SHA-256 `3c4890f2...`.
- Fresh evidence at
  `plans/260719-0746-repository-evidence-closure/reports/tester-2026-07-19.md:75-76`
  records active executable `420c0856...` and active bundle `2111b6f5...`; line 91
  identifies `3c4890f2...` as the rollback bundle.
- Impact: a release handoff can bind to the wrong artifact while documentation claims current
  authority. This violates truthful-docs acceptance in `plan.md:94-97` and
  `phase-03-re-run-verification-and-reconcile-docs.md:56-57`.
- Fix: update the section from fresh tester evidence with explicit active/rollback labels, or
  label it a historical 2026-07-18 snapshot and link the 2026-07-19 report as current.
- Side effect: documentation/evidence metadata only; do not regenerate bundles for this fix.

## High Priority

No additional high-priority production defect was confirmed.

## Warnings / Informational

### W1 - Harvest anomaly semantics are ambiguous at the readiness gate

- Snapshot open, leaf-reparse, source-identity, generic snapshot, and destination-verification
  failures return rejected records at `tests/run-physical-playthrough.ps1:170-194,224-238`.
- Harvest sets `integrity_passed = false` only for `containment_unsafe` at lines 337-343.
  A rejected leaf reparse, source swap/open failure, or corrupt destination can therefore
  leave aggregate integrity true at line 614 and permit readiness from a valid direct
  `ProjectRun` log at lines 613-619.
- Exact scenario: start without a prelaunch side-channel; produce a valid direct game log;
  create a post-run leaf reparse or trigger the deterministic source swap. Harvest rejects
  and excludes it from `source_logs` at lines 584-586, but readiness can still pass.
- Adjudication: **not a trust-boundary bypass**, because rejected bytes are never parsed. It
  is safe only if integrity means "no unsafe side-channel evidence was consumed." Prose at
  `README.md:184` and `docs/testing.md:360` can instead imply anomaly-free integrity.
- Fix/test: define the meaning. If strict semantics are intended, make snapshot/open/identity/
  reparse/copy anomalies false while leaving ordinary stale/baseline exclusions non-fatal;
  assert that a valid direct log plus each anomaly cannot become ready. Otherwise rename and
  document the field as accepted-evidence integrity and assert that behavior.

### W2 - Focused regression does not execute the public summary/readiness contract

- `tests/physical-playthrough-evidence-regression.ps1:19-55` imports helper functions only.
  Lines 70-194 cover archival, freshness, baseline, exact boundary, copy corruption/cleanup,
  source swap, and supported junction rejection.
- It never calls `Write-EvidenceFiles`, asserts legacy summary field types/names, or drives
  readiness across `AnalyzeLog`, `EditorF5`, `ProjectRun`, preparation failure, or harvest
  failure. Static review confirms parameters remain at runner lines 2-11, legacy summary
  fields remain at lines 621-645/653-658, and markers remain at lines 661-663.
- Fix: add a no-Godot summary/readiness test, optionally extracting only the final gate into
  a small domain-specific pure helper. Do not add a thirteenth canonical Godot check.

## Suggestions

- `.github/workflows/ci.yml:37-42` checks PNG signature, `IHDR` type, and 1280x640, but not
  mandatory IHDR length 13. The committed file is valid and hashes to `58d5893...`; adding
  the length check would make the dependency-free guard match its "canonical PNG" message.

## Mandatory Verdicts

### (a) Acceptance criteria - **FAIL only on C1**

- Cover: pass. Direct byte inspection found canonical PNG, IHDR length 13, 1280x640, SHA-256
  `58d5893...`; provenance is at `docs/asset-credits.md:11`; `.gdignore:1` and
  `export_presets.cfg:11` keep it outside Godot import/export; CI checks presence/type/size.
- Side-channel: pass for the covered model. Strict post-launch/baseline rejection is at runner
  lines 321-375; stable one-stream copy/verification/cleanup is at 155-248; regression lines
  70-194 cover stale, absent, same-baseline, former tolerance, exact boundary, fresh copy,
  corrupt destination, deterministic source swap, cleanup, and junction rejection.
- Multiple candidates/mixed runs: pass statically via discovery/indexing at runner lines
  75-96/325-375 and unique-payload rejection at 379-404.
- Windows adversarial contracts: pass; harness lines 105-279 cover descendant teardown,
  manifest/recovery/parser/containment/timeout/lock paths. Tester lines 79-92 confirm markers
  and active/rollback preservation.
- Exact canonical suite: pass 12/12 per tester lines 27-49; focused wrappers are not check 13.
- Documentation: fail only on C1. PDR-07 remains correctly open at `README.md:7,196-200`,
  parent plan lines 54-59/105-109, and PDR lines 19/51.

### (b) Business logic/workflow regression - **PASS**

- No diff to `GameState`, InputMap, pacing runtime, settings/runtime, scenes, or gameplay.
- `AnalyzeLog` stays package-ineligible; `EditorF5` relies on the side-channel; `ProjectRun`
  can use its direct game log (`run-physical-playthrough.ps1:529,548-619`).
- No database/query surface exists; N+1/index concerns are not applicable.

### (c) Public contract compatibility - **PASS, with W2 coverage gap**

- PowerShell parameters and defaults are preserved at runner lines 2-11.
- Legacy summary fields are retained and new side-channel fields are additive at 621-658.
- `PLAYTHROUGH_PACING: ` prefix and boundary order remain at lines 17-28.
- Canonical marker names remain at lines 661-663; exact twelve runner names are unchanged.
- No diff to pacing schema/runtime, settings, InputMap, export preset, verifier, transaction
  helper, manifest, or Job runner contracts.

### (d) Patterns, KISS/DRY, PowerShell 5.1 - **PASS**

- Code follows adjacent fail-closed PowerShell patterns and uses APIs available to Windows
  PowerShell 5.1/.NET Framework. No dependency or generic manager abstraction was added.
- Hostile same-host reparse swap after path preflight is explicitly disclosed in
  `CHANGELOG.md:45` and `docs/testing.md:86`; it is not claimed closed.

### (e) Parse/lint/build/test state - **PASS for available gates**

- Fresh tester evidence: 3/3 PowerShell AST parses, focused physical regression pass,
  canonical 12/12 with clean current-run logs and zero leaked profiles/processes, packaging
  PowerShell/bash pass, Windows export/adversarial pass, secret scan, YAML parse, Markdown
  links/media, cover contract, and `git diff --check` all pass.
- Docker daemon timed out and is truthfully `UNAVAILABLE`, not passed. No line/type coverage
  tooling exists for this PowerShell/Markdown/YAML/PNG slice.
- Mojibake candidates observed: 0. Lint/diff issues observed: 0.

## Edge Cases and Side Effects

- Preparation archive/clear failures set integrity false and block readiness at runner lines
  256-302/614-619. Rejected snapshot destinations are removed in `finally` at 239-247.
- Root/candidate reparse discovery propagates a terminating error at lines 44-96: fail-closed
  and console-diagnosable, but it may terminate before JSON summary creation.
- A launch-mode run intentionally archives then deletes existing user-profile
  `playthrough_pacing_last.txt` files before launch at lines 256-295/566-570.
- Analyze-only mode does not touch APPDATA. Rejected harvest files never enter parsing.
- Windows adversarial tests create isolated `.tmp` fixtures and invoke timeout/lock failures;
  tester lines 89-92 confirm accepted active/rollback identities were preserved.
- No source, gameplay, settings, export-contract, network, credential, or external-user side
  effect was introduced by the reviewed diff.

## Recommended Actions / Plan Follow-up

1. Fix C1 and rerun lightweight docs/link/diff gates; zero critical is required to land.
2. Decide W1 semantics and add the W2 no-Godot contract assertions.
3. Phase 2 can complete after C1/review closure. Phase 3 remains pending until review is
   zero-critical and docs/status reconciliation is finished. Refresh Phase 4 handoff only
   against the eventual clean tip. Parent Phase 5/PDR-07 remains human-only and open.

## Metrics

- Type coverage: N/A; no new typed runtime surface.
- Test coverage: no line coverage; behavioral gates listed in verdict (e) are green.
- Linting issues: 0 observed.

## Unresolved Question

- Does `pacing_side_channel_integrity_passed` mean anomaly-free harvest or only that no
  rejected/unsafe side-channel bytes were consumed? Resolve this before treating the field
  as a stable evidence contract.
