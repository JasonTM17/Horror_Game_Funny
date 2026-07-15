---
phase: 1
title: Repository and Toolchain
status: completed
priority: P1
dependencies: []
effort: medium
---

# Phase 1: Repository and Toolchain

## Overview

Create the safe Git/Godot baseline, portable toolchain, project metadata, initial architecture docs, and first verified commits without writing to C: beyond unavoidable OS behavior.

## Context Links

- [Plan](./plan.md)
- [Architecture research](./research/researcher-01-godot-architecture.md)
- [Game design research](./research/researcher-02-game-design-and-qa.md)

## Requirements

- Initialize `main`, add the exact empty GitHub remote, and never force-push.
- Download official Godot 4.7.1 to D:, create `_sc_`, and redirect command temp/log paths to D:.
- Create a Compatibility-renderer project, lower-case directory skeleton, safe `.gitignore`, license, README baseline, and core design docs.
- Check C:/D: free space before download, extraction, import, and commit.

## Architecture

The repository root is also `res://`. Tool binaries stay outside the repository. Godot import/cache/editor state is ignored. Project settings establish main scene, input actions, display stretch, renderer, and four future autoload paths only when their scripts exist.

## File Inventory

| Action | Path | Rough size | Test impact |
|---|---|---:|---|
| Create | `.gitignore`, `.gitattributes`, `LICENSE`, `CHANGELOG.md` | <150 lines | Git hygiene |
| Create | `project.godot`, `icon.svg` | <250 lines | Godot recognition |
| Create | `README.md` | <180 lines | Run contract |
| Create | `docs/game-design.md`, `docs/architecture.md`, `docs/code-standards.md` | <500 lines total | Plan baseline |
| Create | source/assets/scenes/tests directory skeleton via tracked files as needed | small | later phases |

## Function and Interface Checklist

- [x] Input Map names finalized: move, sprint, interact, flashlight, pause, objective.
- [x] Main scene and renderer paths use exact lower-case casing.
- [x] No autoload points to a missing script.
- [x] Repository ignores `.godot/`, `.artifacts/`, portable tools, exports, logs, IDE state.
- [x] Local-only CK scaffolding (`.agents/`, `.claude/`, `.codex/`, `AGENTS.md`, `CLAUDE.md`, `plans/templates/`) is placed in `.git/info/exclude`, not published or hidden by project `.gitignore`.

## Dependency Map

`empty workspace -> portable Godot -> project.godot -> headless import -> Git commits -> Phase 2`

## Implementation Steps

1. Record disk, Git, remote, auth, and tool versions in a report.
2. Download/checksum/extract Godot to `D:\Tools\Godot-4.7.1`; enable self-contained mode before first execution.
3. Initialize Git `main`; add local CK/tooling paths to `.git/info/exclude`; add `origin` only after confirming it is the requested empty repository.
4. Create repository metadata and project skeleton.
5. Run Godot version and empty-project headless import with D:-resident temp/log paths.
6. Write design/architecture/code standards from verified requirements.
7. Run `git diff --check`, secret scan, and commit metadata then docs as separate atomic commits.

## Atomic Commit Checkpoints

- `chore: initialize Godot project and repository metadata`
- `docs: define Room 407 design and architecture`
- `docs: add verified implementation plan`

## Test Scenario Matrix

| Priority | Scenario | Expected |
|---|---|---|
| Critical | Headless editor imports project | exit 0, no parse/load errors |
| High | Fresh clone ignores cache/tools/logs | only authored files tracked |
| High | `git ls-files` after initial staging | no CK skill bundle, local instruction file, or plan template is tracked |
| High | Remote inspection | exact URL; remote still empty before first push |
| Medium | Case-sensitive path audit | all referenced paths lower-case and present |

## Success Criteria

- [x] Godot 4.7.1 runs self-contained from D: and reports its version.
- [x] `project.godot` imports headlessly using Compatibility renderer.
- [x] `main` and exact `origin` are configured safely.
- [x] Three atomic commits exist; no cache, binary tool, log, or secret is staged.
- [x] C: and D: free-space readings are recorded after the phase.

## Risks and Mitigation

| Risk | Mitigation |
|---|---|
| C: reaches zero | stop heavy command below 128 MiB; use `_sc_`, D: temp/logs |
| Remote unexpectedly gains history | fetch/reassess; never overwrite or force |
| Godot download corrupt | verify official asset hash/ZIP integrity before extraction |

## Security and Licensing

MIT project license. Official Godot binary is an external tool and not committed. Secret scan precedes commits.

## Next Steps

- Phase 2 implements the main runtime contracts against this stable project foundation.
