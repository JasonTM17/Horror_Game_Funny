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
- [x] Final Git audit was rerun after the post-voice hardening/documentation commits and proved a clean synced branch at `bf4cd9a` before this metadata-only parity record.

## Current Evidence — 2026-07-16

- The voice delivery is pushed through `e1e8093` in four focused commits: `5b745b1`, `db736f4`, `3c17663`, and `e1e8093`. It adds 70 manifest-backed English story cues and their verified runtime/test/provenance contracts. The post-voice sequence `15b871c`, `2e2abf2`, and `d5e6dfb` is also pushed; local `HEAD`, `origin/main`, and a direct `refs/heads/main` query matched `d5e6dfb` before this documentation sync.
- Documentation, journal, and QA evidence landed non-force in `bf4cd9a`. The working tree was clean and local `HEAD`, `origin/main`, and the direct remote branch ref all matched `bf4cd9a` with `0/0` divergence before this metadata-only parity record.
- The fresh post-voice 12-check Godot 4.7.1 runner exits `0` in 60.3 seconds with 12 logs, all 10 required markers, zero canonical bad-line matches, and zero temporary profiles. `menu-settings-regression.gd` and `voice-over-regression.gd` run inside `settings-audio`; neither adds a thirteenth check.
- The current compressed fresh report is complete and order-valid at 6.59 seconds active, 6.83 seconds wall, and 0.23 seconds paused, but correctly reports `within_target: false`. The restored-run report remains incomplete/ineligible with a null total verdict.
- Current hardening source/test evidence covers the 1.5 m door sweep, reason-scoped movement-only lock/release, and a bounded entity-parented SFX cue at chase start/recovery with failure/ending teardown. Standard review's one medium finding was fixed; adversarial review reported zero findings.
- A historical fresh clone of `origin/main` at `c38fde9` independently reproduced `SuiteExit 0`, 12 logs, 9 markers, zero bad lines, zero temporary profiles, and zero dirty lines. The verified clone was removed only after its absolute path was confirmed under the repository-local temp root. It predates the project-settings marker, voice delivery, and post-voice hardening, so final clean-clone parity remains open.
- The generated-file, credential-name, high-confidence secret, credentialed-remote, tracked-binary, and tracked-file-size scans found no release blockers. No tracked file exceeds 10 MiB; `.godot`, `.artifacts`, `.tmp`, engine logs, exports, and binaries remain untracked.
- Clean-clone rehearsal disk snapshot: C: 11.97 GiB free; D: 33.05 GiB free. Later disk readings are reported separately because unrelated desktop activity can change C:; the runner left zero `godot-user-*` profiles behind.
- A local Compatibility-renderer capture remains developer evidence, not a physical F5 traversal. No authorized physical F5 15–20 minute boot-to-credits run has paired same-run footage with eligible, complete, actual-order-valid 900–1200 second telemetry or the chase/presentation/audio/settings matrix. Phase 8 remains in progress.
- The non-force pushed history also contains `4574962` (release-parity metadata), `46a58e8` (physical evidence runner), `ba59df0` (review-required/error-scanned semantics), `05ade4b` (clean-revision binding/review checklist), and the voice sequence through `e1e8093`. The runner prepares the missing evidence but does not satisfy the manual gate until an authorized recording is reviewed.

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
- [x] Post-voice hardening and documentation are committed/pushed; working-tree cleanliness and `origin/main` parity were re-proven at `bf4cd9a` before this metadata-only parity record.
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
- Keep every later evidence or tuning commit non-force and re-prove a clean working tree plus direct local/remote parity after each push.
- Mark the goal complete only after every remaining gate has direct evidence.
