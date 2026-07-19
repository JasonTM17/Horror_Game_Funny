---
phase: 1
title: "Audit dirty closure surface"
status: completed
effort: "small"
---

# Phase 1: Audit dirty closure surface

## Overview

Establish a reproducible baseline and review every existing change before editing it.

## Prerequisites

- Preserve branch `main`, unstaged user work, and remote parity evidence.
- Read `docs/code-standards.md` and adjacent PowerShell/CI/documentation patterns.

## Owned inventory

- `.github/workflows/ci.yml`, `CHANGELOG.md`, `CONTRIBUTING.md`, `README.md`
- `docs/.gdignore`, `docs/media/room-407-cover.png`, `docs/asset-credits.md`
- `docs/limitations.md`, `docs/testing.md`
- `plans/260718-1319-final-horror-release-candidate/reports/headless-qa-audit-2026-07-18.md`
- `tests/run-physical-playthrough.ps1`
- `tests/physical-playthrough-evidence-regression.ps1`
- `tests/windows-export-adversarial.ps1`

## Steps

1. Record `git status --short --branch`, `git diff --check`, tracked/untracked inventory,
   local/tracking/remote refs, and confirm nothing is staged.
2. Review the whole diff for unrelated edits, generated files, secrets, stale claims,
   mojibake, broken links, and deviations from adjacent PowerShell/CI conventions.
3. Verify the cover's PNG signature, IHDR 1280x640 dimensions, byte size, SHA-256,
   README placement, provenance row, `.gdignore`, and export exclusion.
4. Trace evidence-runner inputs through `summary.json`/`summary.md`; enumerate baseline,
   freshness, reparse, copy-size/hash, mixed-payload, launch, and analyze-only cases.
5. Trace the export adversarial harness to the verifier, transaction helper, active and
   rollback bundles; prove it cannot mutate accepted bundles during negative tests.
6. Produce a finding list. Phase 2 edits are allowed only for concrete findings.

## Success criteria

- [x] Exact 13-path baseline and branch/ref evidence are recorded.
- [x] Every change maps to one acceptance criterion; unrelated work is absent.
- [x] Cover/provenance/isolation claims are byte- and source-verified.
- [x] Evidence and export threat cases have identified assertions and cleanup paths.
- [x] Findings distinguish blockers, warnings, and no-change observations.

## Result

Completed by [Phase 1 audit report](./reports/phase-01-audit-2026-07-19.md).
The audit found two physical side-channel blockers for Phase 2 and retained the
Windows transaction reparse-race question as a scoped warning pending assessment.

## Non-goals and risks

- Do not stage, commit, push, launch a desktop window, or claim prior logs as current.
- Main risk is accepting documentation wording as proof; verify source and artifacts.
