---
title: Repository media and evidence closure
description: >-
  Audit, harden, and verify the current repository-cover, CI, physical-evidence,
  Windows-export, and documentation slice without overstating the human-only
  gate.
status: completed
priority: P1
branch: main
tags:
  - release
  - documentation
  - evidence
  - windows
  - qa
blockedBy: []
blocks: []
created: '2026-07-19T07:46:00+07:00'
createdBy: 'ck:cook'
source: skill
---

# Repository media and evidence closure

## Parent authority

This is a source-completable child plan of the
[final horror release candidate](../260718-1319-final-horror-release-candidate/plan.md).
It prepares trustworthy repository and physical-review tooling, but cannot close
parent Phase 5 or PDR-07. Those require a human-observed physical keyboard/mouse run
from `START SHIFT` to visible credits with same-run capture and pacing evidence.

## Requirements contract

- **Output:** a reviewed cover/CI/docs/evidence/export hardening slice;
  current automated evidence; reconciled plan/documentation status; and an exact
  operator handoff for the remaining physical F5 review.
- **Acceptance:** the 1280x640 cover has recorded provenance and stays outside Godot
  imports/exports; side-channel stale/mixed/reparse/size/hash cases are rejected;
  focused evidence and export adversarial harnesses pass; the canonical Godot suite
  passes 12/12; packaging, Docker when available, secret, YAML, link, and diff checks
  pass; final review has zero unresolved Critical, High, or Medium findings; public
  contracts stay stable.
- **Out of scope:** new gameplay, story, runtime, art/audio features; fabricated human
  evidence; installer/signing/store work; or marking PDR-07 complete without a human.
- **Constraints:** Godot 4.7.1 Compatibility; preserve `main` and existing user work;
  no force push, destructive Git, desktop control, or Git commit/push without recorded
  approval. The user authorized commit/push on 2026-07-19. Docker Hub publication remains
  separate and requires repository secrets plus a verified registry result.
- **Touchpoints:** the Phase 1 inventory plus finding-driven QA, CI, documentation, and
  report extensions approved during review. Runtime/game/config/container/dependency
  contracts are verification-only and remain unchanged.

## Starting evidence boundary

- Pre-landing `HEAD`, `origin/main`, and remote `main` were
  `4ec7eddaf4aaeadfc2cb2be613f7303cc8058b60`; it remains the audited base boundary.
- The 30-path landing slice (24 modified tracked paths plus six new paths) was split into
  QA commit `ad514cba881270d43fa532d324224618dd48d364` and report-containing closure commit
  `c28beeed7a4bafd871e09225152f329beac09e9a`. The real-index docs/media gate emitted all
  four success markers before and after the closure commit.
- Parent phases 1-4 and 6 are completed; Phase 5 remains in progress.

## Phases

| Phase | Name | Status |
|---|---|---|
| 1 | [Audit dirty closure surface](./phase-01-audit-dirty-closure-surface.md) | Completed |
| 2 | [Harden evidence and export contracts](./phase-02-harden-evidence-and-export-contracts.md) | Completed |
| 3 | [Re-run verification and reconcile docs](./phase-03-re-run-verification-and-reconcile-docs.md) | Completed |
| 4 | [Prepare physical F5 operator handoff](./phase-04-prepare-physical-f5-operator-handoff.md) | Completed |

## Progress

All 21/21 child-plan criteria are evidence-backed. The reopened pacing/quarantine,
process-boundary, exact-check, export-timeout, Git-index, media/link, and documentation
paths passed focused tests, host 12/12, local Docker 12/12, export preservation, and final
review. See the [final tester report](./reports/tester-final-2026-07-19.md) and
[final reviewer report](./reports/code-review-final-2026-07-19.md). Reviewer verdict:
**Pass for staging**, with 0 Critical/High/Medium and one informational Low. Source and
delivery closure are complete: non-force push succeeded, local/origin/remote parity is
0/0, and the matching `ci` plus `docker-suite` runs passed. Docker Hub publication was
skipped because Actions secrets are absent. Parent Phase 5/PDR-07 remains open for a
human physical production-window package.

## Scope change log

- Initial 13-path audit boundary expanded to the current 30-path landing manifest after
  accepted findings required the bounded Job helper, exact-order packaging checks,
  index-blob/mode media validation, durable docs, and final evidence reports.
- Impact: QA/CI/docs/plan surface only. No GDScript, scene, `project.godot`, export preset,
  Dockerfile, compose file, dependency, or lockfile change.

## Dependencies

- Phase 1 fixes the exact inventory and identifies evidence-backed defects.
- Phase 2 may edit only defects found in Phase 1 and gates Phase 3.
- Phase 3 supplies authoritative automated/review evidence before status sync.
- Phase 4 packages the truthful human handoff after source-completable checks pass.

## Evidence map

| Requirement | Authoritative evidence |
|---|---|
| Cover integrity and isolation | PNG header/IHDR dimensions, SHA-256/provenance, `.gdignore`, export-content audit |
| Physical evidence integrity | focused regression marker plus adversarial summary-field assertions |
| Export hardening | verified active/rollback bundle followed by adversarial harness marker |
| Runtime non-regression | fresh canonical 12/12 host suite and zero bad log lines/profile leaks |
| Packaging and repository hygiene | packaging/Docker, secret, YAML, link, and `git diff --check` results |
| Contract safety | final three-stage review: zero unresolved Critical/High/Medium findings; one informational Low |
| Human-only gate | operator capture, same-run eligible pacing payload, completed review matrix |

## Stable contracts

- Exact twelve-check runner names and success markers; focused harnesses never become
  a thirteenth Godot check.
- `PLAYTHROUGH_PACING: ` prefix, boundary order, target metadata, and side-channel path.
- `GameState`, InputMap, settings, audio, scene/router, Windows preset, manifest, and
  redistribution-file contracts remain unchanged unless a proven defect forces a
  separately reviewed compatibility decision.
- Automation and staged artwork are never labeled physical or human playthrough proof.

## Completion boundary

This child plan is complete and landed: all four phases and 21/21 criteria are evidence-
backed, applicable source and real-index gates are green, final review has no unresolved
Critical/High/Medium finding, the authorized non-force push has 0/0 remote parity, both
required workflows passed, and the operator handoff is usable. Docker Hub publication is
not claimed because no required repository secrets are listed. Parent Phase 5/PDR-07
stays open until a human supplies and reviews the production-window evidence.
