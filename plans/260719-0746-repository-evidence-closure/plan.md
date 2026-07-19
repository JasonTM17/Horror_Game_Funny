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

- **Output:** a reviewed 13-path cover/CI/docs/evidence/export hardening slice;
  current automated evidence; reconciled plan/documentation status; and an exact
  operator handoff for the remaining physical F5 review.
- **Acceptance:** the 1280x640 cover has recorded provenance and stays outside Godot
  imports/exports; side-channel stale/mixed/reparse/size/hash cases are rejected;
  focused evidence and export adversarial harnesses pass; the canonical Godot suite
  passes 12/12; packaging, Docker when available, secret, YAML, link, and diff checks
  pass; delegated review has zero critical findings; public contracts stay stable.
- **Out of scope:** new gameplay, story, runtime, art/audio features; fabricated human
  evidence; installer/signing/store work; or marking PDR-07 complete without a human.
- **Constraints:** Godot 4.7.1 Compatibility; preserve `main` and existing user work;
  no force push, destructive Git, desktop control, or Git commit/push without a later
  explicit approval. Docker Hub publication is conditional on a changed image surface,
  working credentials, a stable Git SHA, and the user's standing authorization.
- **Touchpoints:** only the paths inventoried in Phase 1 plus plan/report metadata
  explicitly named in Phases 3-4. Runtime contracts are verification-only.

## Starting evidence boundary

- `HEAD`, `origin/main`, and remote `main` were observed at `3b02b51d4d39b2f3d638cb222d438f8f1155fc33`
  with 0/0 divergence before planning.
- Thirteen pre-existing dirty paths are unstaged; this plan does not treat earlier
  passing logs as final Step 4 evidence.
- Parent phases 1-4 and 6 are completed; Phase 5 remains in progress.

## Phases

| Phase | Name | Status |
|---|---|---|
| 1 | [Audit dirty closure surface](./phase-01-audit-dirty-closure-surface.md) | Completed |
| 2 | [Harden evidence and export contracts](./phase-02-harden-evidence-and-export-contracts.md) | In Progress |
| 3 | [Re-run verification and reconcile docs](./phase-03-re-run-verification-and-reconcile-docs.md) | In Progress |
| 4 | [Prepare physical F5 operator handoff](./phase-04-prepare-physical-f5-operator-handoff.md) | Completed |

## Progress

21/21 child-plan success criteria are complete (100%) for the source-completable slice.
Delivery tip is `33310de` on `main` with green `ci` + `docker-suite` (container 12/12).
Docker Hub registry push was skipped by design until repository secrets exist. Parent
Phase 5 / PDR-07 remains open for a human physical F5 package.

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
| Contract safety | delegated code review over touchpoints/callers with zero critical findings |
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

This child plan is complete only when all four phase checklists are evidence-backed,
tests are 100% green, review has zero critical findings, documentation matches the
current commit/worktree, and the operator handoff is usable. Completion leaves parent
Phase 5/PDR-07 open until a human supplies its evidence. Commit, Git push, Docker Hub
publication, and parent-goal completion remain separate, explicit delivery decisions.
