---
phase: 8
title: "Documentation Release and Push"
status: in-progress
priority: P1
dependencies: [6]
effort: "medium"
---

# Phase 8: Documentation Release and Push

## Overview

Finalize all user/maintainer documentation from verified code, prepare the playable source release candidate, audit every acceptance criterion, clean Git state, and push the atomic `main` history to origin. Documentation reconciliation may overlap Phase 7 evidence collection after Phase 6 implementation is complete; final release closure remains gated by every Phase 7 manual criterion.

## Context Links

- [Plan](./plan.md)
- Phase 7 test/review/red-team reports in `reports/`

## Requirements

- README: description, screenshot guidance, gameplay, controls, requirements, run/export, structure, architecture, contributing, license, assets, limitations.
- Design, architecture, testing, asset credits, limitations, code standards, changelog.
- Exact final commands/results, branch/remote/commit list, disk readings, secret scan, clean status, successful non-force push.
- Completion audit maps each brief acceptance criterion to authoritative evidence.

## Architecture

Docs describe only paths/signals/commands proven in current code. Release is source-first and runs after clone in Godot 4.7.1; export binaries/templates remain out of scope and are documented honestly.

## File Inventory

| Action | Paths | Rough size | Test impact |
|---|---|---:|---|
| Modify | `README.md`, `CHANGELOG.md` | <350 lines total | run/release contract |
| Modify | `docs/{game-design,architecture,code-standards,testing,limitations,asset-credits}.md` | <1,200 lines total | maintainability/evidence |
| Create | `docs/contributing.md` if needed | <120 lines | contribution workflow |
| Create | final report under plan `reports/` | <250 lines | completion audit |
| Modify | plan/phase statuses via CK CLI only | metadata | plan sync |

## Function and Interface Checklist

- [x] Every documented class, file, input action, command, and scene exists with exact case.
- [x] Asset credits list every authored/generated asset category and license scope.
- [x] `docs/limitations.md` distinguishes untested export, hardware, and manual behavior from implemented gameplay.
- [x] README quick-start works from a clean clone using the official Godot 4.7.1 executable.
- [ ] Final Git audit enumerates commits and proves a clean synced branch.

## Current Evidence — 2026-07-15

- Telemetry code `fc8f7e7` and reconciled README/design/architecture/testing/limitations/changelog commit `257e601` are pushed. Local `HEAD` and `origin/main` matched at `257e601` before this evidence-only plan/journal update.
- The exact 12-check headless runner passes after all telemetry/review fixes. The compressed fresh report is complete and order-valid but correctly outside target; the restored-run report is incomplete/ineligible with a null total verdict.
- A fresh clone of `origin/main` at `257e601` reproduced the README runner contract with 12 logs, all 9 required markers, zero bad log matches, zero temporary profiles, and zero tracked changes. The verified clone was deleted from the repository-local temp root.
- A real local Compatibility-renderer capture is clean and readable, but remains uncommitted and non-physical.
- Post-rehearsal disk snapshot at 18:20 ICT: C: 10.50 GiB free; D: 34.50 GiB free. The isolated runner left zero `godot-user-*` profiles behind.
- No authorized physical F5 15–20 minute boot-to-credits run with same-run telemetry exists. Phase 8 is in progress, not complete.

## Dependency Map

`verified code/reports -> docs reconciliation -> final clean-cache test -> secret/Git audit -> push -> completion audit`

## Implementation Steps

1. Read actual code/scenes/reports, then update every required doc without aspirational claims.
2. Verify Markdown links, file paths, commands, dates, licenses, and limitation wording.
3. Run final disk check and clean-cache headless import/test/smoke plus final manual launch.
4. Run `git diff --check`, ignored/generated-file audit, staged secret scan, branch/remote inspection.
5. Commit documentation and release-preparation changes separately.
6. Push `main` with `git push -u origin main`; never force.
7. Compare local/remote commit IDs, verify clean worktree, and record complete commit sequence.
8. Perform requirement-by-requirement completion audit; update CK plan statuses only when evidence supports them.

## Atomic Commit Checkpoints

- `docs: finalize run testing architecture and asset guides`
- `build: prepare verified playable release candidate`

## Test Scenario Matrix

| Priority | Scenario | Expected |
|---|---|---|
| Critical | README steps from clean project cache | project imports/tests/runs as written |
| Critical | Local vs origin/main | identical final commit; no force |
| Critical | Acceptance audit | every required item has direct evidence |
| High | Secret/generated-file scan | no credential/cache/log/tool binary tracked |
| High | Doc path/link check | all referenced files exist and casing matches |
| Medium | Disk check after final import | C:/D: remain operational; values reported |

## Success Criteria

- [x] Required source-release documentation is accurate, internally linked, and license-complete.
- [x] Final clean-cache validation reproduces prior passing results.
- [ ] Working tree is clean and atomic history is visible on `origin/main`.
- [x] Current audit reports requirements/evidence, fixed/open findings, documentation changes, automated verification, renderer evidence, Git, disk, remaining gates, recommendations, and unresolved questions without claiming completion.
- [ ] Goal is marked complete only after all acceptance evidence is present.

## Risks and Mitigation

| Risk | Mitigation |
|---|---|
| Docs claim unverified behavior | trace each claim to code/test/manual evidence |
| Push rejected or auth expires | preserve local commits, inspect remote, never rewrite history |
| Export unavailable | state source-playable limit; do not claim binary export tested |

## Security and Licensing

Final staged diff is scanned for tokens, passwords, local user paths, logs, and binary provenance. MIT license and authored asset declarations are explicit.

## Next Steps

- Record the authorized physical F5 playthrough and manual presentation/settings evidence required by Phase 7.
- Preserve the same-run capture and telemetry payload; use its chapter/total timings for any final tuning inside the continuous scene.
- Commit and push this evidence-only plan/journal/audit update, then prove a clean working tree and local/remote parity without rewriting history.
- Mark the goal complete only after every remaining gate has direct evidence.
