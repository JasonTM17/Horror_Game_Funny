---
title: QA verification for final source consistency hardening
date: 2026-07-19
scope: plan/260719-2235-final-source-consistency-hardening
status: pass-with-environment-notes
---

# Test Report - 260719-2253 - final source consistency hardening

## Test Results Overview
- **Total**: 31 validation checks across 10 command entries
- **Passed**: 31
- **Failed**: 0
- **Skipped**: 0
- **Duration**: focused+full Godot/runtime gates ~1m 11s, export verifier ~21s, docs/package checks ~30s

## Coverage Metrics
| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Lines | n/a for this QA pass | 80% | n/a |
| Branches | n/a for this QA pass | 70% | n/a |
| Functions | n/a for this QA pass | 80% | n/a |

## Verified Gates
- Focused settings-audio scene with `D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe` passed and printed `SETTINGS_AUDIO_TEST_OK`.
- Canonical headless suite passed all 12 checks:
  - `editor-import`
  - `menu`
  - `gameplay`
  - `game-state`
  - `progression`
  - `checkpoint-layout`
  - `physical-route`
  - `player-input`
  - `visual-effects`
  - `settings-audio`
  - `settings-persistence-write`
  - `settings-persistence-read`
- Explicit artifact-log bad pattern scan found no matches for:
  - `ERROR:`
  - `SCRIPT ERROR`
  - `Parse Error`
  - `PROGRESSION_ASSERT`
  - `LAYOUT_ASSERT`
  - `PHYSICAL_ROUTE_ASSERT`
  - `PLAYER_INPUT_ASSERT`
  - `VISUAL_EFFECTS_ASSERT`
  - `SETTINGS_AUDIO_ASSERT`
  - `SETTINGS_PERSISTENCE_ASSERT`
  - `VOICE_OVER_ASSERT`
- Physical evidence regression passed with:
  - `PHYSICAL_EVIDENCE_PROCESS_BOUNDARY_REGRESSION_OK`
  - `PHYSICAL_EVIDENCE_PACING_SCHEMA_REGRESSION_OK`
  - `PHYSICAL_EVIDENCE_DESTINATION_CONTAINMENT_REGRESSION_OK`
  - `PHYSICAL_EVIDENCE_REPARSE_REGRESSION_OK`
  - `PHYSICAL_EVIDENCE_SIDECHANNEL_REGRESSION_OK`
- Windows export adversarial passed with:
  - `WINDOWS_JOB_ROOT_EXIT_GRANDCHILD_OK`
  - `WINDOWS_EXPORT_RECOVERED_PREVIOUS_OK`
  - `WINDOWS_EXPORT_MANIFEST_AND_RECOVERY_ADVERSARIAL_OK`
  - `WINDOWS_EXPORT_PARSER_ADVERSARIAL_OK`
  - `WINDOWS_EXPORT_DETERMINISTIC_TIMEOUT_PRESERVATION_OK`
  - `WINDOWS_EXPORT_TIMEOUT_LOCK_PRESERVATION_OK`
  - `WINDOWS_EXPORT_ADVERSARIAL_OK`
- Windows export verifier passed and emitted:
  - `WINDOWS_TEMPLATE_ARCHIVE_SHA256=86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72`
  - `WINDOWS_TEMPLATE_BINARY_SHA256=76269a403bb832599edeee4432a5b7a7e88c018eb5c9c798dfd8289359b0ec07`
  - `GODOT_COPYRIGHT_SHA256=cb1980c88089573bcacd7221d777c689bb8bbd778799f24c27fca0fe5f774d6d`
  - `WINDOWS_EXPORT_SIZE_BYTES=117920184`
  - `WINDOWS_EXPORT_SHA256=febc147f65b856ca9f4f2de7e1e946ceeb11e7b0644108b85fb2edf1a06da18a`
  - `WINDOWS_EXPORT_BUNDLE_SHA256=3ab2ef0d25052847c367f9c26d2199b55de45319c47d53fe0fdab529e521f827`
  - `WINDOWS_EXPORT_PE=x86_64`
  - `WINDOWS_EXPORTED_PROCESS_SMOKE_OK`
  - `WINDOWS_EXPORT_VERIFY_OK`
- Repository docs/media verifier passed:
  - `REPOSITORY_MEDIA_OK`
  - `MARKDOWN_LOCAL_LINKS_OK`
  - `MARKDOWN_INDEXED_LOCAL_LINKS_OK`
  - `PRO_DOCS_OK`
- Static Docker packaging verify passed:
  - `DOCKER_PACKAGING_VERIFY_OK`
- Secret scan passed:
  - `SECRET_PATTERN_SCAN_OK`
- Docker compose config parsed cleanly with `docker compose config --quiet`.
- `git diff --check` returned clean.

## Failed Tests
- None.

## Build Status
- **Build**: not run as a live Docker build
- **Warnings**: Docker daemon unavailable on this host, so no live Docker engine build was attempted
- **Dependencies**: Godot 4.7.1 console binary and official export template archive were present and verified

## Critical Issues
- None in the executed gate set.

## Recommendations
1. Keep the current `settings-audio` regression marker and PCM loop/seam assertions stable; this is the key new coverage added by the plan.
2. Preserve the explicit export-template hash check and the `WINDOWS_EXPORT_VERIFY_OK` smoke output as the packaging boundary.
3. If a future gate needs live Docker execution, run it on a host with the daemon available; current evidence is static-only for Docker.

## Unresolved Questions
- None.
