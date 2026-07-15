---
phase: 8
title: "Documentation Release and Push"
status: pending
priority: P1
dependencies: [7]
effort: "medium"
---

# Phase 8: Documentation Release and Push

## Overview

Finalize all user/maintainer documentation from verified code, prepare the playable source release candidate, audit every acceptance criterion, clean Git state, and push the atomic `main` history to origin.

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
| Modify | `docs/{game-design,architecture,code-standards,testing,known-limitations,asset-credits}.md` | <1,200 lines total | maintainability/evidence |
| Create | `docs/contributing.md` if needed | <120 lines | contribution workflow |
| Create | final report under plan `reports/` | <250 lines | completion audit |
| Modify | plan/phase statuses via CK CLI only | metadata | plan sync |

## Function and Interface Checklist

- [x] Every documented class, file, input action, command, and scene exists with exact case.
- [x] Asset credits list every authored/generated asset category and license scope.
- [x] Known limitations distinguish untested export/hardware/manual behavior from implemented gameplay.
- [ ] README quick-start works from a clean clone using the official editor.
- [ ] Final Git audit enumerates commits and proves a clean synced branch.

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
- [ ] Final clean-cache validation reproduces prior passing results.
- [ ] Working tree is clean and atomic history is visible on `origin/main`.
- [ ] Final report includes Completed, Architecture, Verification, Git, Run instructions, and Remaining limitations.
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

- None when all evidence passes and remote `main` matches local `main`.
