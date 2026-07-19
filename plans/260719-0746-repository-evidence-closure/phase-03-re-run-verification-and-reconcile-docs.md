---
phase: 3
title: Re-run verification and reconcile docs
status: completed
effort: medium
---

# Phase 3: Re-run verification and reconcile docs

## Overview

Run a clean verification matrix and adversarial review, then sync documentation and plan
status to the evidence actually produced.

## Prerequisites and inventory

- Phase 2 is complete and the live diff is frozen for testing.
- Verification covers all shared contracts; reconciliation may touch the parent plan,
  its current audit report, and the older `260715-0936` plan only to remove dual authority.

## Steps

1. Require the final tester to run the canonical host suite, focused regressions,
   packaging, Docker suite when the daemon is available, export verification/adversarial
   checks, secret scan, YAML parse, link/media validation, and diff checks.
2. Require 12/12 canonical success, unique focused markers, zero scanned bad lines,
   zero leaked profiles/processes, and Docker runtime UID/GID/version evidence. A missing
   daemon is an explicit exception, never a pass.
3. Require final code review against acceptance criteria, scout blast radius, and
   stable contracts; require zero unresolved Critical/High/Medium findings and resolve
   approved defects through the CK review cycle.
4. Activate CK project-management during finalize and reconcile all phase files, the
   child plan table, parent Phase 5, and older-plan cross-links from actual evidence.
5. Reconcile docs review findings. Keep README, changelog, testing, limitations, credits,
   CI text, and audit report mutually consistent and free of overclaims or stale commit IDs.
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
- [x] Final reviewer reports zero unresolved Critical/High/Medium findings and no contract regression.
- [x] Child, parent, and older plan status/cross-links have one truthful authority.
- [x] Docs and audit report cite only current, reproducible evidence.
- [x] Docker Hub decision and, if published, both verified tags/digests are recorded.

## Result

Completed as source verification against the live 30-path worktree on 2026-07-19. The
[final tester report](./reports/tester-final-2026-07-19.md), including its post-review
delta, records:

- host Godot exactly 12/12, twelve exact logs, zero bad canonical logs, clean processes;
- Docker build/run 12/12 as UID/GID 65532 with Godot 4.7.1;
- real Windows PE x86_64 export and exported-process smoke;
- export adversarial success, including self-seeding with canonical bundles absent;
- all five physical-evidence markers and both exact-order packaging markers;
- secret, PyYAML workflow parse, strict UTF-8, diff, and generated-cleanup gates green.

The earlier failed-clone bundle note is explicitly superseded by the passing isolated
fresh-canonical-absent delta. The
[final reviewer report](./reports/code-review-final-2026-07-19.md) gives **Pass for
staging**: 0 unresolved Critical/High/Medium and one informational Low for per-blob
`git cat-file` process startup. Accepted Git-index filesystem/path/blob/mode confusion,
media-extension bypass, authorization drift, and report-authority drift were fixed and
rechecked.

Delivery passed after all 30 intended paths entered the real index. The verifier emitted
`REPOSITORY_MEDIA_OK`, `MARKDOWN_LOCAL_LINKS_OK`, `MARKDOWN_INDEXED_LOCAL_LINKS_OK`, and
`PRO_DOCS_OK` before and after report-containing commit
`c28beeed7a4bafd871e09225152f329beac09e9a`. The authorized non-force push reached 0/0
remote parity; matching `ci` and `docker-suite` runs passed. No Docker Hub Actions secrets
are listed, and the workflow log records a skipped publish, so no publication, tag, or
registry digest is claimed.

## Non-goals and risks

- Real-index delivery is closed; future docs changes must continue to pass the same indexed-blob/mode gate.
- The informational `git cat-file` N+1 pattern is accepted at current scale, not erased.
- No Docker Hub secret means no publication claim; local Docker is test evidence only.
- Do not rewrite historical evidence; explicitly supersede stale results.
