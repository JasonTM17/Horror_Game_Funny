---
phase: 3
title: Re-run verification and reconcile docs
status: in-progress
effort: medium
---

# Phase 3: Re-run verification and reconcile docs

## Overview

Delegate a clean verification matrix and adversarial review, then sync documentation and
plan status to the evidence actually produced.

## Prerequisites and inventory

- Phase 2 is complete and the live diff is frozen for testing.
- Verification covers all shared contracts; reconciliation may touch the parent plan,
  its current audit report, and the older `260715-0936` plan only to remove dual authority.

## Steps

1. Spawn the mandatory CK tester to run the canonical host suite, focused regressions,
   packaging, Docker suite when the daemon is available, export verification/adversarial
   checks, secret scan, YAML parse, link/media validation, and diff checks.
2. Require 12/12 canonical success, unique focused markers, zero scanned bad lines,
   zero leaked profiles/processes, and explicit environment notes for unavailable Docker.
3. Spawn the mandatory code reviewer with acceptance criteria, scout blast radius, and
   stable contracts; require zero critical findings and resolve approved defects through
   the CK review cycle.
4. Activate CK project-management during finalize and reconcile all phase files, the
   child plan table, parent Phase 5, and older-plan cross-links from actual evidence.
5. Delegate docs review. Keep README, changelog, testing, limitations, credits, CI text,
   and audit report mutually consistent and free of overclaims or stale commit IDs.
6. Decide Docker Hub publication from evidence: publish `latest` plus immutable Git-SHA
   only if the image surface changed, credentials work, the tree has a stable commit, and
   the built suite passes; otherwise record why no push is needed or possible.

## Verification commands

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run-headless-tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/physical-playthrough-evidence-regression.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/verify-docker-packaging.ps1
docker compose build suite
docker compose run --rm suite
powershell -NoProfile -ExecutionPolicy Bypass -File tests/windows-export-adversarial.ps1
git diff --check
```

## Success criteria

- [x] Mandatory tester reports every applicable gate passing; exceptions are explicit.
- [x] Canonical suite is exactly 12/12 with clean logs and cleanup.
- [x] Mandatory reviewer reports zero critical findings and no contract regression.
- [x] Child, parent, and older plan status/cross-links have one truthful authority.
- [x] Docs and audit report cite only current, reproducible evidence.
- [x] Docker Hub decision and, if published, both verified tags/digests are recorded.

## Result

Completed with fresh tester and cycle-2 review evidence. Docker packaging contracts pass,
but the live Docker daemon is unavailable, so no local image push is claimed; CI remains
the conditional Docker Hub publisher after a successful authorized Git push.

## Non-goals and risks

- An unavailable Docker daemon is an environmental limitation, not permission to claim pass.
- Do not rewrite historical evidence; append or clearly supersede stale status statements.
