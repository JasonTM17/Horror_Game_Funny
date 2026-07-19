---
date: 2026-07-19
session: repository-evidence-closure
status: source-complete-human-gate-open
tags: [release, qa, evidence, docker, physical-playthrough]
---

# Repository Evidence Closure Is Not Release Closure

**Date**: 2026-07-19 10:13
**Severity**: High
**Component**: Release evidence, CI, physical-playthrough tooling
**Status**: Source-completable gates resolved; human acceptance remains open

## Context

This closure slice hardened `tests/run-physical-playthrough.ps1`, added the focused side-channel regression, checked the repository-cover contract in `.github/workflows/ci.yml`, and reconciled the testing and limitation boundaries. It was intentionally a source-completable child of `plans/260719-0746-repository-evidence-closure`, not a substitute for parent Phase 5/PDR-07.

## What Happened

The automated evidence surface is green. The focused regression exited `0` with `PHYSICAL_EVIDENCE_REPARSE_REGRESSION_OK` and `PHYSICAL_EVIDENCE_SIDECHANNEL_REGRESSION_OK`; the canonical host runner reported `Checks 12/12`; packaging, export adversarial, secret, YAML/link/media, cover, and `git diff --check` gates passed. CI now rejects a malformed cover before reading its dimensions: it requires a 13-byte `IHDR` and exactly `1280x640`.

The runner now archives/clears baseline pacing side-channels and fails closed on stale, changed, swapped, or reparse-point sources. That fixes the earlier embarrassing gap where a uniquely written pre-launch payload could appear fresh enough to be accepted.

## Reflection

This was relief with a hard ceiling. We had tooling that could make a neatly packaged lie: a capture reference, a pacing JSON blob, and green headless logs without proving anyone played the game. The worst failure would have been administrative confidence--calling PDR-07 done because the wrappers were polished. The automation is stronger now, but it still cannot see a player struggle with the chase, hear a bad mix, or distinguish a checkbox from real keyboard and mouse input.

## Root Cause

We initially treated a user-data side-channel as fresh evidence without binding it tightly enough to the launch boundary and stable source identity. That was a bad assumption: an old-but-unique file can be syntactically valid and still be the wrong run. Separately, we kept trying to infer human experience from machine checks, which is a category error rather than missing test coverage.

## Decisions

- Kept the focused PowerShell checks outside the canonical twelve-check Godot suite; adding them as a fake thirteenth gameplay check would blur two different evidence contracts.
- Recorded Docker as **unverified**, not failed or passed: the installed client could not reach `dockerDesktopLinuxEngine`, so `docker compose build/run` and Docker Hub publication have no local proof.
- Kept parent Phase 5/PDR-07 open. A source or CI pass cannot close a perceptual, human-observed gate.

## Lesson

Fail closed when provenance is ambiguous, and name the proof boundary in every green report. A passing harness establishes only what it can directly observe; never let convenience turn it into release certification.

## Next Steps

- **Owner: release QA/human operator, before release** -- from a clean committed tree, run F5 from `START SHIFT` to visible credits using physical keyboard/mouse; preserve same-run capture and an eligible, complete, in-order 900-1200 second pacing payload; complete the perception matrix.
- **Owner: release maintainer, after authorized push** -- run/observe Docker compose where the daemon is available and decide whether conditional Docker Hub publication actually occurs.
