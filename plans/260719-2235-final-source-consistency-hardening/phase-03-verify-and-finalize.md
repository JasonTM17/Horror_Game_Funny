---
phase: 3
title: Verify and finalize
status: completed
priority: P1
effort: medium
dependencies:
  - 2
---

# Phase 3: Verify and finalize

## Overview

Run the complete non-interactive quality boundary, mandatory delegated review, plan
sync-back, documentation finalization, and technical journal.

## Requirements

- Fresh Godot 4.7.1 host suite, focused evidence/export regressions where applicable,
  repository docs/media, packaging, secrets, and whitespace checks.
- Mandatory CK tester and code-reviewer evidence with blast-radius review.
- Final status must distinguish source completion from human release certification.

## Related Code Files

- Create: `reports/` entries under this plan as needed
- Create: `docs/journals/260719-*.md`
- Modify: this plan and every phase file via full CK sync-back

## Tests After

1. Run `tests/run-headless-tests.ps1` with the documented Godot 4.7.1 console binary.
2. Run `tests/physical-playthrough-evidence-regression.ps1` and the Windows export
   adversarial/verifier gates if their prerequisites remain available.
3. Run packaging, repository docs/media, secret scan, YAML, links, and `git diff --check`.

## Implementation Steps

1. Delegate the test gate; use debugger delegation for any failure.
2. Delegate mandatory review against acceptance, blast radius, contracts, patterns, and
   repo-wide lint/build/test results; fix and repeat if required.
3. Run project-management full-plan sync-back, docs-manager finalization, and journal.
4. Preserve a clean, reviewable worktree; no commit/push without explicit authorization.

## Success Criteria

- [x] Focused and canonical Godot checks pass with zero scanned errors.
- [x] Repository/release contract checks pass.
- [x] Review reports zero unresolved Critical/High/Medium findings.
- [x] All child-plan checklists and statuses match evidence.
- [x] Parent remains 5/6 until human PDR-07 evidence exists.

## Result

The host suite passed 12/12 twice after the final runtime edits, focused and adversarial
evidence/export gates passed, and the fresh executable/process smoke produced the
`117920376`-byte `74ef9d12…` artifact recorded in the QA addendum. Documentation,
packaging, secret, Compose, link/media, and diff gates are green. Final mandatory review:
10/10 with zero unresolved Critical/High/Medium. PDR-07 remains human-only and open.

## Risk Assessment

Docker daemon or signing/registry credentials may be unavailable; record those as
environment/external limits and rely on the current successful remote suite, never as a
reason to falsify local evidence or close PDR-07.
